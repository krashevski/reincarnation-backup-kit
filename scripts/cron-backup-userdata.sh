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
cron-backup-userdata.sh — for cron
Reincarnation Backup Kit — MIT License
Copyright (c) 2025 Vladislav Krashevsky with support from ChatGPT
-------------------------------------------------------------
Uses rsync for fast mirror backup + tar for archiving changed files
Automatically checks disk space and calls clean-backup-logs.sh
=============================================================
DOC

set -euo pipefail

# Стандартная библиотека REBK
# --- Определяем BIN_DIR относительно скрипта ---
BIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Путь к библиотекам всегда относительно BIN_DIR
LIB_DIR="$BIN_DIR/lib"

# source "$(dirname "$0")/lib/init.sh"

source "$LIB_DIR/i18n.sh"
init_app_lang

source "$LIB_DIR/logging.sh"       # error / die
source "$LIB_DIR/user_home.sh"     # resolve_target_home
source "$LIB_DIR/real_user.sh"     # resolve_real_user
source "$LIB_DIR/privileges.sh"    # require_root
source "$LIB_DIR/context.sh"       # контекст выполнения
source "$LIB_DIR/guards-inhibit.sh"
source "$LIB_DIR/cleanup.sh"

if ! TARGET_HOME="$(resolve_target_home)"; then
    die "Cannot determine target home"
fi

if ! REAL_USER="$(resolve_real_user)"; then
    die "Cannot determine real user"
fi

require_root || return 1

# --- Paths ---
CURRENT_USER="${SUDO_USER:-$USER}"
BACKUP_DIR="/mnt/backups/REBK"
BR_WORKDIR="$BACKUP_DIR/bares_workdir"
USERDATA_DIR="$BR_WORKDIR/user_data"
ARCHIVE_DIR="$BR_WORKDIR/tar_archive"
LOG_DIR="$BACKUP_DIR/logs"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
mkdir -p "$BR_WORKDIR" "$USERDATA_DIR" "$ARCHIVE_DIR" "$LOG_DIR"

# --- Disk space check and log cleanup ---
FREE_PERC=$(df --output=pcent "$BACKUP_DIR" | tail -1 | tr -dc '0-9')
if (( FREE_PERC < 10 )); then
    warn cronud_free_space "$BACKUP_DIR" "$FREE_PERC"
    if [[ -x "$SCRIPT_DIR/clean-backup-logs.sh" ]]; then
        "$SCRIPT_DIR/clean-backup-logs.sh"
    else
        warn cronud_not_script "$SCRIPT_DIR"
    fi
    FREE_PERC=$(df --output=pcent "$BACKUP_DIR" | tail -1 | tr -dc '0-9')
    if (( FREE_PERC < 10 )); then
        error cronud_not_space
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
        warn cronud_dir_skip "$SRC"
        return
    fi

    mkdir -p "$DST"
    info cronud_backup "$SRC" "$DST"
    rsync -aHAX --numeric-ids --info=progress2 --ignore-errors --update $(rsync_exclude) \
        "$SRC/" "$DST/"
        
    info cronud_archiving_changed "$SRC" "$ARCHIVE"
    LAST_BACKUP_TIME=$(stat -c %Y "$USERDATA_DIR/$NAME" 2>/dev/null || echo 0) 
    
    # Собираем только изменённые файлы 
    mapfile -t changed_files < <(find "$SRC" -type f -newermt "@$LAST_BACKUP_TIME") 
    if [ ${#changed_files[@]} -eq 0 ]; then 
       warn cronud_no_files "$SRC" 
       return 0 
    fi 
    
    # Архивация с относительными путями 
    ( 
       cd "$SRC" 
       printf '%s\0' "${changed_files[@]#"$SRC"/}" | tar --null -T - -czf "$ARCHIVE" 
    ) 
    ok cronud_done "$SRC"
}    

# --- Run backup ---
run_backup "$TARGET_USER"

exit 0