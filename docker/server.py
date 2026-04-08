#!/usr/bin/env python3
import os
import socket
import socketserver
import subprocess


BIND_HOST = os.environ.get("BIND_HOST", "0.0.0.0")
PORT = int(os.environ.get("PORT", "9999"))
READ_IDLE_TIMEOUT = float(os.environ.get("READ_IDLE_TIMEOUT", "0.5"))
MAX_SCRIPT_SIZE = int(os.environ.get("MAX_SCRIPT_SIZE", str(256 * 1024)))
CHALLENGE_SESSION = os.environ.get("CHALLENGE_SESSION", "/usr/local/bin/challenge-session")
BANNER = b"quickjs-uaf-baby\nsend a JavaScript exploit script, then stop sending data\n"


class ThreadedTCPServer(socketserver.ThreadingMixIn, socketserver.TCPServer):
    allow_reuse_address = True
    daemon_threads = True


class ChallengeHandler(socketserver.BaseRequestHandler):
    def handle(self):
        self.request.settimeout(READ_IDLE_TIMEOUT)
        chunks = []
        total = 0

        while total < MAX_SCRIPT_SIZE:
            want = min(4096, MAX_SCRIPT_SIZE - total)
            try:
                chunk = self.request.recv(want)
            except socket.timeout:
                break
            except OSError:
                return

            if not chunk:
                break

            chunks.append(chunk)
            total += len(chunk)

        payload = b"".join(chunks)
        if not payload.strip():
            self._send(BANNER)
            return

        env = os.environ.copy()
        try:
            proc = subprocess.run(
                ["bash", CHALLENGE_SESSION],
                input=payload,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                timeout=int(env.get("SESSION_TIMEOUT", "30")) + 2,
                env=env,
                check=False,
            )
            self._send(proc.stdout)
        except subprocess.TimeoutExpired:
            self._send(b"[!] session timed out\n")

    def _send(self, data: bytes):
        if not data:
            return
        try:
            self.request.sendall(data)
        except OSError:
            pass


def main():
    with ThreadedTCPServer((BIND_HOST, PORT), ChallengeHandler) as server:
        print(f"[*] quickjs-uaf-baby listening on {BIND_HOST}:{PORT}", flush=True)
        print("[*] send a JavaScript file, then stop sending data", flush=True)
        server.serve_forever()


if __name__ == "__main__":
    main()
