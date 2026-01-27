#!/bin/bash
# =============================================================
# Reincarnation Backup Kit — MIT License
# Copyright (c) 2025 Vladislav Krashevsky
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, subject to the following:
# The above copyright notice and this permission notice shall
# be included in all copies or substantial portions of the Software.
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND.
# =============================================================
# Wrapper: backup-system.sh
# Обёртка для системного бэкапа (Ubuntu 24.04)
# Автоматически вызывает подходящий скрипт backup-<distro>-<version>.sh
# Reincarnation Backup Kit — MIT License
# Copyright (c) 2025 Vladislav Krashevsky with support from ChatGPT
# =============================================================

set -euo pipefail

# -------------------------------------------------------------
# Colors (safe for set -u)
# -------------------------------------------------------------
if [[ "${FORCE_COLOR:-0}" == "1" || -t 1 ]]; then
    RED="\033[0;31m"
    GREEN="\033[0;32m"
    YELLOW="\033[1;33m"
    BLUE="\033[0;34m"
    NC="\033[0m"
else
    RED=""; GREEN=""; YELLOW=""; BLUE=""; NC=""
fi


# -------------------------------------------------------------
# 1. Определяем директорию скрипта
# -------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -------------------------------------------------------------
# 2. Объявляем ассоциативный массив MSG (будет расширяться при source)
# -------------------------------------------------------------
declare -A MSG

# -------------------------------------------------------------
# 3. Функция загрузки сообщений
# -------------------------------------------------------------
load_messages() {
    local lang="$1"
    # очищаем предыдущие ключи
    MSG=()

    case "$lang" in
        ru)
            source "$SCRIPT_DIR/i18n/messages_ru.sh"
            ;;
        en)
            source "$SCRIPT_DIR/i18n/messages_en.sh"
            ;;
        *)
            echo "Unknown language: $lang" >&2
            return 1
            ;;
    esac
}

# -------------------------------------------------------------
# 4. Безопасный say
# -------------------------------------------------------------
say() {
    local key="$1"; shift
    local msg="${MSG[${key}]:-$key}"

    if [[ $# -gt 0 ]]; then
        printf "$msg\n" "$@"
    else
        printf '%s\n' "$msg"
    fi
}


# -------------------------------------------------------------
# 5. Фуекцмя ok
# -------------------------------------------------------------
ok() {
    local key="$1"; shift
    local fmt
    fmt="$(say "$key")"
    printf "%b[OK]%b %b\n" \
        "${GREEN:-}" \
        "${NC:-}" \
        "$(printf "$fmt" "$@")"
}


# -------------------------------------------------------------
# 6. Функция info для логирования
# -------------------------------------------------------------
info() {
    local key="$1"; shift
    local fmt
    fmt="$(say "$key")"
    printf "%b[INFO]%b %b\n" \
        "${BLUE:-}" \
        "${NC:-}" \
        "$(printf "$fmt" "$@")" >&2
}


# -------------------------------------------------------------
# 7. Функция warn для логирования
# -------------------------------------------------------------
warn() {
    local key="$1"; shift
    local fmt
    fmt="$(say "$key")"
    printf "%b[WARN]%b %b\n" \
        "${YELLOW:-}" \
        "${NC:-}" \
        "$(printf "$fmt" "$@")" >&2
}

# -------------------------------------------------------------
# 8. Функция error для логирования
# -------------------------------------------------------------
error() {
    local key="$1"; shift
    local fmt
    fmt="$(say "$key")"
    printf "%b[ERROR]%b %b\n" \
        "${RED:-}" \
        "${NC:-}" \
        "$(printf "$fmt" "$@")" >&2
}


# -------------------------------------------------------------
# 9. Функция echo_echo_msg для логирования
# -------------------------------------------------------------
echo_msg() {
    local key="$1"; shift
    local fmt
    fmt="$(say "$key")"
    printf "%b\n" "$(printf "$fmt" "$@")"
}

# -------------------------------------------------------------
# 10. Функция die для логирования
# -------------------------------------------------------------
die() {
    error "$@"
    exit 1
}

# -------------------------------------------------------------
# 11. Устанавливаем язык по умолчанию и загружаем переводы
# -------------------------------------------------------------
LANG_CODE="${LANG_CODE:-ru}"
load_messages "$LANG_CODE"

# --- Проверка root только для команд, где нужны права ---
require_root() {
    if [[ $EUID -ne 0 ]]; then
        error run_sudo
        return 1
    fi
}

REAL_HOME="${HOME:-/home/$USER}"
if [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != "root" ]]; then
    REAL_HOME="/home/$SUDO_USER"
fi

# --- Inhibit recursion via systemd-inhibit ---
if [[ -t 1 ]] && command -v systemd-inhibit >/dev/null 2>&1; then
    if [[ -z "${INHIBIT_LOCK:-}" ]]; then
        export INHIBIT_LOCK=1
        exec systemd-inhibit \
            --what=handle-lid-switch:sleep:idle \
            --why="Backup in progress" \
            "$0" "$@"
    fi
fi

# --- Дистрибутив ---
DISTRO_ID=$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
DISTRO_VER=$(grep '^VERSION_ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')

info distro_found "$DISTRO_ID" "$DISTRO_VER"

SCRIPT_DIR="$(dirname "$0")"
TARGET="$SCRIPT_DIR/backup-${DISTRO_ID}-${DISTRO_VER}.sh"

if [[ ! -x "$TARGET" ]]; then
    error no_script "$DISTRO_ID"-"$DISTRO_VER"
    exit 1
fi

exec "$TARGET" "$@"

