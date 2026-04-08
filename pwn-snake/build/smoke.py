#!/usr/bin/env python3
import argparse
import socket
import sys
import time
from typing import List, Optional, Tuple


class BufferedSocket:
    def __init__(self, sock: socket.socket) -> None:
        self.sock = sock
        self.buf = bytearray()

    def _extract(self, needles: List[bytes]) -> Optional[Tuple[bytes, bytes]]:
        matches = []
        for needle in needles:
            idx = self.buf.find(needle)
            if idx != -1:
                matches.append((idx, needle))

        if not matches:
            return None

        idx, needle = min(matches, key=lambda item: item[0])
        end = idx + len(needle)
        data = bytes(self.buf[:end])
        del self.buf[:end]
        return data, needle

    def recv_until(self, needle: bytes, timeout: float) -> bytes:
        data, _ = self.recv_until_any([needle], timeout)
        return data

    def recv_until_any(self, needles: List[bytes], timeout: float) -> Tuple[bytes, bytes]:
        deadline = time.time() + timeout
        while time.time() < deadline:
            found = self._extract(needles)
            if found is not None:
                return found

            remaining = deadline - time.time()
            self.sock.settimeout(max(0.1, remaining))
            chunk = self.sock.recv(4096)
            if not chunk:
                break
            self.buf.extend(chunk)

        found = self._extract(needles)
        if found is not None:
            return found

        raise RuntimeError(f"did not receive expected markers: {needles!r}")


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
                buffered = BufferedSocket(sock)

                sock.sendall(b"q\n")
                after_input, marker = buffered.recv_until_any(
                    [b"Any last words?", b"Final Score: 0"],
                    args.timeout,
                )
                sys.stdout.write(after_input.decode("latin1", "replace"))

                final = after_input
                if marker == b"Any last words?":
                    sock.sendall(b"smoke-check\n")
                    final = buffered.recv_until(b"Final Score: 0", args.timeout)
                    sys.stdout.write(final.decode("latin1", "replace"))

                transcript = after_input + (b"" if marker == b"Final Score: 0" else final)
                if b"Game Over!" not in transcript:
                    print("missing Game Over marker", file=sys.stderr)
                    return 1

                print("[+] smoke test matched expected snake quit flow")
                return 0
        except Exception as exc:
            last_error = exc
            time.sleep(1.0)

    print(f"[-] smoke test failed before ready timeout: {last_error}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
