#!/usr/bin/env python3
import argparse
import socket
import sys
import time


EXPECTED_CT = b"69c4e0d86a7b0430d8cdb78070b4c55a"


def recv_until(sock: socket.socket, needle: bytes, timeout: float) -> bytes:
    deadline = time.time() + timeout
    data = bytearray()
    while time.time() < deadline:
        try:
            chunk = sock.recv(4096)
        except socket.timeout:
            continue
        if not chunk:
            break
        data.extend(chunk)
        if needle in data:
            return bytes(data)
    tail = bytes(data)[-400:]
    raise RuntimeError(f"did not receive expected marker: {needle!r}; received tail={tail!r}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", required=True)
    parser.add_argument("--port", required=True, type=int)
    parser.add_argument("--timeout", type=float, default=10.0)
    parser.add_argument("--ready-timeout", type=float, default=60.0)
    parser.add_argument("--expect", default="FLAG{ci_smoke_test}")
    args = parser.parse_args()

    deadline = time.time() + args.ready_timeout
    last_error = None

    while time.time() < deadline:
        try:
            with socket.create_connection((args.host, args.port), timeout=args.timeout) as sock:
                sock.settimeout(args.timeout)

                sock.sendall(EXPECTED_CT + b"\n")
                time.sleep(0.5)
                sock.sendall(b"/bin/cat /flag || /bin/cat flag\n")
                sock.shutdown(socket.SHUT_WR)
                data = recv_until(sock, args.expect.encode(), args.timeout)
                text = data.decode("latin1", "replace")
                sys.stdout.write(text)

                if "FAIL: not match." in text:
                    print("ciphertext was rejected", file=sys.stderr)
                    return 1
                if "No such file" in text:
                    print("flag path was not readable inside the exploit shell", file=sys.stderr)
                    return 1

                print("[+] smoke test matched expected exploit-to-shell flow")
                return 0
        except Exception as exc:
            last_error = exc
            time.sleep(1.0)

    print(f"[-] smoke test failed before ready timeout: {last_error}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
