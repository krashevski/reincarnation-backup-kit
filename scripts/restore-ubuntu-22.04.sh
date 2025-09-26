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
restore-ubuntu-22.04.sh v1.15 — восстановление из архива (Ubuntu 22.04)
Part of Backup Kit — minimal restore script with logging
Author: Vladislav Krashevsky with support from ChatGPT
License: MIT
-------------------------------------------------------------
Restores backup archive created by `backup-ubuntu-22.04.sh`.
Supports English and Russian messages.
Environment variables:
  RESTORE_PACKAGES=manual|full|none   (default: manual)
  RESTORE_LOGS=true|false             (default: false)
  LANG_CHOICE=en|ru                   (default: ru)
=============================================================
DOC

set -euo pipefail

# --- systemd-inhibit ---
if [[ -z "${INHIBIT_LOCK:-}" ]]; then
    export INHIBIT_LOCK=1
    exec systemd-inhibit --what=handle-lid-switch:sleep:idle --why="$(say start)" "$0" "$@"
fi

# --- Цвета ---
RED="\033[0;31m"; GREEN="\033[0;32m"; YELLOW="\033[1;33m"; BLUE="\033[0;34m"; NC="\033[0m"
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

# --- Язык сообщений ---
declare -A MSG=(
    [en_start]="Backup Kit — Starting system restore (Ubuntu 22.04)"
    [ru_start]="Backup Kit — Начало восстановления системы (Ubuntu 22.04)"

    [en_cleanup]="Cleaning temporary restore files..."
    [ru_cleanup]="Очистка временных файлов восстановления..."
    [en_cleanup_done]="Temporary files cleaned."
    [ru_cleanup_done]="Временные файлы очищены."

    [en_no_archive]="Backup archive not found!"
    [ru_no_archive]="Архив резервной копии не найден!"

    [en_extract]="Extracting archive"
    [ru_extract]="Распаковка архива"

    [en_extract_done]="Archive extracted"
    [ru_extract_done]="Архив распакован"

    [en_restore_repos]="Restoring APT sources and keyrings..."
    [ru_restore_repos]="Восстановление репозиториев APT и ключей..."
    [en_restore_repos_done]="Repositories and keyrings restored."
    [ru_restore_repos_done]="Репозитории и ключи восстановлены."

    [en_restore_packages_manual]="Restoring manually installed packages..."
    [ru_restore_packages_manual]="Восстановление вручную установленных пакетов..."
    [en_restore_packages_full]="Restoring full package list..."
    [ru_restore_packages_full]="Восстановление полного списка пакетов..."
    [en_restore_packages_skip]="Skipping package restore (RESTORE_PACKAGES=none)"
    [ru_restore_packages_skip]="Пропуск восстановления пакетов (RESTORE_PACKAGES=none)"
    [en_restore_packages_done]="Packages restored."
    [ru_restore_packages_done]="Пакеты восстановлены."

    [en_restore_logs]="Restoring logs..."
    [ru_restore_logs]="Восстановление логов..."
    
    [en_restore_logs_done]="Logs restored."
    [ru_restore_logs_done]="Логи восстановлены."
    
    [en_restore_logs_skip]="Skipping logs restore"
    [ru_restore_logs_skip]="Пропуск восстановления логов"

    [en_done]="Backup Kit — System restore completed successfully!"
    [ru_done]="Backup Kit — Восстановление системы завершено успешно!"
    
    [en_run_sudo]="The script must be run with root rights (sudo)"
    [ru_run_sudo]="Скрипт нужно запускать с правами root (sudo)"
)

# --- Выбор языка ---
L=${LANG_CHOICE:-ru}

say() { echo "${MSG[${L}_$1]}"; }

# --- Проверка root только для команд, где нужны права ---
require_root() {
    if [[ $EUID -ne 0 ]]; then
        error "$(say run_sudo)"
        return 1
    fi
}

# --- Настройки ---
BACKUP_DIR="/mnt/backups"
WORKDIR="$BACKUP_DIR/restore_workdir"
LOG_DIR="$BACKUP_DIR/logs"
BACKUP_NAME="$BACKUP_DIR/backup-ubuntu-22.04.tar.gz"
mkdir -p "$WORKDIR" "$LOG_DIR"
RUN_LOG="$LOG_DIR/restore-$(date +%F-%H%M%S).log"

# Очистка при выходе
cleanup() {
    info "$(say cleanup)"
    rm -rf "$WORKDIR"
    ok "$(say cleanup_done)"
}
trap cleanup EXIT INT TERM

# Проверка архива
if [ ! -f "$BACKUP_NAME" ]; then
    error "$(say no_archive)"
    exit 1
fi

# === Функции ===
extract_archive() {
    info "$(say extract)..."
    if pv "$BACKUP_NAME" | tar -xzv ---skip-old-files -C "$WORKDIR" >>"$RUN_LOG" 2>&1; then
        ok "$(say extract_done)"
    else
        error "Failed to extract archive"
        exit 1
    fi
}

restore_repos_and_keys() {
    info "$(say restore_repos)"
    PKG_DIR="$WORKDIR/system_packages"
    if [ ! -d "$PKG_DIR" ]; then
        error "system_packages directory missing in archive"
        exit 1
    fi

    sudo cp -a "$PKG_DIR/sources.list" /etc/apt/sources.list
    sudo cp -a "$PKG_DIR/sources.list.d/"* /etc/apt/sources.list.d/ 2>/dev/null || true
    sudo mkdir -p /etc/apt/trusted.gpg.d
    sudo cp -a "$PKG_DIR/keyrings/"* /etc/apt/trusted.gpg.d/ 2>/dev/null || true
    sudo apt update >>"$RUN_LOG" 2>&1 || warn "apt update failed"
    ok "$(say restore_repos_done)"
}

restore_packages() {
    PKG_DIR="$WORKDIR/system_packages"
    mode="${RESTORE_PACKAGES:-manual}"

    case "$mode" in
        manual)
            info "$(say restore_packages_manual)"
            if xargs -a "$PKG_DIR/manual-packages.list" sudo apt-get install -y >>"$RUN_LOG" 2>&1; then
                ok "$(say restore_packages_done)"
            else
                error "Failed to restore manual packages"
                exit 1
            fi
            ;;
        full)
            info "$(say restore_packages_full)"
            if sudo dpkg --set-selections < "$PKG_DIR/installed-packages.list" && \
               sudo apt-get -y dselect-upgrade >>"$RUN_LOG" 2>&1; then
                ok "$(say restore_packages_done)"
            else
                error "Failed to restore full package list"
                exit 1
            fi
            ;;
        none)
            warn "$(say restore_packages_skip)"
            ;;
        *)
            error "Invalid RESTORE_PACKAGES mode: $mode"
            exit 1
            ;;
    esac
}

restore_logs() {
    if [ "${RESTORE_LOGS:-false}" = "true" ]; then
        info "$(say restore_logs)"
        mkdir -p "$BACKUP_DIR/logs_restored"
        cp -a "$WORKDIR/system_packages/README" "$BACKUP_DIR/logs_restored/" || true
        ok "$(say restore_logs_done)"
    else
        info "$(say restore_logs_skip)"
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
info "$(say start)"
info "======================================================"

echo "[$(date +%F_%T)] Restore started" >>"$RUN_LOG"

run_step "Extracting archive" extract_archive
run_step "Restoring repositories and keyrings" restore_repos_and_keys
run_step "Restoring packages" restore_packages
run_step "Restoring logs" restore_logs

info "======================================================"
ok "$(say done)"
info "Log file: $RUN_LOG"
info "======================================================"

echo "[$(date +%F_%T)] Restore finished successfully" >>"$RUN_LOG"

exit 0

