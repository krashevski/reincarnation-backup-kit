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
restore-sytem.sh v1.0 — Universal Restore Dispatcher (Ubuntu/Debian)
Part of Backup Kit — minimal restore script with logging
Author: Vladislav Krashevsky with support from ChatGPT
=============================================================
DOC

set -euo pipefail

# --- systemd-inhibit ---
if [[ -z "${INHIBIT_LOCK:-}" ]]; then
    export INHIBIT_LOCK=1
    exec systemd-inhibit --what=handle-lid-switch:sleep:idle --why="Running restore" "$0" "$@"
fi

# === Цвета ===
RED="\033[0;31m"; GREEN="\033[0;32m"; BLUE="\033[0;34m"; NC="\033[0m"
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

# === Выбор языка ===
L=${LANG_CHOICE:-ru}
say() { 
    local key="${L}_$1"
    shift
    printf "${MSG[$key]}" "$@"
}

# === Двуязычные сообщения ===
declare -A MSG=( 
  [ru_help]="Если АРХИВ не указан, будут использоваться значения по умолчанию в зависимости от системы."
  [en_help]="If ARCHIVE not specified, defaults will be used depending on system."
  
  [ru_detect_system]="Определение системы: "
  [en_detect_system]="Detected system: "

  [ru_not_found_dir]="❌ Каталог BACKUP_DIR не найден. Подключите или смонтируйте диск!"
  [en_not_found_dir]="❌ Directory BACKUP_DIR not found. Please mount the backup disk!"

  [ru_not_supported]="❌ Система %s %s пока не поддерживается"
  [en_not_supported]="❌ System %s %s is not supported yet"

  [ru_not_found_script]="❌ Скрипт %s не найден или не исполняемый!"
  [en_not_found_script]="❌ Script %s not found or not executable!"

  [ru_not_found_archive]="❌ Архив %s не найден!"
  [en_not_found_archive]="❌ Archive %s not found!"

  [ru_running]="Запуск: "
  [en_running]="Running: "

  [ru_link_created]="Символическая ссылка создана: ~/Backups"
  [en_link_created]="Symlink created: ~/Backups"

  [ru_dispatcher_finished]="Dispatcher finished."
  [en_dispatcher_finished]="Dispatcher finished."
  
  [ru_create_simlink]="Создание символической ссылки"
  [en_create_simlink]="Creating a symbolic link"

  [ru_restore_finished]="Восстановление завершено"
  [en_restore_finished]="Restore finished"

  [ru_log_file]="Файл лога: "
  [en_log_file]="Log file: "
  
  [ru_not_system]="Не удаётся обнаружить систему (нет /etc/os-release)"
  [en_not_system]="Cannot detect system (no /etc/os-release)"
  
  [ru_dispatcher_started]="Диспетчер запущен"
  [en_dispatcher_started]="Dispatcher started"
  
  [ru_dispatcher_finished]="Диспетчер успешно завершил работу"
  [en_dispatcher_finished]="Dispatcher finished successfully"
)

if [[ "${1:-}" == "--help" ]]; then
    echo "Usage: $0 [ARCHIVE]"
    echo "$(say help)"
    echo
    exit 0
fi

# --- Настройки ---
BACKUP_DIR="/mnt/backups"
LOG_DIR="$BACKUP_DIR/logs"
RUN_LOG="$LOG_DIR/restore-dispatch-$(date +%F-%H%M%S).log"

cleanup() {
   info "$(say dispatcher_finished)"
}
trap cleanup EXIT INT TERM

# --- Проверки ---
if [ ! -d "$BACKUP_DIR" ]; then
    error "$(say not_found_dir)"
    exit 1
fi

# --- Определяем систему ---
if [ -r /etc/os-release ]; then
    source /etc/os-release
    DISTRO="$ID"
    VERSION="$VERSION_ID"
else
    error "$(say not_system)"
    exit 1
fi

info "$(say detect_system)" "$DISTRO" "$VERSION"

# --- Определяем скрипт и архив ---
SCRIPT=""
ARCHIVE="${1:-}"

REAL_HOME="${HOME:-/home/$USER}"
if [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != "root" ]]; then
    REAL_HOME="/home/$SUDO_USER"
fi

case "$DISTRO-$VERSION" in
    ubuntu-24.04)
        SCRIPT="$REAL_HOME/bin/restore-ubuntu-24.04.sh"
        ARCHIVE="${ARCHIVE:-$BACKUP_DIR/backup-ubuntu-24.04.tar.gz}"
        ;;
    ubuntu-22.04)
        SCRIPT="$REAL_HOME/bin/restore-ubuntu-22.04.sh"
        ARCHIVE="${ARCHIVE:-$BACKUP_DIR/backup-ubuntu-22.04.tar.gz}"
        ;;
    debian-12)
        SCRIPT="$REAL_HOME/bin/restore-debian-12.sh"
        ARCHIVE="${ARCHIVE:-$BACKUP_DIR/backup-debian-12.tar.gz}"
        ;;
    *)
        error "$(say not_supported $DISTRO $VERSION)"
        exit 1
        ;;
esac

# --- Проверки наличия ---
if [ ! -x "$SCRIPT" ]; then
    error printf "$(say not_found_script "$SCRIPT")"
    exit 1
fi

if [ ! -f "$ARCHIVE" ]; then
    error printf "$(say not_found_archive "$ARCHIVE")"
    exit 1
fi

# --- Запуск ---
info "============================================================="
info "$(say running)" "$SCRIPT" "$ARCHIVE"
info "============================================================="

{
    echo "[$(date +%F_%T)] $(say dispatcher_started)"
    "$SCRIPT" "$ARCHIVE"
    echo "[$(date +%F_%T)] $(say dispatcher_finished)"
} 2>&1 | tee -a "$RUN_LOG"

info "$(say create_simlink)"
ln -sfn "$BACKUP_DIR" "$REAL_HOME/backups"
ok "$(say link_created)"

info "============================================================="
ok "$(say restore_finished)"
info "$(say log_file)" $RUN_LOG
info "============================================================="

exit 0
