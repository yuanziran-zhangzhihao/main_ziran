# Run notes

- Run pwntools scripts from inside their own challenge directory.
- For dynamic ELF scripts, local execution is patched to use the bundled `ld-linux-x86-64.so.2` and `libc.so.6`.
- `pwn-edit` and `pwn-level1_heap` are static binaries, so no libc patching is needed for those two.
- Snake ncurses scripts set `TERM=xterm` for local process runs.
- `pwn-level0_heap/exp.py` defaults to `127.0.0.1:6666`; use the challenge container or run with `LOCAL=1` in a Linux environment.
- `pwn-level1_heap/exp.py` is a locally written static-binary exploit draft; the rest are copied/adapted local scripts.
