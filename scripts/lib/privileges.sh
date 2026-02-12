#!/usr/bin/env bash
# =============================================================
# /scripts/lib/privileges.sh - privilege checks
# -------------------------------------------------------------
# Использование privileges.sh
:<<'DOC'
source "$LIB_DIR/logging.sh"
source "$LIB_DIR/privileges.sh"

require_root || return 1
DOC

set -o errexit
set -o pipefail

# -------------------------------------------------------------
# Защита от повторного подключения
# -------------------------------------------------------------
[[ -n "${_REBK_PRIVILEGES_LOADED:-}" ]] && return 0
_REBK_PRIVILEGES_LOADED=1

# -------------------------------------------------------------
# runtime-проверка зависимоси от logging.sh
# -------------------------------------------------------------
type error >/dev/null 2>&1 || {
    echo "privileges.sh requires logging.sh" >&2
    return 1
}

require_root() {
    if [[ $EUID -ne 0 ]]; then
        error run_sudo
        return 1
    fi
    return 0
}

