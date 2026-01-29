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
cron-backup-userdata.sh v1.0 — Backup Kit for cron
Reincarnation Backup Kit — MIT License
Copyright (c) 2025 Vladislav Krashevsky with support from ChatGPT
-------------------------------------------------------------
Dual language (RU/EN) cron backup script for user data
Uses rsync for fast mirror backup + tar for archiving changed files
Automatically checks disk space and calls clean-backup-logs.sh
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

# --- Paths ---
CURRENT_USER="${SUDO_USER:-$USER}"
BACKUP_DIR="/mnt/backups"
BR_WORKDIR="$BACKUP_DIR/br_workdir"
USERDATA_DIR="$BR_WORKDIR/user_data"
ARCHIVE_DIR="$BR_WORKDIR/tar_archive"
LOG_DIR="$BACKUP_DIR/logs"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
mkdir -p "$BR_WORKDIR" "$USERDATA_DIR" "$ARCHIVE_DIR" "$LOG_DIR"

# --- Disk space check and log cleanup ---
FREE_PERC=$(df --output=pcent "$BACKUP_DIR" | tail -1 | tr -dc '0-9')
if (( FREE_PERC < 10 )); then
    warn low_free_space "$BACKUP_DIR" "$FREE_PERC"
    if [[ -x "$SCRIPT_DIR/clean-backup-logs.sh" ]]; then
        "$SCRIPT_DIR/clean-backup-logs.sh"
    else
        warn not_script_found "$SCRIPT_DIR"
    fi
    FREE_PERC=$(df --output=pcent "$BACKUP_DIR" | tail -1 | tr -dc '0-9')
    if (( FREE_PERC < 10 )); then
        error not_space_after
        exit 1
    fi
fi

# --- Target user ---
TARGET_USER="${1:-$CURRENT_USER}"

EXCLUDES=(
    ".cache" "Downloads" "Trash" ".thumbnails"
    ".mozilla/firefox/*/cache2"
    ".config/google-chrome/Default/Cache"
    ".var/app/*/cache" "Thumbs.db" ".DS_Store" ".gvfs/"
    ".local/share/baloo" ".local/share/tracker"
    ".thunderbird/*/Cache" ".thunderbird/*/OfflineCache"
)

rsync_exclude() {
    local args=()
    for e in "${EXCLUDES[@]}"; do
        args+=(--exclude="$e")
    done
    echo "${args[@]}"
}

run_backup() {
    local NAME="$1"
    local SRC="/home/$NAME"
    local DST="$USERDATA_DIR/$NAME"
    local ARCHIVE="$ARCHIVE_DIR/${NAME}_$(date +%F-%H%M%S).tar.gz"

    if [ ! -d "$SRC" ]; then
        warn dir_skip "$SRC"
        return
    fi

    mkdir -p "$DST"
    info rs_backup "$SRC" "$DST"
    rsync -aHAX --numeric-ids --info=progress2 --ignore-errors --update $(rsync_exclude) \
        "$SRC/" "$DST/"
        
    info archiving_changed "$SRC" "$ARCHIVE"
    LAST_BACKUP_TIME=$(stat -c %Y "$USERDATA_DIR/$NAME" 2>/dev/null || echo 0) 
    
    # Собираем только изменённые файлы 
    mapfile -t changed_files < <(find "$SRC" -type f -newermt "@$LAST_BACKUP_TIME") 
    if [ ${#changed_files[@]} -eq 0 ]; then 
       warn  "$SRC" 
       return 0 
    fi 
    
    # Архивация с относительными путями 
    ( 
       cd "$SRC" 
       printf '%s\0' "${changed_files[@]#"$SRC"/}" | tar --null -T - -czf "$ARCHIVE" 
    ) 
    ok backup_done "$SRC"
}    

# --- Run backup ---
run_backup "$TARGET_USER"

exit 0

