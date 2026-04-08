# core_level0 Platform Deploy

## Deploy Target

- Image package: `ghcr.io/<owner>/core_level0`
- Exposed port: `1337/tcp`
- Runtime mode: single-port TCP service, one QEMU session per connection

## Runtime Flag Sources

The container picks the first non-empty value from:

1. `A1CTF_FLAG`
2. `PCTF_FLAG`
3. `GZCTF_FLAG`
4. `FLAG`
5. `FLAG_VALUE`

If none is provided, it falls back to a random `FLAG{...}` value.

## Player View

- The connection lands in the guest serial console.
- The guest shell is `ctf`, not `root`.
- The vulnerable device is `/dev/babyioctl`.
- A small upload helper exists at `/bin/b64dec`.

## Local Manual Run

```bash
docker build -t core_level0:local .
docker run --rm -it -p 1337:1337 -e 'FLAG=FLAG{demo_runtime_flag}' core_level0:local
```

Then connect:

```bash
nc 127.0.0.1 1337
```
