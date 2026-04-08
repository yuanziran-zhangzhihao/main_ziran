#!/bin/bash

set -euo pipefail

LOGIN_USER="${LOGIN_USER:-root}"
LOGIN_PASS="${LOGIN_PASS:-root}"
MOUNT_POINT="${MOUNT_POINT:-/mnt/hg532}"
ROOTFS_DEVICE="${ROOTFS_DEVICE:-}"
ROUTER_PORT="${ROUTER_PORT:-37215}"
SSH_HOST="${SSH_HOST:-127.0.0.1}"
SSH_PORT="${SSH_PORT:-2222}"
SSH_CONNECT_TIMEOUT="${SSH_CONNECT_TIMEOUT:-5}"
SSH_BOOT_TIMEOUT="${SSH_BOOT_TIMEOUT:-120}"
BOOTSTRAP_VIA_SSH="${BOOTSTRAP_VIA_SSH:-0}"
QEMU_GUEST_IFACE="${QEMU_GUEST_IFACE:-eth0}"
QEMU_GUEST_IP="${QEMU_GUEST_IP:-10.0.2.15}"
QEMU_GUEST_NETMASK="${QEMU_GUEST_NETMASK:-255.255.255.0}"
QEMU_GUEST_GW="${QEMU_GUEST_GW:-10.0.2.2}"
NETWORK_SETTLE_DELAY="${NETWORK_SETTLE_DELAY:-15}"
BOOT_TIMEOUT="${BOOT_TIMEOUT:-600}"
STEP_TIMEOUT="${STEP_TIMEOUT:-30}"
ROUTER_START_TIMEOUT="${ROUTER_START_TIMEOUT:-60}"
POLL_INTERVAL="${POLL_INTERVAL:-1}"
SESSION_DIR="${SESSION_DIR:-/tmp/hg532-session}"
CONSOLE_FIFO="${CONSOLE_FIFO:-$SESSION_DIR/console.in}"
CONSOLE_LOG="${CONSOLE_LOG:-$SESSION_DIR/console.log}"
QEMU_PID_FILE="${QEMU_PID_FILE:-$SESSION_DIR/qemu.pid}"
USE_SSH=0
SSH_BASE=()

capture_pane() {
    if [[ -f "$CONSOLE_LOG" ]]; then
        tail -n 120 "$CONSOLE_LOG"
    fi
}

qemu_pid() {
    if [[ -f "$QEMU_PID_FILE" ]]; then
        tr -d '\r\n' < "$QEMU_PID_FILE"
    fi
}

qemu_is_alive() {
    local pid
    pid="$(qemu_pid)"
    [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null
}

wait_for_regex() {
    local regex="$1"
    local timeout="$2"
    local elapsed=0
    local pane

    while (( elapsed < timeout )); do
        pane="$(capture_pane)"
        if printf '%s\n' "$pane" | grep -Eq "$regex"; then
            return 0
        fi
        if ! qemu_is_alive; then
            echo "[-] qemu exited before pattern appeared: $regex" >&2
            printf '%s\n' "$pane" | tail -n 120 >&2
            return 1
        fi
        sleep "$POLL_INTERVAL"
        elapsed=$((elapsed + POLL_INTERVAL))
    done

    echo "[-] timed out waiting for pattern: $regex" >&2
    printf '%s\n' "$pane" | tail -n 120 >&2
    return 1
}

send_line() {
    if ! qemu_is_alive; then
        echo "[-] qemu is not running, cannot send console input" >&2
        exit 1
    fi
    timeout 2 bash -lc 'printf "%s\n" "$1" > "$2"' bash "$1" "$CONSOLE_FIFO" >/dev/null 2>&1
}

build_ssh_base() {
    SSH_BASE=(
        sshpass -p "$LOGIN_PASS"
        ssh
        -o StrictHostKeyChecking=no
        -o UserKnownHostsFile=/dev/null
        -o PreferredAuthentications=password
        -o PubkeyAuthentication=no
        -o NumberOfPasswordPrompts=1
        -o ConnectTimeout="$SSH_CONNECT_TIMEOUT"
        -p "$SSH_PORT"
        "$LOGIN_USER@$SSH_HOST"
    )
}

wait_for_ssh() {
    local timeout="$1"
    local elapsed=0

    while (( elapsed < timeout )); do
        if "${SSH_BASE[@]}" true >/dev/null 2>&1; then
            return 0
        fi
        sleep "$POLL_INTERVAL"
        elapsed=$((elapsed + POLL_INTERVAL))
    done

    return 1
}

run_cmd_console() {
    local cmd="$1"
    local timeout="${2:-$STEP_TIMEOUT}"
    local marker="__HG532_DONE_${RANDOM}_${RANDOM}__"
    local pane
    local status_line
    local status

    send_line "$cmd"
    send_line "printf '${marker}:%s\\n' \$?"
    wait_for_regex "${marker}:[0-9]+" "$timeout"

    pane="$(capture_pane)"
    status_line="$(printf '%s\n' "$pane" | tr -d '\r' | grep -E "${marker}:[0-9]+" | tail -n 1 || true)"
    status="${status_line##*:}"

    if [[ -z "$status_line" || "$status" != "0" ]]; then
        echo "[-] guest command failed via console: $cmd" >&2
        printf '%s\n' "$pane" | tail -n 60 >&2
        exit 1
    fi
}

run_cmd_ssh() {
    local cmd="$1"
    local timeout="${2:-$STEP_TIMEOUT}"
    local quoted

    quoted="$(printf '%q' "$cmd")"

    if ! timeout "$timeout" "${SSH_BASE[@]}" "sh -lc $quoted"; then
        echo "[-] guest command failed via ssh: $cmd" >&2
        exit 1
    fi
}

run_cmd() {
    if [[ "$USE_SSH" == "1" ]]; then
        run_cmd_ssh "$@"
    else
        run_cmd_console "$@"
    fi
}

if ! qemu_is_alive; then
    echo "[-] qemu session not running: $QEMU_PID_FILE" >&2
    exit 1
fi

if [[ "$BOOTSTRAP_VIA_SSH" == "1" ]] && command -v sshpass >/dev/null 2>&1 && command -v ssh >/dev/null 2>&1; then
    build_ssh_base
    if wait_for_ssh "$SSH_BOOT_TIMEOUT"; then
        USE_SSH=1
        echo "[*] guest bootstrap via ssh: ${SSH_HOST}:${SSH_PORT}"
    else
        echo "[*] ssh bootstrap not ready, falling back to console" >&2
    fi
fi

if [[ "$USE_SSH" != "1" ]]; then
    send_line ""
    wait_for_regex 'debian-mips login:|login:|root@[^:]+:.*#' "$BOOT_TIMEOUT"

    if ! capture_pane | grep -Eq 'root@[^:]+:.*#'; then
        send_line ""
        wait_for_regex 'debian-mips login:|login:' 15
        send_line "$LOGIN_USER"
        wait_for_regex 'Password:' 15
        send_line "$LOGIN_PASS"
        wait_for_regex 'root@[^:]+:.*#' 20
    fi
fi

run_cmd "mkdir -p $MOUNT_POINT"
run_cmd "ROOTFS_DEVICE=\"$ROOTFS_DEVICE\"; if [ -z \"\$ROOTFS_DEVICE\" ]; then for candidate in /dev/sdb /dev/hdb /dev/vdb; do if [ -b \"\$candidate\" ]; then ROOTFS_DEVICE=\"\$candidate\"; break; fi; done; fi; [ -n \"\$ROOTFS_DEVICE\" ]"
run_cmd "ROOTFS_DEVICE=\"$ROOTFS_DEVICE\"; if [ -z \"\$ROOTFS_DEVICE\" ]; then for candidate in /dev/sdb /dev/hdb /dev/vdb; do if [ -b \"\$candidate\" ]; then ROOTFS_DEVICE=\"\$candidate\"; break; fi; done; fi; grep -q ' $MOUNT_POINT ' /proc/mounts || mount -t ext2 \"\$ROOTFS_DEVICE\" $MOUNT_POINT"
run_cmd "mkdir -p $MOUNT_POINT/proc $MOUNT_POINT/dev $MOUNT_POINT/sys"
run_cmd "mkdir -p $MOUNT_POINT/tmp && chmod 1777 $MOUNT_POINT/tmp"
run_cmd "grep -q ' $MOUNT_POINT/proc ' /proc/mounts || mount -t proc proc $MOUNT_POINT/proc"
run_cmd "grep -q ' $MOUNT_POINT/dev ' /proc/mounts || mount -o bind /dev $MOUNT_POINT/dev"
run_cmd "grep -q ' $MOUNT_POINT/sys ' /proc/mounts || mount -o bind /sys $MOUNT_POINT/sys || true"
run_cmd "chroot $MOUNT_POINT /bin/sh -c 'killall upnp mic atmcmdd tcwdog >/dev/null 2>&1 || true; rm -f /tmp/router-init.log /tmp/mic.log /tmp/upnp.log /tmp/diag.out; /etc/profile >/tmp/router-init.log 2>&1 &'"
run_cmd "ready=1; for _ in \$(seq 1 $ROUTER_START_TIMEOUT); do if netstat -lnt 2>/dev/null | grep -q ':$ROUTER_PORT '; then ready=0; break; fi; sleep 1; done; test \"\$ready\" -eq 0" $((ROUTER_START_TIMEOUT + 10))
run_cmd "sleep $NETWORK_SETTLE_DELAY" $((NETWORK_SETTLE_DELAY + 5))
run_cmd "ifconfig $QEMU_GUEST_IFACE $QEMU_GUEST_IP netmask $QEMU_GUEST_NETMASK up"
run_cmd "route del default 2>/dev/null || true; route add default gw $QEMU_GUEST_GW dev $QEMU_GUEST_IFACE 2>/dev/null || route change default gw $QEMU_GUEST_GW dev $QEMU_GUEST_IFACE"
run_cmd "ifconfig $QEMU_GUEST_IFACE | grep -q 'inet addr:$QEMU_GUEST_IP'"
run_cmd "rm -f $MOUNT_POINT/tmp/diag.out /tmp/flag-relay.log; sh -c 'while true; do while [ ! -s $MOUNT_POINT/tmp/diag.out ]; do sleep 1; done; while netstat -lnt 2>/dev/null | grep -q :$ROUTER_PORT; do killall upnp >/dev/null 2>&1 || true; killall mic >/dev/null 2>&1 || true; sleep 1; done; until nc -l -p $ROUTER_PORT -q 1 < $MOUNT_POINT/tmp/diag.out; do killall upnp >/dev/null 2>&1 || true; killall mic >/dev/null 2>&1 || true; sleep 1; done; break; done' >/tmp/flag-relay.log 2>&1 &"

echo "[+] router services started inside guest"
