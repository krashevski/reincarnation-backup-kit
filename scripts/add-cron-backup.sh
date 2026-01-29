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
:<<'DOC'
=============================================================
add-cron-backup.sh — Add/update a cron job for cron-backup-userdata.sh
Reincarnation Backup Kit — MIT License
Copyright (c) 2025 Vladislav Krashevsky with support from ChatGPT
------------------------------------------------------------
Usage:
    sudo ./add-cron-backup.sh HH:MM [username]
Description:
    Creates a daily cron backup job
    for the given user and cron-backup-userdata.sh
=============================================================
DOC

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
# 5. Kjuuth ok
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

# --- Args ---
if [[ $# -lt 1 ]]; then
    echo_msg usage "$0" >&2
    exit 1
fi

TIME="$1"
USER_NAME="${2:-${SUDO_USER:-$USER}}"
BACKUP_DIR="/mnt/backups"
mkdir -p "$BACKUP_DIR"

if ! [[ "$TIME" =~ ^([01]?[0-9]|2[0-3]):([0-5][0-9])$ ]]; then
    error invalid_format
    exit 1
fi
HOUR="${TIME%:*}"
MINUTE="${TIME#*:}"

# --- Script path ---
SCRIPT_PATH="$(realpath "$(dirname "$0")/cron-backup-userdata.sh")"
if [[ ! -x "$SCRIPT_PATH" ]]; then
    error script_error
    exit 1
fi

LOG_DIR="$BACKUP_DIR/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/backup-userdata_${USER_NAME}_$(date +%F).log"

CRON_LINE="$MINUTE $HOUR * * * ionice -c2 -n7 nice -n10 "$SCRIPT_PATH" "$USER_NAME" >> "$LOG_FILE" 2>&1"

CURRENT_CRON=$(crontab -l 2>/dev/null || true)
NEW_CRON=$(echo "$CURRENT_CRON" | grep -v "$SCRIPT_PATH" || true)
NEW_CRON="$NEW_CRON"$'\n'"$CRON_LINE"
NEW_CRON=$(echo "$NEW_CRON" | sed '/^$/d')
echo "$NEW_CRON" | crontab -

ok cron_task "$USER_NAME"
info current_jobs
crontab -l

run_cron_test() {
   /usr/bin/ionice -c2 -n7 /usr/bin/nice -n10 "$SCRIPT_PATH" "$USER_NAME" >> "$LOG_FILE" 2>&1
}

info run_test

if run_cron_test; then
    ok test_done "$LOG_FILE"
else
    error test_failed "$LOG_FILE"
    return 1
fi

exit 0