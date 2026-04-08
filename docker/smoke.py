#!/usr/bin/env python3
import argparse
import base64
import socket
import sys
import time
from pathlib import Path


def recv_until(sock: socket.socket, marker: bytes, timeout: float) -> bytes:
    deadline = time.time() + timeout
    data = bytearray()

    while time.time() < deadline:
        if marker in data:
            return bytes(data)
        sock.settimeout(max(0.1, deadline - time.time()))
        try:
            chunk = sock.recv(4096)
        except socket.timeout:
            continue
        if not chunk:
            break
        data.extend(chunk)

    return bytes(data)


def send_text(sock: socket.socket, text: str) -> None:
    sock.sendall(text.encode())


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", required=True)
    parser.add_argument("--port", required=True, type=int)
    parser.add_argument("--payload", required=True)
    parser.add_argument("--expect", required=True)
    parser.add_argument("--boot-timeout", type=float, default=90.0)
    parser.add_argument("--flag-timeout", type=float, default=120.0)
    args = parser.parse_args()

    payload = base64.b64encode(Path(args.payload).read_bytes()).decode()
    payload_lines = [payload[idx:idx + 76] for idx in range(0, len(payload), 76)]

    with socket.create_connection((args.host, args.port), timeout=10.0) as sock:
        boot = recv_until(sock, b"ctf$ ", args.boot_timeout)
        sys.stdout.buffer.write(boot)
        sys.stdout.flush()

        if b"ctf$ " not in boot:
            print("[-] prompt did not appear", file=sys.stderr)
            return 1

        send_text(sock, "stty -echo; PS2=''\n")
        prompt = recv_until(sock, b"ctf$ ", 10.0)
        sys.stdout.buffer.write(prompt)
        sys.stdout.flush()

        send_text(sock, "cat >/tmp/exp.b64 <<'EOF'\n")
        for line in payload_lines:
            send_text(sock, line + "\n")
        send_text(sock, "EOF\n")

        prompt = recv_until(sock, b"ctf$ ", 60.0)
        sys.stdout.buffer.write(prompt)
        sys.stdout.flush()

        if b"ctf$ " not in prompt:
            print("[-] upload did not finish cleanly", file=sys.stderr)
            return 1

        send_text(
            sock,
            "/bin/b64dec /tmp/exp.b64 /tmp/exp && chmod 700 /tmp/exp && "
            "rm -f /tmp/exp.b64 && /tmp/exp\n",
        )

        result = recv_until(sock, args.expect.encode(), args.flag_timeout)
        sys.stdout.buffer.write(result)
        sys.stdout.flush()

        if args.expect.encode() not in result:
            print("[-] expected flag string not found", file=sys.stderr)
            return 1

    print("[+] smoke test matched expected flag")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
