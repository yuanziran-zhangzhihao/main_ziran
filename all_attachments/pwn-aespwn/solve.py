#!/usr/bin/python3
from pwn import *
import sys


context(os='linux', arch='amd64', log_level='debug')

file_name = './pwn'
libc_name = './libc.so.6'
ld_name = './ld-linux-x86-64.so.2'

host = '127.0.0.1'
port = 9999

cipher = b'69c4e0d86a7b0430d8cdb78070b4c55a'


def create_io():
    global io
    global elf
    global libc

    elf = ELF(file_name, checksec=False)
    libc = ELF(libc_name, checksec=False)

    if len(sys.argv) > 2:
        io = remote(sys.argv[1], int(sys.argv[2]))
    else:
        io = process([ld_name, '--library-path', '.', file_name])


def pwn1():
    io.sendline(cipher)
    io.interactive()


create_io()
pwn1()
