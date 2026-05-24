# Local exp sources

Local exp/solve files were copied on 2026-05-24 from the user's desktop CTF archive:

- CTF archive / test attachments
- CTF archive / worktree area / `1-1`
- CTF archive / authoring area / `1-1`

Copied files:

- `pwn-aespwn/exp.py`
- `pwn-aespwn/solve.py`
- `pwn-json_stack/exp.py`
- `pwn-ret2dlresolve/exp.py`
- `pwn-ret2dlresolve/solve.local.py`
- `pwn-ret2text/exp.py`
- `pwn-snake/exp.py`
- `pwn-snake/exp2.py`
- `pwn-snake_manager/exp.py`
- `pwn-snake_manager/exp.short.py`
- `pwn-snake_manager/exp1.py`
- `pwn-js/solve.js`
- `pwn-router/solve.local.py`
- `core_level0/exp.local.c`
- `CVE2017iot/exp.local_report_flag.py`
- `CVE2017iot/exp.local_diag_sync.py`
- `CVE2017iot/exp.local_interactive.py`
- `_extra_local_exp/pwn-ret2text_revenge/exp.py`
- `pwn-bypass/exp.py`
- `pwn-edit/exp.py`
- `pwn-level0_heap/exp.py`
- `pwn-weboverflow/exp.py`
- `pwn-weboverflow/client`
- `pwn-snake_manager/snake_login.py`
- `pwn-level1_heap/exp.py` was written locally because no matching current exp was found.

Existing files were not overwritten. Different local variants were saved with `.local` or descriptive suffixes.

Small local-run edits were applied to copied scripts only:

- Dynamic local scripts use `./ld-linux-x86-64.so.2 --library-path . ./pwn` where applicable.
- Blocking `gdb.attach(...)` / `pause()` calls in final run paths were commented out.
- `pwn-weboverflow/exp.py` got the missing `import re` and its required `client` helper binary.
