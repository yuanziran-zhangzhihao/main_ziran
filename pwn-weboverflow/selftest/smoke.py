#!/usr/bin/env python3
import argparse
import socket
import sys
import time
from typing import Sequence


def recv_until(sock: socket.socket, markers: Sequence[bytes], timeout: float) -> bytes:
    deadline = time.time() + timeout
    data = bytearray()
    while time.time() < deadline:
        remaining = deadline - time.time()
        sock.settimeout(max(0.1, remaining))
        try:
            chunk = sock.recv(4096)
        except socket.timeout:
            continue
        if not chunk:
            break
        data.extend(chunk)
        if any(marker in data for marker in markers):
            break
    return bytes(data)


def connect_with_retry(host: str, port: int, timeout: float) -> socket.socket:
    deadline = time.time() + timeout
    last_error = None
    while time.time() < deadline:
        try:
            return socket.create_connection((host, port), timeout=1.0)
        except OSError as exc:
            last_error = exc
            time.sleep(0.2)
    raise RuntimeError(f"unable to connect to {host}:{port}: {last_error}")


def run_smoke(host: str, port: int, timeout: float) -> None:
    with connect_with_retry(host, port, timeout) as sock:
        banner = recv_until(
            sock,
            [b"give you two choices:", b"2.get flag"],
            timeout,
        )
        if (
            b"Welcome to this game!" not in banner
            and b"Welcome to the vulnerable server!" not in banner
        ):
            raise RuntimeError(f"missing entry banner, got: {banner!r}")
        if b"give you two choices:" not in banner:
            raise RuntimeError(f"missing menu banner, got: {banner!r}")

        sock.sendall(b"2\nAAAA\n")
        sock.shutdown(socket.SHUT_WR)
        reply = recv_until(sock, [b"Data processed. Goodbye."], timeout)
        if b"Data processed. Goodbye." not in reply:
            raise RuntimeError(f"missing processing reply, got: {reply!r}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Smoke test for pwn-weboverflow")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8000)
    parser.add_argument("--timeout", type=float, default=10.0)
    args = parser.parse_args()

    try:
        run_smoke(args.host, args.port, args.timeout)
    except Exception as exc:
        print(f"[smoke] failed: {exc}", file=sys.stderr)
        return 1

    print("[smoke] ok")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
