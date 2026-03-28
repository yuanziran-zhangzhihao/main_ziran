# babyioctl

## Overview

`babyioctl` is a beginner-friendly kernel pwn challenge built around an out-of-bounds read in `ioctl`.

The final release format is the usual CTF kernel bundle:

- `bzImage`
- `rootfs.cpio.gz`
- `run.sh`

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
- `initramfs/init`: init script used inside the CTF rootfs
- `docker/build.sh`: builds the full CTF bundle
- `docker-compose.yml`: Docker entrypoint for one-command packaging
- `run.sh`: launches the challenge in QEMU

## Build The CTF Bundle

```bash
docker compose up --build builder
```

This produces:

- `bzImage`
- `rootfs.cpio.gz`
- `babydriver.ko`
- `exp`

The Docker image installs an Ubuntu generic kernel and matching headers, so the generated `bzImage` and `babydriver.ko` are built for the same kernel version.

## Run The Challenge

Requirements on the host:

- `qemu-system-x86_64`

Then run:

```bash
./run.sh
```

The VM boots directly into a shell and auto-loads the vulnerable module.

## Solve Path

1. Open `/dev/babyioctl`
2. Use `BABY_IOCTL_SET_SIZE` to set the read size to `0x80`
3. Use `BABY_IOCTL_READ` to leak memory
4. Search the leaked buffer for `flag{`

## Notes

- This challenge is intentionally simple and deterministic
- There is no race condition, UAF, ROP, or privilege escalation path
- It is suitable as a first kernel pwn challenge or warm-up problem
