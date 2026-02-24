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
check-last-archive.sh — check user tar backups
Reincarnation Backup Kit — MIT License
Copyright (c) 2025 Vladislav Krashevsky with support from ChatGPT
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

# === Директории ===
BACKUP_DIR="${BACKUP_DIR:-/mnt/backups}"
ARCHIVE_DIR="$BACKUP_DIR/br_workdir/tar_archive"

usage() {
    say last_usage
    exit 1
}

# --- Аргументы ---
LIST_MODE=0
if [[ $# -eq 0 ]]; then usage; fi

if [[ "$1" == "--list" ]]; then
    LIST_MODE=1
    shift
fi

if [[ $# -ne 1 ]]; then usage; fi

USER="$1"

# --- Поиск файлов ---
shopt -s nullglob
files=( "$ARCHIVE_DIR/${USER}"_*.tar.gz )
shopt -u nullglob

if [[ ${#files[@]} -eq 0 ]]; then
    error last_no_archives "$USER"
    exit 1
fi

if [[ $LIST_MODE -eq 1 ]]; then
    info last_all_archives
    # Список архивов с датой и размером
    ls -t "${files[@]}" | while read -r f; do
        size=$(du -h "$f" | cut -f1)
        mtime=$(stat -c %y "$f" | cut -d. -f1)
        echo "  $mtime  $size  $f"
    done
else
    latest=$(ls -t "${files[@]}" | head -n1)
    size=$(du -h "$latest" | cut -f1)
    mtime=$(stat -c %y "$latest" | cut -d. -f1)

    ok last_archive "$USER"
    echo_msg last_file $latest
    echo_msg last_date $mtime
    echo_msg last_size $size
fi

exit 0

