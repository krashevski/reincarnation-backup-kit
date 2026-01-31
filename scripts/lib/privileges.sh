#!/usr/bin/env bash
# =============================================================
# /scripts/lib/privileges.sh
# Privilege checks
# -------------------------------------------------------------
# Использование privileges.sh
# SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# LIB_DIR="$SCRIPT_DIR/lib"
:<<'DOC'
=============================================================
LANG_CODE=ru
export RUN_LOG="/var/log/rebk.log"
source "$LIB_DIR/logging.sh"
source "$LIB_DIR/privileges.sh"

require_root || return 1
=============================================================
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

