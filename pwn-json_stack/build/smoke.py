#!/usr/bin/env python3
import argparse
import socket
import struct
import sys
import time


def recv_exact(sock: socket.socket, size: int) -> bytes:
    chunks = []
    remaining = size
    while remaining > 0:
        chunk = sock.recv(remaining)
        if not chunk:
            raise RuntimeError("connection closed before full response was received")
        chunks.append(chunk)
        remaining -= len(chunk)
    return b"".join(chunks)


def roundtrip(host: str, port: int, payload: bytes, timeout: float) -> bytes:
    with socket.create_connection((host, port), timeout=timeout) as sock:
        sock.settimeout(timeout)
        sock.sendall(struct.pack("<I", len(payload)))
        sock.sendall(payload)
        resp_len = struct.unpack("<I", recv_exact(sock, 4))[0]
        return recv_exact(sock, resp_len)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", required=True)
    parser.add_argument("--port", required=True, type=int)
    parser.add_argument("--timeout", type=float, default=5.0)
    parser.add_argument("--ready-timeout", type=float, default=60.0)
    args = parser.parse_args()

    payload = b'{"data":"nope"}'
    expected = b'"bad cmd"'
    deadline = time.time() + args.ready_timeout
    last_error = None

    while time.time() < deadline:
        try:
            first = roundtrip(args.host, args.port, payload, args.timeout)
            second = roundtrip(args.host, args.port, payload, args.timeout)
            print(first)
            print(second)
            if first != expected or second != expected:
                print("unexpected response payload", file=sys.stderr)
                return 1
            print("[+] smoke test matched expected bad-cmd behavior twice")
            return 0
        except Exception as exc:
            last_error = exc
            time.sleep(1.0)

    print(f"[-] smoke test failed before ready timeout: {last_error}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
