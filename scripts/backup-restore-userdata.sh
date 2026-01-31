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
backup-restore-userdata.sh v1.6 (bilingual RU/EN)
Hybrid backup: rsync (mirror) + tar (changed files)
Part of Backup Kit — minimal restore script with logging
-------------------------------------------------------------
Features:
- Detects all users in /home
- Allows selecting users for backup/restore
- Rsync for fast mirror backups
- Tar for archiving changed files (long-term storage)
- pv shows progress of tar archiving
- Progress via rsync --info=progress2
- Logging with tee (stdout+stderr)
- Optional X-session warning
- Restore skips junk files and keeps newer files
- Handles spaces/Unicode in paths
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


# --- Args parsing ---
OPERATION=""
FRESH_MODE=false

for arg in "$@"; do
    case "$arg" in
        backup|restore) OPERATION="$arg" ;;
        --fresh) FRESH_MODE=true ;;
        *) warn unknown_arg "$arg" ;;
    esac
done

if [[ -z "$OPERATION" ]]; then
    warn usage "$0"
    info example_backup "$0"
    info example_restore "$0"
    exit 1
fi

# --- systemd-inhibit only for restore ---
if [[ "$OPERATION" == "restore" ]] && command -v systemd-inhibit >/dev/null 2>&1; then
    if [[ -z "${INHIBIT_LOCK:-}" ]]; then
        export INHIBIT_LOCK=1
        exec systemd-inhibit \
            --what=handle-lid-switch:sleep:idle \
            --why="Reincarnation Backup Kit: restore in progress" \
            "$0" "$@"
    fi
fi

warn warn_time

# === Paths ===
CURRENT_USER="${SUDO_USER:-$USER}"
BACKUP_DIR="${BACKUP_DIR:-/mnt/backups}"
BR_WORKDIR="$BACKUP_DIR/br_workdir"
USERDATA_DIR="$BR_WORKDIR/user_data"
ARCHIVE_DIR="$BR_WORKDIR/tar_archive"
LOG_DIR="$BACKUP_DIR/logs"
mkdir -p "$BACKUP_DIR" "$BR_WORKDIR" "$USERDATA_DIR" "$ARCHIVE_DIR" "$LOG_DIR"
RUN_LOG="$LOG_DIR/br-$(date +%F-%H%M%S).log"

exec > >(tee -a "$RUN_LOG") 2>&1

# === Excludes ===
EXCLUDES=(
    ".cache" "Downloads" "Trash" ".thumbnails"
    ".mozilla/firefox/*/cache2"
    ".config/google-chrome/Default/Cache"
    ".var/app/*/cache" "Thumbs.db" ".DS_Store" ".gvfs/"
    ".local/share/baloo" ".local/share/tracker"
    ".thunderbird/*/Cache" ".thunderbird/*/OfflineCache"
    "lost+found"
)

RSYNC_EXCLUDES=()
for e in "${EXCLUDES[@]}"; do
    RSYNC_EXCLUDES+=(--exclude="$e")
done

# === Functions ===
run_rsync_backup() {
    local SRC="$1"
    local DST="$USERDATA_DIR/$2"
    mkdir -p "$DST"
    info rs_backup "$SRC" "$DST"
    rsync -aHAX --numeric-ids --info=progress2 --ignore-errors --update "${RSYNC_EXCLUDES[@]}" \
        "$SRC/" "$DST/"
}

fresh_backup_dir() {
    local user_backup_dir="$1"
    if [ -d "$user_backup_dir" ]; then
        warn fresh_remove "$user_backup_dir"
        rm -rf "$user_backup_dir"
    fi
    mkdir -p "$user_backup_dir"
}

run_tar_backup() {
    local SRC="$1"
    local NAME="$2"
    local ARCHIVE="$ARCHIVE_DIR/${NAME}_$(date +%F-%H%M%S).tar.gz"

    info "Archiving changed files from $SRC -> $ARCHIVE"
    LAST_BACKUP_TIME=$(stat -c %Y "$USERDATA_DIR/$NAME" 2>/dev/null || echo 0)

    mapfile -t changed_files < <(find "$SRC" -type f -newermt "@$LAST_BACKUP_TIME")
    if [ ${#changed_files[@]} -eq 0 ]; then
        warn no_new_files "$SRC"
        return 0
    fi

    printf '%s\n' "${changed_files[@]}" | tar --null -T - -czf - 2>/dev/null | \
        pv -s $(du -sb "$SRC" | awk '{print $1}') > "$ARCHIVE"

    ok archive_created "$ARCHIVE"
}

run_backup() {
    local NAME="$1"
    local SRC="/home/$NAME"
    if [ ! -d "$SRC" ]; then
        warn dir_missing "$SRC"
        return 0
    fi
    
    local DST="$USERDATA_DIR/$NAME"
    if $FRESH_MODE; then
        fresh_backup_dir "$DST"
    fi

    run_rsync_backup "$SRC" "$NAME"
    run_tar_backup "$SRC" "$NAME"
    ok backup_done_user "$NAME"
}

run_restore() {
    local NAME="$1"
    local DST="/home/$NAME"
    local LARGE_DIRS=("Videos" "Pictures" "Music" "Видео" "Изображения" "Музыка")

    if ! id "$NAME" &>/dev/null; then
        warn "$(echo_msg user_not_found "$NAME")"
        return 1
    fi

    [ -d "$DST" ] || mkdir -p "$DST"
    HDD_MOUNT="/mnt/storage"
    mkdir -p "$HDD_MOUNT"

    SRC="$USERDATA_DIR/$NAME"
    if [ -d "$SRC" ]; then
        info "$(echo_msg rs_restore "$SRC" "$DST")"
        while IFS= read -r -d '' item; do
            BASENAME=$(basename "$item")        
            if [ -d "$item" ]; then
                DST_DIR="$DST/$BASENAME"
                [[ " ${LARGE_DIRS[*]} " == *" $BASENAME "* ]] && DST_DIR="$HDD_MOUNT/$BASENAME"
                rsync -aHAX --numeric-ids --info=progress2 --ignore-errors --update --ignore-existing \
                    "${RSYNC_EXCLUDES[@]}" \
                    "$item/" "$DST_DIR/"
            elif [ -f "$item" ]; then
                rsync -aHAX --numeric-ids --info=progress2 --ignore-errors --update --ignore-existing \
                    "${RSYNC_EXCLUDES[@]}" \
                    "$item" "$DST/"
            fi
        done < <(find "$SRC" -mindepth 1 -maxdepth 1 -print0)
    else
        warn no_backup_found "$NAME"
    fi
    
    # Last archive
    tarf=$(ls -t "$ARCHIVE_DIR/${NAME}"*.tar.gz 2>/dev/null | head -n1)
    if [[ -n "$tarf" ]]; then
        info extracting_archive "$tarf"
        pv "$tarf" | tar -xzv --keep-newer-files -C "$DST"
    fi

    ok restore_done_user "$NAME"
}

# === Parse flags ===
FRESH_MODE=false
for arg in "$@"; do
  case $arg in
    --fresh)
      FRESH_MODE=true
      ;;
  esac
done

# === Checks ===
if ! mountpoint -q /mnt/backups; then
    error not_mounted
    exit 1
fi

if ! mountpoint -q /mnt/storage; then
    error not_mounted_storage
    exit 1
fi

users=()
for d in /home/*; do
    [ -d "$d" ] && users+=("$(basename "$d")")
done
if [ ${#users[@]} -eq 0 ]; then
    error no_users
    exit 1
fi

echo "$(echo_msg user_list)"
for i in "${!users[@]}"; do
    printf "  %d) %s\n" "$((i+1))" "${users[$i]}"
done
printf "$(echo_msg select_user "$OPERATION")"
read -r -a selections

status=0
for sel in "${selections[@]}"; do
    index=$((sel-1))
    if [[ $index -ge 0 && $index -lt ${#users[@]} ]]; then
        [[ "$OPERATION" == "backup" ]] && run_backup "${users[$index]}" || run_restore "${users[$index]}"
    else
        warn invalid_choice "$sel"
        status=1
    fi
done

if [ $status -eq 0 ]; then
    ok done_all "$OPERATION"
else
    error some_failed "$OPERATION" "$RUN_LOG"
fi

exit $status
