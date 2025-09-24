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

# --- Colors ---
RED="\033[0;31m"; GREEN="\033[0;32m"; YELLOW="\033[1;33m"; BLUE="\033[0;34m"; NC="\033[0m"
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

# === Сообщения ===
LANG_CODE="en"
[[ "${LANG:-}" == ru* ]] && LANG_CODE="ru"

declare -A MSG_RU MSG_EN
MSG_RU=(
   [low_free_space]="На %b мало места:"
   [not_script_found]="Скрипт очистки логов не найден:"
   [not_space_after]="Недостаточно места после очистки"
   [dir_skip]="Пользовательский каталог %s не найден, пропускается."
   [rs_backup]="Резервное копирование Rsync:"
   [archiving_changed]="Архивирование изменённых файлов из"
   [no_new_files]="Нет новых файлов для архивирования в"
   [backup_done]="Резервное копирование завершено для"
)
MSG_EN=(
   [low_free_space]="Low free space at %b:"
   [not_script_found]="Clean-backup-logs.sh not found:"
   [not_space_after]="Not enough space after cleaning"
   [dir_skip]="User directory %s not found, skipping."
   [rs_backup]="Rsync backup:"
   [archiving_changed]="Archiving changed files from"
   [no_new_files]="No new files to archive in"
   [backup_done]="Backup completed for"  
)

msg() {
  local key="$1"; shift
  case "$LANG_CODE" in
    ru) printf "${MSG_RU[$key]}\n" "$@" ;;
    en) printf "${MSG_EN[$key]}\n" "$@" ;;
  esac
}

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
    warn "$(msg low_free_space "$BACKUP_DIR" "$FREE_PERC%")"
    if [[ -x "$SCRIPT_DIR/clean-backup-logs.sh" ]]; then
        "$SCRIPT_DIR/clean-backup-logs.sh"
    else
        warn "$(msg not_script_found "$SCRIPT_DIR")"
    fi
    FREE_PERC=$(df --output=pcent "$BACKUP_DIR" | tail -1 | tr -dc '0-9')
    if (( FREE_PERC < 10 )); then
        error "$(msg not_space_after)"
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
        warn "$(msg dir_skip) $SRC"
        return
    fi

    mkdir -p "$DST"
    info "$(msg rs_backup) $SRC -> $DST"
    rsync -aHAX --numeric-ids --info=progress2 --ignore-errors --update $(rsync_exclude) \
        "$SRC/" "$DST/"
        
    info "$(msg archiving_changed) $SRC -> $ARCHIVE"
    LAST_BACKUP_TIME=$(stat -c %Y "$USERDATA_DIR/$NAME" 2>/dev/null || echo 0) 
    
    # Собираем только изменённые файлы 
    mapfile -t changed_files < <(find "$SRC" -type f -newermt "@$LAST_BACKUP_TIME") 
    if [ ${#changed_files[@]} -eq 0 ]; then 
       warn "$(msg no_new_files) $SRC" 
       return 0 
    fi 
    
    # Архивация с относительными путями 
    ( 
       cd "$SRC" 
       printf '%s\0' "${changed_files[@]#"$SRC"/}" | tar --null -T - -czf "$ARCHIVE" 
    ) 
    ok "$(msg backup_done) $SRC"
}    

# --- Run backup ---
run_backup "$TARGET_USER"

exit 0

