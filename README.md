# babyioctl

## Overview

`babyioctl` is a beginner-friendly kernel pwn challenge built around an out-of-bounds read in `ioctl`.

This branch now supports both delivery paths:

- player attachments: `bzImage`, `rootfs.cpio.gz`, `run.sh`
- platform deployment: single-port Docker container on `1337/tcp`

## Vulnerability

The bug is in the driver read length handling.

- `BABY_IOCTL_SET_SIZE` lets the player control `g_read_size`
- `BABY_IOCTL_READ` copies `g_read_size` bytes starting from `g_blob.note`
- `g_blob.note` is only `0x40` bytes long
- `g_blob.flag` is placed immediately after `note`

That means the intended solve is to set the read size to `0x80` and leak both buffers in one shot.

## Files

- `babydriver.c`: vulnerable kernel module
- `exp.c`: local reference exploit
- `initramfs/init`: guest init script
- `docker/build.sh`: builds the kernel bundle and helper artifacts
- `docker/start.sh`: prepares a runtime initramfs with the real flag and starts the TCP service
- `docker/session.sh`: launches one QEMU session per connection
- `docker/smoke.py`: black-box smoke test against the exposed TCP service
- `run.sh`: local QEMU launcher for the player attachment bundle

## Player Attachment Bundle

```bash
docker build -t core_level0:local .
cid="$(docker create core_level0:local)"
mkdir -p attachments
docker cp "$cid:/opt/core_level0/attachments/." ./attachments/
docker rm -v "$cid"
```

This exports:

- `bzImage`
- `rootfs.cpio.gz`
- `run.sh`
- `babydriver.c`
- `exp.c`
- `README.md`

The attachment bundle uses a placeholder local flag. The real platform flag is injected at container runtime.

## Run The Local Bundle

Requirements on the host:

- `qemu-system-x86_64`

Then run:

```bash
cd attachments
./run.sh
```

The VM boots into a `ctf` shell and auto-loads the vulnerable module.

## Run The Docker Service

```bash
docker compose up --build challenge
```

Then connect:

```bash
nc 127.0.0.1 1337
```

The remote service also lands in the guest serial console as `ctf`.

## Solve Path

1. Open `/dev/babyioctl`
2. Use `BABY_IOCTL_SET_SIZE` to set the read size to `0x80`
3. Use `BABY_IOCTL_READ` to leak memory
4. Search the leaked buffer for the printable `{...}` candidate

For remote play, upload a prebuilt static exploit into the guest with `/bin/b64dec`.

## Notes

- This challenge is intentionally simple and deterministic
- There is no race condition, UAF, ROP, or privilege escalation path
- The platform container exposes only one port
- The runtime flag is injected when the Docker container starts
