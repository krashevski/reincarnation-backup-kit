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

# --- Colors ---
RED="\033[0;31m"; GREEN="\033[0;32m"; YELLOW="\033[1;33m"; BLUE="\033[0;34m"; NC="\033[0m"

ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

# --- Language detection ---
LANG_CODE="en"
[[ "${LANG:-}" == ru* ]] && LANG_CODE="ru"

declare -A MSG_RU MSG_EN
MSG_RU=(
  [run_root]="Скрипт должен запускаться с правами root (sudo)"
  [usage]="Использование: %s ЧЧ:ММ [имя пользователя]"
  [invalid_format]="Неверный формат времени. HH:MM (например 10:30)"
  [script_error]="Скрипт cron-backup-userdata.sh не найден или не имеет права на выполнение."
  [cron_task]="Cron-задача для %s обновлена/добавлена успешно."
  [current_jobs]="Текущие cron-задания:"
  [run_test]="Выполняем тестовый бэкап прямо сейчас..."
  [test_done]="Тестовый бэкап завершён. Лог:"
)
MSG_EN=(
  [run_root]="The script must be run with root privileges (sudo)"
  [usage]="Usage: %s HH:MM [username]"
  [invalid_format]="Invalid time format. HH:MM (e.g. 10:30)"
  [script_error]="Script cron-backup-userdata.sh not found or not executable."
  [cron_task]="Cron task for %s updated/added successfully."
  [current_jobs]="Current cron jobs:"
  [run_test]="Running a test backup right now..."
  [test_done]="Test backup complete. Log:"
)

msg() {
  local key="$1"; shift
  case "$LANG_CODE" in
    ru) printf "${MSG_RU[$key]}\n" "$@" ;;
    en) printf "${MSG_EN[$key]}\n" "$@" ;;
  esac
}

# --- Args ---
if [[ $# -lt 1 ]]; then
    msg usage "$0" >&2
    exit 1
fi

TIME="$1"
USER_NAME="${2:-${SUDO_USER:-$USER}}"
BACKUP_DIR="/mnt/backups"
mkdir -p "$BACKUP_DIR"

if ! [[ "$TIME" =~ ^([01]?[0-9]|2[0-3]):([0-5][0-9])$ ]]; then
    error "$(msg invalid_format)"
    exit 1
fi
HOUR="${TIME%:*}"
MINUTE="${TIME#*:}"

# --- Script path ---
SCRIPT_PATH="$(realpath "$(dirname "$0")/cron-backup-userdata.sh")"
if [[ ! -x "$SCRIPT_PATH" ]]; then
    error "$(msg script_error)"
    exit 1
fi

LOG_DIR="$BACKUP_DIR/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/backup-userdata_${USER_NAME}_$(date +%F).log"

CRON_LINE="$MINUTE $HOUR * * * ionice -c2 -n7 nice -n10 $SCRIPT_PATH $USER_NAME >> $LOG_FILE 2>&1"

CURRENT_CRON=$(crontab -l 2>/dev/null || true)
NEW_CRON=$(echo "$CURRENT_CRON" | grep -v "$SCRIPT_PATH" || true)
NEW_CRON="$NEW_CRON"$'\n'"$CRON_LINE"
NEW_CRON=$(echo "$NEW_CRON" | sed '/^$/d')
echo "$NEW_CRON" | crontab -

ok "$(msg cron_task "$USER_NAME")"
info "$(msg current_jobs)"
crontab -l

info "$(msg run_test)"
ionice -c2 -n7 nice -n10 $SCRIPT_PATH $USER_NAME >> "$LOG_FILE" 2>&1
ok "$(msg test_done)"
ls -l "$LOG_FILE"

