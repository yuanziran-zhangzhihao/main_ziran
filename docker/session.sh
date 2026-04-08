#!/usr/bin/env bash
set -euo pipefail

QJS_BIN="${QJS_BIN:-/work/quickjs-2024-01-13/qjs}"
SESSION_TIMEOUT="${SESSION_TIMEOUT:-30}"
tmp_dir="$(mktemp -d)"
script_path="${tmp_dir}/input.js"

cleanup() {
    rm -rf "${tmp_dir}" 2>/dev/null || true
}

trap cleanup EXIT INT TERM

cat >"${script_path}"

if [[ ! -s "${script_path}" ]]; then
    cat <<'EOF'
quickjs-uaf-baby
send a JavaScript exploit script, then close the connection
EOF
    exit 0
fi

timeout "${SESSION_TIMEOUT}" "${QJS_BIN}" "${script_path}"
