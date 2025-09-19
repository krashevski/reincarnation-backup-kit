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
safe-restore-userdata.sh v1.4 — безопасное восстановление Backup Kit
Part of Backup Kit — minimal restore script with logging
-------------------------------------------------------------
Особенности:
- Определяет путь к backup-restore-userdata.sh автоматически
- Проверяет каталог резервных копий
- Работает без дублирования выбора пользователей
- Гарантированно запускает восстановление в щадящем режиме (без --delete)
- Двуязычная поддержка (RU/EN)
=============================================================
DOC

set -euo pipefail

# === Цвета ===
RED="\033[0;31m"
GREEN="\033[0;32m"
BLUE="\033[0;34m"
NC="\033[0m"

# === Двуязычные сообщения ===
declare -A MSG=(
  [ru_start]="Запуск безопасного восстановления Backup Kit..."
  [en_start]="Starting safe Backup Kit restore..."

  [ru_error_no_script]="Не найден restore-скрипт: "
  [en_error_no_script]="Restore script not found: "

  [ru_error_no_backup]="Ошибка: каталоги резервных копий не найдены."
  [en_error_no_backup]="Error: backup directories not found."

  [ru_info_expected]="Ожидаются каталоги:"
  [en_info_expected]="Expected backup directories:"

  [ru_ok_finished]="Все операции восстановления завершены успешно."
  [en_ok_finished]="All restore operations completed successfully."

  [ru_error_finished]="Восстановление завершилось с ошибками."
  [en_error_finished]="Restore finished with errors."

  [ru_info_safe]="Запускается безопасное восстановление (без удаления лишних файлов)..."
  [en_info_safe]="Starting safe restore (without deleting extra files)..."
)

# === Выбор языка ===
L=${LANG_CHOICE:-ru}

say() {
    local key="$1"
    echo -e "${MSG[${L}_$key]}${2:-}"
}

info()  { echo -e "${BLUE}[INFO]${NC} $(say "$1" "$2")"; }
ok()    { echo -e "${GREEN}[OK]${NC} $(say "$1" "$2")"; }
error() { echo -e "${RED}[ERROR]${NC} $(say "$1" "$2")"; }

# === Определяем пути ===
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
RESTORE_SCRIPT="$SCRIPT_DIR/backup-restore-userdata.sh"

BACKUP_DIR="/mnt/backups"
BR_USERDATA="$BACKUP_DIR/br_workdir/user_data"
BR_ARCHIVE="$BACKUP_DIR/br_workdir/tar_archive"

# --- Проверка существования скрипта ---
if [[ ! -x "$RESTORE_SCRIPT" ]]; then
    error error_no_script "$RESTORE_SCRIPT"
    exit 1
fi

# --- Проверка каталогов резервных копий ---
if [[ ! -d "$BR_USERDATA" && ! -d "$BR_ARCHIVE" ]]; then
    error error_no_backup
    info ru_info_expected
    echo "  $BR_USERDATA"
    echo "  $BR_ARCHIVE"
    exit 1
fi

# --- Запуск восстановления ---
info ru_info_safe
if SAFE=1 sudo -E bash "$RESTORE_SCRIPT" restore "$@"; then
    ok ok_finished
else
    error error_finished
    exit 1
fi

exit 0

