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
    parser.add_argument("--timeout", type=float, default=8.0)
    parser.add_argument("--ready-timeout", type=float, default=60.0)
    args = parser.parse_args()

    deadline = time.time() + args.ready_timeout
    last_error = None

    while time.time() < deadline:
        try:
            with socket.create_connection((args.host, args.port), timeout=args.timeout) as sock:
                sock.settimeout(args.timeout)

                menu = recv_until(sock, b"2.login admin", args.timeout)
                sys.stdout.write(menu.decode("latin1", "replace"))

                sock.sendall(b"1\n")
                game = recv_until(sock, b"Press 'q' to quit", args.timeout)
                sys.stdout.write(game.decode("latin1", "replace"))

                sock.sendall(b"q")
                end = recv_until(sock, b"Final Score: 0", args.timeout)
                sys.stdout.write(end.decode("latin1", "replace"))
                if b"Game Over!" not in end:
                    print("missing Game Over marker", file=sys.stderr)
                    return 1

                menu2 = recv_until(sock, b"2.login admin", args.timeout)
                sys.stdout.write(menu2.decode("latin1", "replace"))

                sock.sendall(b"2\n")
                login = recv_until(sock, b"Enter admin name:", args.timeout)
                sys.stdout.write(login.decode("latin1", "replace"))

                sock.sendall(b"guest\n")
                denied = recv_until(sock, b"No such user.", args.timeout)
                sys.stdout.write(denied.decode("latin1", "replace"))

                print("[+] smoke test matched expected menu, TUI, and admin-login flow")
                return 0
        except Exception as exc:
            last_error = exc
            time.sleep(1.0)

    print(f"[-] smoke test failed before ready timeout: {last_error}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
