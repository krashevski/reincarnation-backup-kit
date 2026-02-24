#!/usr/bin/env bash
# =============================================================
# /scripts/lib/user_home.sh — правило определения целевого домашнего каталога пользователя
# -------------------------------------------------------------
# Использование user_home.sh
:<<'DOC'
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"
#
source "$LIB_DIR/logging.sh"
source "$LIB_DIR/cleanup.sh"

if ! TARGET_HOME="$(resolve_target_home)"; then
    exit 1
fi
DOC
# =============================================================

# -------------------------------------------------------------
# Правило определения целевого домашнего каталога пользователя
# -------------------------------------------------------------

resolve_target_home() {
    local target_home

    if [[ -n "${USER_HOME:-}" ]]; then
        target_home="$USER_HOME"
    elif [[ -n "${SUDO_USER:-}" ]]; then
        target_home="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
    else
        target_home="$HOME"
    fi

    if [[ -z "$target_home" || "$target_home" == "/" ]]; then
        error invalid_home "$target_home"
        return 1
    fi

    printf '%s\n' "$target_home"
}

# -------------------------------------------------------------
# Экспорт say как readonly API
# -------------------------------------------------------------
readonly -f say ok info warn error die