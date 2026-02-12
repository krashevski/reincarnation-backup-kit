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
#
inhibit_run "$0" "$@"
DOC

set -o errexit
set -o pipefail

# Защита от повторного подключения
if [[ -n "${_REBK_GUARDS_LOADED:-}" ]]; then
    return 0 2>/dev/null || exit 0
fi
_REBK_GUARDS_LOADED=1

# Проверка, уже есть inhibit
[[ -n "${REBK_INHIBITED:-}" ]] && return 0 2>/dev/null || true
export REBK_INHIBITED=1

# -------------------------------------------------------------
# Надёжная функция inhibit_run
# -------------------------------------------------------------
inhibit_run() {
    local cmd=("$@")

    # Проверка, что systemd-inhibit доступен
    if ! command -v systemd-inhibit >/dev/null 2>&1; then
        warn "systemd-inhibit not found, skipping inhibit"
        return 0
    fi

    # Проверка, не запущен ли уже REBK inhibit
    if systemd-inhibit --list 2>/dev/null | grep -q "REBK"; then
        info "Inhibit already active, skipping"
        return 0
    fi

    # Попытка запуска inhibit, игнорируя ошибки No buffer space available
    systemd-inhibit \
        --who="REBK" \
        --why="Backup in progress" \
        --what=shutdown:sleep \
        "${cmd[@]}" 2>/dev/null || {
        warn "Failed to inhibit (systemd buffer full or other error), continuing anyway"
    }
}

# Экспорт say из logging.sh
readonly -f say ok info warn error die
