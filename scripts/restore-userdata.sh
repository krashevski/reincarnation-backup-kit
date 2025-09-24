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
restore-userdata.sh v2.0 — Backup Kit Safe Restore
Reincarnation Backup Kit — MIT License
Copyright (c) 2025 Vladislav Krashevsky with support from ChatGPT
------------------------------------------------------------
Features:
- Correctly displays localized messages
- Guaranteed to initiate a safe restore (SAFE=1)
- Checks both backup directories separately
- Logging and progress are the same as backup-restore-userdata.sh
======================================================================
DOC

set -euo pipefail

# === Цвета ===
RED="\033[0;31m"
GREEN="\033[0;32m"
BLUE="\033[0;34m"
NC="\033[0m"

# === Сообщения ===
declare -A MSG
MSG[ru_start]="Запуск безопасного восстановления Backup Kit..."
MSG[en_start]="Starting safe Backup Kit restore..."

MSG[ru_error_no_script]="Не найден restore-скрипт: %s"
MSG[en_error_no_script]="Restore script not found: %s"

MSG[ru_error_no_backup]="Ошибка: каталог резервных копий не найден: %s"
MSG[en_error_no_backup]="Error: backup directory not found: %s"

MSG[ru_ok_finished]="Все операции восстановления завершены успешно."
MSG[en_ok_finished]="All restore operations completed successfully."

MSG[ru_error_finished]="Восстановление завершилось с ошибками."
MSG[en_error_finished]="Restore finished with errors."

MSG[ru_info_safe]="Запускается безопасное восстановление (без удаления лишних файлов)..."
MSG[en_info_safe]="Starting safe restore (without deleting extra files)..."

# === Определение языка ===
determine_language() {
    if [[ -n "${LANG_CHOICE:-}" ]]; then
        echo "$LANG_CHOICE"
        return
    fi
    if [[ -n "${SUDO_USER:-}" ]]; then
        local user_lang
        user_lang=$(sudo -u "$SUDO_USER" bash -c 'echo "${LANG:-}"')
        [[ "$user_lang" == ru* ]] && echo "ru" || echo "en"
        return
    fi
    [[ "${LANG:-}" == ru* ]] && echo "ru" || echo "en"
}

L=$(determine_language)

# === Функция say ===
say() {
    local key="$1"; shift || true
    local msg_key="${L}_$key"
    local text="${MSG[$msg_key]:-⚠ Unknown message key: $msg_key}"
    if (( $# )); then
        printf "$text\n" "$@"
    else
        printf "%s\n" "$text"
    fi
}

info()  { echo -e "${BLUE}[INFO]${NC} $(say "$1" "$@")"; }
ok()    { echo -e "${GREEN}[OK]${NC} $(say "$1" "$@")"; }
error() { echo -e "${RED}[ERROR]${NC} $(say "$1" "$@")"; }

# === Пути ===
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
RESTORE_SCRIPT="$SCRIPT_DIR/backup-restore-userdata.sh"

BACKUP_DIR="/mnt/backups"
BR_USERDATA="$BACKUP_DIR/br_workdir/user_data"
BR_ARCHIVE="$BACKUP_DIR/br_workdir/tar_archive"
LOG_DIR="$BACKUP_DIR/logs"
mkdir -p "$LOG_DIR"
RUN_LOG="$LOG_DIR/restore-$(date +%F-%H%M%S).log"

# === Проверка скрипта ===
if [[ ! -x "$RESTORE_SCRIPT" ]]; then
    error error_no_script "$RESTORE_SCRIPT"
    exit 1
fi

# === Проверка каталогов резервных копий ===
backup_ok=true
for dir in "$BR_USERDATA" "$BR_ARCHIVE"; do
    if [[ ! -d "$dir" ]]; then
        error error_no_backup "$dir"
        backup_ok=false
    fi
done
$backup_ok || exit 1

# === Запуск восстановления ===
info info_safe
# Перенаправляем вывод в лог с прогрессом
if SAFE=1 sudo -E bash "$RESTORE_SCRIPT" restore "$@" > >(tee -a "$RUN_LOG") 2>&1; then
    ok ok_finished
else
    error error_finished
    exit 1
fi

exit 0

