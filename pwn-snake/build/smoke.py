#!/usr/bin/env python3
import argparse
import socket
import sys
import time


def recv_until(sock: socket.socket, needle: bytes, timeout: float) -> bytes:
    deadline = time.time() + timeout
    data = bytearray()
    while time.time() < deadline:
        chunk = sock.recv(4096)
        if not chunk:
            break
        data.extend(chunk)
        if needle in data:
            return bytes(data)
    raise RuntimeError(f"did not receive expected marker: {needle!r}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", required=True)
    parser.add_argument("--port", required=True, type=int)
    parser.add_argument("--timeout", type=float, default=5.0)
    parser.add_argument("--ready-timeout", type=float, default=60.0)
    args = parser.parse_args()

    deadline = time.time() + args.ready_timeout
    last_error = None

    while time.time() < deadline:
        try:
            with socket.create_connection((args.host, args.port), timeout=args.timeout) as sock:
                sock.settimeout(args.timeout)

                banner = recv_until(sock, b"Press 'q' to quit", args.timeout)
                sys.stdout.write(banner.decode("latin1", "replace"))

                sock.sendall(b"q\n")
                prompt = recv_until(sock, b"Any last words?", args.timeout)
                sys.stdout.write(prompt.decode("latin1", "replace"))

                sock.sendall(b"smoke-check\n")
                final = recv_until(sock, b"Final Score: 0", args.timeout)
                sys.stdout.write(final.decode("latin1", "replace"))

                if b"Game Over!" not in final:
                    print("missing Game Over marker", file=sys.stderr)
                    return 1

                print("[+] smoke test matched expected snake exit flow")
                return 0
        except Exception as exc:
            last_error = exc
            time.sleep(1.0)

    print(f"[-] smoke test failed before ready timeout: {last_error}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
