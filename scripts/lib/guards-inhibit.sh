#!/usr/bin/env bash
# =============================================================
# /scripts/lib/guards-inhibit.sh
# Универсальные guard-модули (lock + inhibit + recursion check)
# Ключевые обязанности:
# проверка: уже под inhibit или нет;
# защита от самоперезапуска;
# единая точка входа для systemd-inhibit
# -------------------------------------------------------------
# Использование guards-inhibit.sh
:<<'DOC'
source "$LIB_DIR/guards-inhibit.sh"

inhibit_run "$0" "$@"
DOC
# =============================================================

set -o errexit
set -o pipefail

# Защита от повторного source (НО без return!)
if [[ -n "${_REBK_GUARDS_LOADED:-}" ]]; then
    :
else
    _REBK_GUARDS_LOADED=1
fi


# -------------------------------------------------------------
# API: inhibit_run
# -------------------------------------------------------------
inhibit_run() {
    local cmd=("$@")

    # Уже под inhibit — ничего не делаем
    if [[ -n "${REBK_INHIBITED:-}" ]]; then
        return 0
    fi

    export REBK_INHIBITED=1

    if ! command -v systemd-inhibit >/dev/null 2>&1; then
        warn "systemd-inhibit not found, skipping inhibit"
        return 0
    fi

    systemd-inhibit \
        --who="REBK" \
        --why="Backup in progress" \
        --what=shutdown:sleep \
        "${cmd[@]}" 2>/dev/null || {
        warn "Failed to inhibit, continuing anyway"
    }
}

: # inhibit_run intentionally NOT readonly (re-exec safe)