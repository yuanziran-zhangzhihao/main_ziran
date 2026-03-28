# Solution

The bug is in `BABY_IOCTL_SET_SIZE`:

```c
g_read_size = user_size;
```

There is no upper bound check.

Later, `BABY_IOCTL_READ` does:

```c
copy_to_user(req.buf, g_blob.note, g_read_size);
```

But `g_blob.note` is only `0x40` bytes long.

The memory layout is:

```c
struct baby_blob {
    char note[0x40];
    char flag[0x40];
};
```

So if the player sets `g_read_size` to `0x80`, the kernel copies both `note` and `flag` back to user space.

Minimal exploit flow:

1. `open("/dev/babyioctl", O_RDWR)`
2. `ioctl(fd, BABY_IOCTL_SET_SIZE, &size)` where `size = 0x80`
3. `ioctl(fd, BABY_IOCTL_READ, &req)`
4. Search the leaked buffer for `flag{`

The included `exp.c` already demonstrates the intended solve path.
