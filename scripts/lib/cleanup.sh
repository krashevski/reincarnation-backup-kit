#!/usr/bin/env bash
# =============================================================
# /scripts/lib/cleanup.sh — lifecycle cleanup helpers
# Requires: logging.sh
# -------------------------------------------------------------
# Использование cleanup.sh
# SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# LIB_DIR="$SCRIPT_DIR/lib"
#
# source "$LIB_DIR/logging.sh"
# source "$LIB_DIR/cleanup.sh"
# 
# WORKDIR="$(mktemp -d)"
#
# cleanup_custom() {
#     echo "my cleanup"
# }
# 
# trap 'cleanup_custom; cleanup_workdir "$WORKDIR"' EXIT INT TERM
# =============================================================

set -o errexit
set -o pipefail

# -------------------------------------------------------------
# Защита от повторного подключения
# -------------------------------------------------------------
[[ -n "${_REBK_CLEANUP_LOADED:-}" ]] && return 0
_REBK_CLEANUP_LOADED=1

# -------------------------------------------------------------
# runtime-проверка зависимоси от logging.sh
# -------------------------------------------------------------
type info >/dev/null 2>&1 || {
    echo "cleanup.sh requires logging.sh" >&2
    return 1
}

cleanup_workdir() {
    local dir="$1"

    [[ -z "$dir" ]] && return 0
    [[ "$dir" == "/" ]] && {
        error clean_invalid_dir "$dir" || true
        return 1
    }

    if [[ -d "$dir" ]]; then
        info clean_tmp "$dir"
        rm -rf --one-file-system "$dir" || true
        ok clean_ok
    fi
}

register_cleanup() {
    local dir="$1"
    trap "cleanup_workdir '$dir'" EXIT INT TERM
}

# -------------------------------------------------------------
# Экспорт say как readonly API
# -------------------------------------------------------------
readonly -f say ok info warn error die
