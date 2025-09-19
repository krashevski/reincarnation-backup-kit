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
restore-ubuntu-24.04.sh v1.15 — System Restore (Ubuntu 24.04)
Part of Backup Kit — minimal restore script with simple logging
   Author: Vladislav Krashevsky with support from ChatGPT
   License: MIT
-------------------------------------------------------------
Description:
   Restores system packages, APT sources, and keyrings
   from backup archive backup-ubuntu-24.04.tar.gz
Notes:
   - Designed and tested for Ubuntu 24.04 LTS.
   - Requires a backup archive created by backup-ubuntu-24.04.sh.
   - User home data must be restored separately with
     `backup-restore-userdata.sh`.
Environment variables:
   RESTORE_PACKAGES=manual|full|none (default: manual)
   RESTORE_LOGS=true|false (default: false)
=============================================================
DOC

set -euo pipefail

# --- Цвета ---
RED="\033[0;31m"; GREEN="\033[0;32m"; YELLOW="\033[1;33m"; BLUE="\033[0;34m"; NC="\033[0m"
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARNING]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

# --- Сообщения EN/RU ---
declare -A MSG
MSG[en_CLEAN_TMP]="Cleaning temporary restore files..."
MSG[ru_CLEAN_TMP]="Очистка временных файлов восстановления..."

MSG[en_CLEAN_OK]="Temporary files cleaned."
MSG[ru_CLEAN_OK]="Временные файлы удалены."

MSG[en_ARCHIVE_NOT_FOUND]="Backup archive not found:"
MSG[ru_ARCHIVE_NOT_FOUND]="Файл архива не найден:"

MSG[en_EXTRACTING]="Extracting archive..."
MSG[ru_EXTRACTING]="Распаковка архива..."

MSG[en_EXTRACT_OK]="Archive extracted successfully."
MSG[ru_EXTRACT_OK]="Архив успешно распакован."

MSG[en_EXTRACT_FAIL]="Failed to extract archive."
MSG[ru_EXTRACT_FAIL]="Ошибка при распаковке архива."

MSG[en_REPOS]="Restoring APT sources and keyrings..."
MSG[ru_REPOS]="Восстановление источников APT и ключей..."

MSG[en_REPOS_OK]="Repositories and keyrings restored."
MSG[ru_REPOS_OK]="Источники APT и ключи восстановлены."

MSG[en_REPOS_FAIL]="system_packages directory missing in archive."
MSG[ru_REPOS_FAIL]="Каталог system_packages отсутствует в архиве."

MSG[en_PACKAGES_MANUAL]="Restoring manually installed packages..."
MSG[ru_PACKAGES_MANUAL]="Восстановление вручную установленных пакетов..."

MSG[en_PACKAGES_MANUAL_OK]="Manual packages restored."
MSG[ru_PACKAGES_MANUAL_OK]="Ручные пакеты восстановлены."

MSG[en_PACKAGES_MANUAL_FAIL]="Failed to restore manual packages."
MSG[ru_PACKAGES_MANUAL_FAIL]="Ошибка восстановления ручных пакетов."

MSG[en_PACKAGES_FULL]="Restoring full package list..."
MSG[ru_PACKAGES_FULL]="Восстановление полного списка пакетов..."

MSG[en_PACKAGES_FULL_OK]="Full package list restored."
MSG[ru_PACKAGES_FULL_OK]="Полный список пакетов восстановлен."

MSG[en_PACKAGES_FULL_FAIL]="Failed to restore full package list."
MSG[ru_PACKAGES_FULL_FAIL]="Ошибка восстановления полного списка пакетов."

MSG[en_PACKAGES_SKIP]="Skipping package restore (RESTORE_PACKAGES=none)."
MSG[ru_PACKAGES_SKIP]="Пропуск восстановления пакетов (RESTORE_PACKAGES=none)."

MSG[en_INVALID_MODE]="Invalid RESTORE_PACKAGES mode:"
MSG[ru_INVALID_MODE]="Некорректный режим RESTORE_PACKAGES:"

MSG[en_LOGS]="Restoring logs..."
MSG[ru_LOGS]="Восстановление логов..."

MSG[en_LOGS_OK]="Logs restored."
MSG[ru_LOGS_OK]="Логи восстановлены."

MSG[en_LOGS_SKIP]="Skipping logs restore."
MSG[ru_LOGS_SKIP]="Пропуск восстановления логов."

MSG[en_START]="Backup Kit — Starting system restore (Ubuntu 24.04)"
MSG[ru_START]="Backup Kit — Запуск восстановления системы (Ubuntu 24.04)"

MSG[en_DONE]="Backup Kit — System restore completed successfully!"
MSG[ru_DONE]="Backup Kit — Восстановление системы успешно завершено!"

# --- Определение языка ---
get_lang() {
    if [[ "${LANG_CHOICE:-}" =~ ^(ru|en)$ ]]; then
        echo "$LANG_CHOICE"
    elif [[ "${LANG:-}" == ru* ]]; then
        echo "ru"
    else
        echo "en"
    fi
}
L=$(get_lang)

say() {
    local key="$1"
    echo "${MSG[${L}_$key]}"
}

# --- Защита от рекурсии при systemd-inhibit ---
if [[ -z "${INHIBIT_LOCK:-}" ]]; then
    export INHIBIT_LOCK=1
    exec systemd-inhibit --what=handle-lid-switch:sleep:idle --why="restore running" "$0" "$@"
fi

# === Настройки ===
# безопасное задание BACKUP_DIR с дефолтом
if [ -z "${BACKUP_DIR+x}" ]; then
    BACKUP_DIR="/mnt/backups"
fi
WORKDIR="$BACKUP_DIR/restore_workdir"
LOG_DIR="$BACKUP_DIR/logs"
BACKUP_NAME="$BACKUP_DIR/backup-ubuntu-24.04.tar.gz"

mkdir -p "$WORKDIR" "$LOG_DIR"
RUN_LOG="$LOG_DIR/restore-$(date +%F-%H%M%S).log"

# Очистка при выходе
cleanup() {
    info "$(say CLEAN_TMP)"
    rm -rf "$WORKDIR"
    ok "$(say CLEAN_OK)"
}
trap cleanup EXIT INT TERM

# Проверка архива
if [ ! -f "$BACKUP_NAME" ]; then
    error "$(say ARCHIVE_NOT_FOUND) $BACKUP_NAME"
    exit 1
fi

# === Функции ===
extract_archive() {
    info "$(say EXTRACTING)"
    if pv "$BACKUP_NAME" | tar -xzv --skip-old-files -C "$WORKDIR" >>"$RUN_LOG" 2>&1; then
        ok "$(say EXTRACT_OK)"
    else
        error "$(say EXTRACT_FAIL)"
        exit 1
    fi
}

restore_repos_and_keys() {
    info "$(say REPOS)"
    PKG_DIR="$WORKDIR/system_packages"

    if [ ! -d "$PKG_DIR" ]; then
        error "$(say REPOS_FAIL)"
        exit 1
    fi

    sudo cp -a "$PKG_DIR/sources.list" /etc/apt/sources.list
    sudo cp -a "$PKG_DIR/sources.list.d/"* /etc/apt/sources.list.d/ 2>/dev/null || true
    sudo mkdir -p /etc/apt/keyrings
    sudo cp -a "$PKG_DIR/keyrings/"* /etc/apt/keyrings/ 2>/dev/null || true

    sudo apt update >>"$RUN_LOG" 2>&1 || warn "apt update failed"
    ok "$(say REPOS_OK)"
}

restore_packages() {
    PKG_DIR="$WORKDIR/system_packages"
    mode="${RESTORE_PACKAGES:-manual}"

    case "$mode" in
        manual)
            info "$(say PACKAGES_MANUAL)"
            if xargs -a "$PKG_DIR/manual-packages.list" sudo apt install -y >>"$RUN_LOG" 2>&1; then
                ok "$(say PACKAGES_MANUAL_OK)"
            else
                error "$(say PACKAGES_MANUAL_FAIL)"
                exit 1
            fi
            ;;
        full)
            info "$(say PACKAGES_FULL)"
            if sudo dpkg --set-selections < "$PKG_DIR/installed-packages.list" && \
               sudo apt-get -y dselect-upgrade >>"$RUN_LOG" 2>&1; then
                ok "$(say PACKAGES_FULL_OK)"
            else
                error "$(say PACKAGES_FULL_FAIL)"
                exit 1
            fi
            ;;
        none)
            warn "$(say PACKAGES_SKIP)"
            ;;
        *)
            error "$(say INVALID_MODE) $mode"
            exit 1
            ;;
    esac
}

restore_logs() {
    if [ "${RESTORE_LOGS:-false}" = "true" ]; then
        info "$(say LOGS)"
        mkdir -p "$BACKUP_DIR/logs_restored"
        cp -a "$WORKDIR/system_packages/README" "$BACKUP_DIR/logs_restored/" || true
        ok "$(say LOGS_OK)"
    else
        info "$(say LOGS_SKIP)"
    fi
}

run_step() {
    local name="$1"
    local func="$2"
    info "$name..."
    if "$func" >>"$RUN_LOG" 2>&1; then
        ok "$name completed."
        echo "[$(date +%F_%T)] $name completed" >>"$RUN_LOG"
    else
        error "$name failed. Check $RUN_LOG"
        echo "[$(date +%F_%T)] $name failed" >>"$RUN_LOG"
        exit 1
    fi
}

# === Основной процесс ===
info "======================================================"
info "$(say START)"
info "======================================================"

echo "[$(date +%F_%T)] Restore started" >>"$RUN_LOG"

run_step "Extracting archive" extract_archive
run_step "Restoring repositories and keyrings" restore_repos_and_keys
run_step "Restoring packages" restore_packages
run_step "Restoring logs" restore_logs

info "======================================================"
ok "$(say DONE)"
info "Log file: $RUN_LOG"
info "======================================================"

echo "[$(date +%F_%T)] Restore finished successfully" >>"$RUN_LOG"

exit 0

