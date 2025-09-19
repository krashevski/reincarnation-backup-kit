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
check-last-archive.sh v1.3 — Проверка tar-бэкапов пользователя / Check user tar backups
Part of Backup Kit — minimal restore utility
Author: Vladislav
=============================================================
DOC

set -euo pipefail

# === Двуязычные сообщения ===
declare -A MSG=(
  [ru_usage]="Использование: $0 [--list] <имя_пользователя>"
  [en_usage]="Usage: $0 [--list] <username>"

  [ru_no_archives]="❌ Нет архивов для пользователя: "
  [en_no_archives]="❌ No archives found for user: "

  [ru_all_archives]="📂 Все архивы для пользователя (новые сверху):"
  [en_all_archives]="📂 All archives for user (newest first):"

  [ru_last_archive]="✅ Последний архив для пользователя: "
  [en_last_archive]="✅ Latest archive for user: "

  [ru_file]="   Файл : "
  [en_file]="   File : "

  [ru_date]="   Дата : "
  [en_date]="   Date : "

  [ru_size]="   Размер: "
  [en_size]="   Size: "
)

# === Выбор языка ===
L=${LANG_CHOICE:-ru}
say() { echo -e "${MSG[${L}_$1]}${2:-}"; }

# --- Цвета ---
RED="\033[0;31m"; GREEN="\033[0;32m"; BLUE="\033[0;34m"; NC="\033[0m"
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

# === Директории ===
BACKUP_DIR="${BACKUP_DIR:-/mnt/backups}"
ARCHIVE_DIR="$BACKUP_DIR/br_workdir/tar_archive"

usage() {
    say usage
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
    error "$(say no_archives "$USER")"
    exit 1
fi

if [[ $LIST_MODE -eq 1 ]]; then
    info "$(say all_archives)"
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

    ok "$(say last_archive "$USER")"
    echo "$(say file)$latest"
    echo "$(say date)$mtime"
    echo "$(say size)$size"
fi

exit 0

