#!/usr/bin/env bash
# =============================================================
# /shared-lib/lib/real_user.sh — правило определения реального пользователя
# Все скрипты НЕ используют напрямую:
#   USER, LOGNAME, SUDO_USER
# Используется только resolve_real_user()
# -------------------------------------------------------------
# Использование real_user.sh
:<<'DOC'
source "$LIB_DIR/real_user.sh"

if ! REAL_USER="$(resolve_real_user)"; then
    die "Cannot determine real user"
fi
DOC
# =============================================================

resolve_real_user() {
    local real_user

    if [[ -n "${REAL_USER:-}" ]]; then
        real_user="$REAL_USER"
    elif [[ -n "${SUDO_USER:-}" ]]; then
        real_user="$SUDO_USER"
    elif [[ -n "${USER:-}" ]]; then
        real_user="$USER"
    else
        error invalid_user "cannot resolve real user"
        return 1
    fi

    # Защита: пользователь должен существовать в системе
    if ! getent passwd "$real_user" >/dev/null; then
        error invalid_user "$real_user does not exist"
        return 1
    fi

    printf '%s\n' "$real_user"
}

# Экспорт API
readonly -f resolve_real_user