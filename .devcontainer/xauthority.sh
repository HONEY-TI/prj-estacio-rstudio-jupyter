#!/usr/bin/env bash

set -Eeuo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

OUT="$DIR/.xauth-path"

RUNTIME_DIR="/run/user/$(id -u)"

XAUTH_FILE="$(
    ls -t "$RUNTIME_DIR"/.mutter-Xwaylandauth.* 2>/dev/null |
    head -1 ||
    true
)"

if [[ -z "$XAUTH_FILE" ]]; then
    echo "[xauth] nenhum .mutter-Xwaylandauth.* encontrado em $RUNTIME_DIR" >&2
    : > "$OUT"
else
    echo "$XAUTH_FILE" > "$OUT"
    echo "[xauth] caminho gravado em $OUT: $XAUTH_FILE"
fi

exit 0