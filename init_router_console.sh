#!/bin/bash

set -euo pipefail

TMUX_SESSION="${TMUX_SESSION:-hg532}"
LOGIN_USER="${LOGIN_USER:-root}"
LOGIN_PASS="${LOGIN_PASS:-root}"
MOUNT_POINT="${MOUNT_POINT:-/mnt/hg532}"
ROOTFS_DEVICE="${ROOTFS_DEVICE:-}"
ROUTER_PORT="${ROUTER_PORT:-37215}"
QEMU_GUEST_IFACE="${QEMU_GUEST_IFACE:-eth0}"
QEMU_GUEST_IP="${QEMU_GUEST_IP:-10.0.2.15}"
QEMU_GUEST_NETMASK="${QEMU_GUEST_NETMASK:-255.255.255.0}"
QEMU_GUEST_GW="${QEMU_GUEST_GW:-10.0.2.2}"
NETWORK_SETTLE_DELAY="${NETWORK_SETTLE_DELAY:-15}"
BOOT_TIMEOUT="${BOOT_TIMEOUT:-600}"
STEP_TIMEOUT="${STEP_TIMEOUT:-30}"
POLL_INTERVAL="${POLL_INTERVAL:-1}"

capture_pane() {
    tmux capture-pane -pS -80 -t "$TMUX_SESSION" 2>/dev/null || true
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
        sleep "$POLL_INTERVAL"
        elapsed=$((elapsed + POLL_INTERVAL))
    done

    echo "[-] timed out waiting for pattern: $regex" >&2
    printf "%s\n" "$pane" | tail -n 80 >&2
    return 1
}

send_line() {
    tmux send-keys -t "$TMUX_SESSION" -l "$1"
    tmux send-keys -t "$TMUX_SESSION" Enter
}

run_cmd() {
    local cmd="$1"
    local timeout="${2:-$STEP_TIMEOUT}"
    local marker="__HG532_DONE_${RANDOM}_${RANDOM}__"
    local pane
    local status_line
    local status

    send_line "$cmd"
    send_line "printf '${marker}:%s\n' \$?"
    wait_for_regex "${marker}:[0-9]+" "$timeout"

    pane="$(capture_pane)"
    status_line="$(printf '%s\n' "$pane" | grep -E "${marker}:[0-9]+" | tail -n 1 || true)"
    status="${status_line##*:}"

    if [[ -z "$status_line" || "$status" != "0" ]]; then
        echo "[-] guest command failed: $cmd" >&2
        printf '%s\n' "$pane" | tail -n 40 >&2
        exit 1
    fi
}

if ! tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
    echo "[-] tmux session not found: $TMUX_SESSION" >&2
    exit 1
fi

wait_for_regex 'debian-mips login:|root@debian-mips:.*#' "$BOOT_TIMEOUT"

if ! capture_pane | grep -Eq 'root@debian-mips:.*#'; then
    tmux send-keys -t "$TMUX_SESSION" Enter
    wait_for_regex 'debian-mips login:' 10
    send_line "$LOGIN_USER"
    wait_for_regex 'Password:' 15
    send_line "$LOGIN_PASS"
    wait_for_regex 'root@debian-mips:.*#' 20
fi

run_cmd "mkdir -p $MOUNT_POINT"
run_cmd "ROOTFS_DEVICE=\"$ROOTFS_DEVICE\"; if [ -z \"\$ROOTFS_DEVICE\" ]; then for candidate in /dev/sdb /dev/hdb /dev/vdb; do if [ -b \"\$candidate\" ]; then ROOTFS_DEVICE=\"\$candidate\"; break; fi; done; fi; [ -n \"\$ROOTFS_DEVICE\" ]"
run_cmd "ROOTFS_DEVICE=\"$ROOTFS_DEVICE\"; if [ -z \"\$ROOTFS_DEVICE\" ]; then for candidate in /dev/sdb /dev/hdb /dev/vdb; do if [ -b \"\$candidate\" ]; then ROOTFS_DEVICE=\"\$candidate\"; break; fi; done; fi; grep -q ' $MOUNT_POINT ' /proc/mounts || mount -t ext2 \"\$ROOTFS_DEVICE\" $MOUNT_POINT"
run_cmd "mkdir -p $MOUNT_POINT/proc $MOUNT_POINT/dev $MOUNT_POINT/sys"
run_cmd "grep -q ' $MOUNT_POINT/proc ' /proc/mounts || mount -t proc proc $MOUNT_POINT/proc"
run_cmd "grep -q ' $MOUNT_POINT/dev ' /proc/mounts || mount -o bind /dev $MOUNT_POINT/dev"
run_cmd "grep -q ' $MOUNT_POINT/sys ' /proc/mounts || mount -o bind /sys $MOUNT_POINT/sys || true"
run_cmd "chroot $MOUNT_POINT /bin/sh -c 'killall upnp mic atmcmdd tcwdog >/dev/null 2>&1 || true; rm -f /tmp/router-init.log /tmp/mic.log /tmp/upnp.log /tmp/flag_out; /etc/profile >/tmp/router-init.log 2>&1 &'"
run_cmd "ready=1; for _ in 1 2 3 4 5 6 7 8 9 10; do if netstat -lnt 2>/dev/null | grep -q ':$ROUTER_PORT '; then ready=0; break; fi; sleep 1; done; test \"\$ready\" -eq 0" 20
run_cmd "sleep $NETWORK_SETTLE_DELAY" $((NETWORK_SETTLE_DELAY + 5))
run_cmd "ifconfig $QEMU_GUEST_IFACE $QEMU_GUEST_IP netmask $QEMU_GUEST_NETMASK up"
run_cmd "route del default 2>/dev/null || true; route add default gw $QEMU_GUEST_GW dev $QEMU_GUEST_IFACE 2>/dev/null || route change default gw $QEMU_GUEST_GW dev $QEMU_GUEST_IFACE"
run_cmd "ifconfig $QEMU_GUEST_IFACE | grep -q 'inet addr:$QEMU_GUEST_IP'"
run_cmd "rm -f $MOUNT_POINT/tmp/flag_out /tmp/flag-relay.log; sh -c 'while true; do while [ ! -s $MOUNT_POINT/tmp/flag_out ]; do sleep 1; done; killall upnp >/dev/null 2>&1 || true; killall mic >/dev/null 2>&1 || true; for _ in 1 2 3 4 5; do if ! netstat -lnt 2>/dev/null | grep -q :$ROUTER_PORT; then break; fi; sleep 1; done; cat $MOUNT_POINT/tmp/flag_out | nc -l -p $ROUTER_PORT -q 1 >/dev/null 2>&1; break; done' >/tmp/flag-relay.log 2>&1 &"

echo "[+] router services started inside guest"
