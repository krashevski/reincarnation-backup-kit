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
# Wrapper: backup-system.sh — автоматический вызов backup-<distro>-<version>.sh
# =============================================================

set -euo pipefail

# -------------------------------------------------------------
# 1. Цвета
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
# 2. i18n
# -------------------------------------------------------------
declare -Ag MSG

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$LIB_DIR/.." && pwd)"

load_messages() {
    local lang="$1"
    MSG=()
    local i18n_dir="$LIB_DIR/i18n"
    case "$lang" in
        ru) source "$i18n_dir/messages_ru.sh" ;;
        en) source "$i18n_dir/messages_en.sh" ;;
        *)
            echo "Unknown language: $lang" >&2
            return 1
            ;;
    esac
}

LANG_CODE="${LANG_CODE:-ru}"
load_messages "$LANG_CODE"

say() {
    local key="$1"; shift
    local msg="${MSG[$key]:-$key}"
    [[ $# -gt 0 ]] && printf "$msg" "$@" || printf '%s' "$msg"
}

# -------------------------------------------------------------
# 3. Логирование
# -------------------------------------------------------------
: "${RUN_LOG:=/dev/null}"

ok() {
    printf "%b[OK]%b %b\n" \
        "$GREEN" "$NC" "$(say "$@")" |
    tee -a "$RUN_LOG"
}
info() {
    printf "%b[INFO]%b %b\n" \
        "$BLUE" "$NC" "$(say "$@")" |
    tee -a "$RUN_LOG"
    return 0
}
warn() {
    printf "%b[WARN]%b %b\n" \
        "$YELLOW" "$NC" "$(say "$@")" |
    tee -a "$RUN_LOG" >&2
    return 0
}
error() {
    printf "%b[ERROR]%b %b\n" \
        "$RED" "$NC" "$(say "$@")" |
    tee -a "$RUN_LOG" >&2
    return 1
}
die() {
    error "$@"
    exit "${2:-1}"
}

# -------------------------------------------------------------
# 5. Авто-поднятие до root через sudo (надёжно)
# -------------------------------------------------------------
if [[ $EUID -ne 0 ]]; then
    if command -v sudo >/dev/null 2>&1; then
        # Перезапуск скрипта через sudo
        exec sudo bash "$0" "$@"
    else
        error root_run
        exit 1
    fi
fi

# -------------------------------------------------------------
# 6. Определение домашнего каталога реального пользователя
# -------------------------------------------------------------
REAL_HOME="${HOME:-/home/$USER}"
if [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != "root" ]]; then
    REAL_HOME="/home/$SUDO_USER"
fi

# -------------------------------------------------------------
# 7. Функция require_root для дополнительных проверок
# -------------------------------------------------------------
require_root() {
    if [[ $EUID -ne 0 ]]; then
        error run_sudo
        return 1
    fi
}

# -------------------------------------------------------------
# 8. systemd-inhibit (после root!)
# -------------------------------------------------------------
if [[ -t 1 ]] && command -v systemd-inhibit >/dev/null 2>&1; then
    if [[ -z "${INHIBIT_LOCK:-}" ]]; then
        export INHIBIT_LOCK=1
        exec systemd-inhibit \
            --what=handle-lid-switch:sleep:idle \
            --why="Backup in progress" \
            "$0" "$@"
    fi
fi

# -------------------------------------------------------------
# 9. Определяем систему
# -------------------------------------------------------------
if [ -r /etc/os-release ]; then
    source /etc/os-release
    DISTRO="$ID"
    VERSION="$VERSION_ID"
else
    error not_system
    exit 1
fi

info detect_system "$DISTRO" "$VERSION"

# -------------------------------------------------------------
# 10. Определяем целевой скрипт
# -------------------------------------------------------------
TARGET="$LIB_DIR/backup-${DISTRO}-${VERSION}.sh"

if [[ ! -x "$TARGET" ]]; then
    error no_script "$DISTRO" "$VERSION" "$TARGET"
    exit 1
fi

# -------------------------------------------------------------
# 11. Запускаем целевой скрипт
# -------------------------------------------------------------
exec "$TARGET" "$@"

exit 0



