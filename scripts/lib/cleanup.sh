#!/usr/bin/env bash
# =============================================================
# /scripts/lib/cleanup.sh — lifecycle cleanup helpers
# Requires: logging.sh
# -------------------------------------------------------------
# Использование cleanup.sh
# SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# LIB_DIR="$SCRIPT_DIR/lib"
:<<'DOC'
source "$LIB_DIR/directories.sh"
source "$LIB_DIR/logging.sh"
source "$LIB_DIR/privileges.sh"
source "$LIB_DIR/safety.sh"
source "$LIB_DIR/cleanup.sh"

register_cleanup "$WORKDIR"

main() {
    init_user_dirs || exit 1
    init_system_dirs || exit 1

    run_backup
}

main "$@"

trap 'cleanup_custom; cleanup_workdir "$WORKDIR"' EXIT INT TERM
DOC

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

    info clean_tmp "$dir"

    safe_rm_rf "$dir" || return 1

    ok clean_ok
}

register_cleanup() {
    local dir="$1"
    trap "cleanup_workdir '$dir'" EXIT INT TERM
}


# -------------------------------------------------------------
# Экспорт say как readonly API
# -------------------------------------------------------------
readonly -f say ok info warn error die