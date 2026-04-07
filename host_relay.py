#!/usr/bin/env python3

import argparse
import http.server
import select
import socket
import socketserver
import subprocess
import threading
import time
import urllib.parse


class FlagState:
    def __init__(self, rootfs_image):
        self._lock = threading.Lock()
        self._value = None
        self._rootfs_image = rootfs_image

    def set(self, value):
        value = value.strip()
        if not value:
            return
        with self._lock:
            self._value = value
        print(f"[*] captured flag callback: {value}", flush=True)

    def get(self):
        with self._lock:
            if self._value:
                return self._value

        if not self._rootfs_image:
            return None

        try:
            result = subprocess.run(
                ["debugfs", "-R", "cat /tmp/flag_out", self._rootfs_image],
                capture_output=True,
                text=True,
                timeout=2,
                check=False,
            )
        except (OSError, subprocess.SubprocessError):
            return None

        if result.returncode != 0:
            return None

        value = result.stdout.strip()
        if not value or value == "File not found.":
            return None

        self.set(value)
        return value


class ThreadingHTTPServer(socketserver.ThreadingMixIn, http.server.HTTPServer):
    daemon_threads = True
    allow_reuse_address = True


class CallbackHandler(http.server.BaseHTTPRequestHandler):
    server_version = "HG532FlagCallback/1.0"

    def do_GET(self):
        parsed = urllib.parse.urlsplit(self.path)
        params = urllib.parse.parse_qs(parsed.query, keep_blank_values=True)
        flag = params.get("flag", params.get("f", [""]))[0]
        if not flag:
            flag = urllib.parse.unquote(parsed.path.lstrip("/"))
        self.server.flag_state.set(flag)
        body = b"ok\n"
        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, format, *args):
        return


class ThreadingTCPServer(socketserver.ThreadingMixIn, socketserver.TCPServer):
    daemon_threads = True
    allow_reuse_address = True


class ProxyHandler(socketserver.BaseRequestHandler):
    def handle(self):
        self.request.settimeout(self.server.peek_timeout)
        try:
            initial = self.request.recv(65536)
        except socket.timeout:
            initial = b""
        except OSError:
            return

        if not initial:
            flag = self.server.flag_state.get()
            if not flag:
                return
            try:
                self.request.sendall((flag + "\n").encode())
            except OSError:
                return
            return

        try:
            upstream = socket.create_connection(
                (self.server.target_host, self.server.target_port),
                timeout=self.server.connect_timeout,
            )
        except OSError:
            return

        with upstream:
            self.request.setblocking(False)
            upstream.setblocking(False)

            try:
                upstream.sendall(initial)
            except OSError:
                return

            sockets = [self.request, upstream]
            last_activity = time.monotonic()

            while time.monotonic() - last_activity < self.server.idle_timeout:
                try:
                    readable, _, _ = select.select(sockets, [], [], 0.5)
                except OSError:
                    return

                if not readable:
                    continue

                for source in readable:
                    target = upstream if source is self.request else self.request
                    try:
                        chunk = source.recv(65536)
                    except BlockingIOError:
                        continue
                    except OSError:
                        return

                    if not chunk:
                        return

                    last_activity = time.monotonic()
                    try:
                        target.sendall(chunk)
                    except OSError:
                        return


def parse_args():
    parser = argparse.ArgumentParser(description="HG532 single-port relay")
    parser.add_argument("--listen-host", default="0.0.0.0")
    parser.add_argument("--listen-port", type=int, default=37215)
    parser.add_argument("--target-host", default="127.0.0.1")
    parser.add_argument("--target-port", type=int, default=37216)
    parser.add_argument("--callback-host", default="0.0.0.0")
    parser.add_argument("--callback-port", type=int, default=39000)
    parser.add_argument("--rootfs-image", default="/opt/hg532-ctf/hg532-rootfs.ext2")
    parser.add_argument("--peek-timeout", type=float, default=0.35)
    parser.add_argument("--connect-timeout", type=float, default=3.0)
    parser.add_argument("--idle-timeout", type=float, default=10.0)
    return parser.parse_args()


def main():
    args = parse_args()
    flag_state = FlagState(args.rootfs_image)

    callback_server = ThreadingHTTPServer((args.callback_host, args.callback_port), CallbackHandler)
    callback_server.flag_state = flag_state

    proxy_server = ThreadingTCPServer((args.listen_host, args.listen_port), ProxyHandler)
    proxy_server.flag_state = flag_state
    proxy_server.target_host = args.target_host
    proxy_server.target_port = args.target_port
    proxy_server.peek_timeout = args.peek_timeout
    proxy_server.connect_timeout = args.connect_timeout
    proxy_server.idle_timeout = args.idle_timeout

    callback_thread = threading.Thread(target=callback_server.serve_forever, daemon=True)
    proxy_thread = threading.Thread(target=proxy_server.serve_forever, daemon=True)
    callback_thread.start()
    proxy_thread.start()

    print(
        f"[*] relay listening on {args.listen_host}:{args.listen_port} -> "
        f"{args.target_host}:{args.target_port}",
        flush=True,
    )
    print(
        f"[*] flag callback listener on {args.callback_host}:{args.callback_port}",
        flush=True,
    )

    try:
        callback_thread.join()
        proxy_thread.join()
    except KeyboardInterrupt:
        pass
    finally:
        callback_server.shutdown()
        proxy_server.shutdown()


if __name__ == "__main__":
    main()
