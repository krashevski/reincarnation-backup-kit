#!/usr/bin/env bash
# =============================================================
# /lib/privileges.sh - privilege checks
# -------------------------------------------------------------
# Использование privileges.sh
:<<'DOC'
source "$LIB_DIR/logging.sh"
source "$LIB_DIR/privileges.sh"

require_root || return 1
DOC
# =============================================================

set -o errexit
set -o pipefail

# -------------------------------------------------------------
# Защита от повторного подключения
# -------------------------------------------------------------
[[ -n "${_REBK_PRIVILEGES_LOADED:-}" ]] && return 0
_REBK_PRIVILEGES_LOADED=1

set -o errexit
set -o pipefail

# -------------------------------------------------------------
# runtime-проверка зависимоси от logging.sh
# -------------------------------------------------------------
type error >/dev/null 2>&1 || {
    echo "privileges.sh requires logging.sh" >&2
    return 1
}

require_root() {
    if [[ $EUID -ne 0 ]]; then
        info exec_via_sudo
        exec sudo "$0" "$@"
    fi
}

REBK_CHOWN_EXCLUDES=(
    br_workdir
    '.Trash-*'
)

# --- Исправление прав (кроме REBK_CHOWN_EXCLUDES) ---
fix_backup_dir_permissions() {
    local dir="$1"
    local user="${SUDO_USER:-$USER}"
    local group
    group="$(id -gn "$user")"

    local prune_expr=()
    for ex in "${REBK_CHOWN_EXCLUDES[@]}"; do
        prune_expr+=( -name "$ex" -o )
    done
    unset 'prune_expr[${#prune_expr[@]}-1]'

    find "$dir" -mindepth 1 \
        \( "${prune_expr[@]}" \) -prune -o \
        -exec chown "$user:$group" {} + 2>/dev/null
}

