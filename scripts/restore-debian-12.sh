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
restore-debian-12.sh — восстановление системы (Debian 12)
Part of Backup Kit — minimal restore script with logging
Author: Vladislav Krashevsky with support from ChatGPT
License: MIT
-------------------------------------------------------------
Restores system state from backup archive:
  - System packages (manual/full/none)
  - APT sources and keys
  - Optional logs
Input archive: backup-debian-12.tar.gz
Supports English and Russian messages.
Environment variables:
  RESTORE_PACKAGES=manual|full|none   (default: manual)
  RESTORE_LOGS=true|false             (default: false)
  LANG_CHOICE=en|ru                   (default: ru)
=============================================================
DOC

set -euo pipefail

# --- Язык сообщений ---
declare -A MSG=(
    [en_start]="Backup Kit — Starting restore (Debian 12)"
    [ru_start]="Backup Kit — Начало восстановления (Debian 12)"

    [en_cleanup]="Cleaning temporary files..."
    [ru_cleanup]="Очистка временных файлов..."
    [en_cleanup_done]="Temporary files cleaned."
    [ru_cleanup_done]="Временные файлы очищены."

    [en_no_archive]="Backup archive not found!"
    [ru_no_archive]="Архив резервной копии не найден!"

    [en_extract]="Extracting archive"
    [ru_extract]="Распаковка архива"
    [en_extract_done]="Archive extracted."
    [ru_extract_done]="Архив распакован."

    [en_restore_packages_manual]="Restoring manual packages..."
    [ru_restore_packages_manual]="Восстановление вручную установленных пакетов..."
    [en_restore_packages_full]="Restoring full package list..."
    [ru_restore_packages_full]="Восстановление полного списка пакетов..."
    [en_restore_packages_skip]="Skipping package restore."
    [ru_restore_packages_skip]="Пропуск восстановления пакетов."

    [en_done]="Backup Kit — Restore completed successfully!"
    [ru_done]="Backup Kit — Восстановление завершено успешно!"
)

L=${LANG_CHOICE:-ru}
say() { echo "${MSG[${L}_$1]}"; }

# --- Цвета ---
RED="\033[0;31m"; GREEN="\033[0;32m"; YELLOW="\033[1;33m"; BLUE="\033[0;34m"; NC="\033[0m"
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

# --- systemd-inhibit ---
if [[ -z "${INHIBIT_LOCK:-}" ]]; then
    export INHIBIT_LOCK=1
    exec systemd-inhibit --what=handle-lid-switch:sleep:idle --why="$(say start)" "$0" "$@"
fi

# --- Настройки ---
BACKUP_DIR="/mnt/backups"
WORKDIR="$BACKUP_DIR/workdir"
LOG_DIR="$BACKUP_DIR/logs"
BACKUP_NAME="$BACKUP_DIR/backup-debian-12.tar.gz"

mkdir -p "$WORKDIR" "$LOG_DIR"
RUN_LOG="$LOG_DIR/restore-$(date +%F-%H%M%S).log"

# Очистка при прерывании
cleanup() {
    info "$(say cleanup)"
    rm -rf "$WORKDIR"
    ok "$(say cleanup_done)"
}
trap cleanup EXIT INT TERM ERR

# --- Проверка архива ---
if [ ! -f "$BACKUP_NAME" ]; then
    error "$(say no_archive)"
    exit 1
fi

# --- Функции ---
extract_archive() {
    info "$(say extract)..."
    if pv "$BACKUP_NAME" | tar -xzv --skip-old-files -C "$WORKDIR" >>"$RUN_LOG" 2>&1; then
        ok "$(say extract_done)"
    else
        error "Extraction failed. Check $RUN_LOG"
        exit 1
    fi
}

restore_packages() {
    PKG_DIR="$WORKDIR/system_packages"
    if [ ! -d "$PKG_DIR" ]; then
        warn "$(say restore_packages_skip)"
        return
    fi

    # sources.list
    [ -f "$PKG_DIR/sources.list" ] && sudo cp "$PKG_DIR/sources.list" /etc/apt/sources.list
    [ -d "$PKG_DIR/sources.list.d" ] && sudo cp -a "$PKG_DIR/sources.list.d/"* /etc/apt/sources.list.d/ 2>/dev/null || true
    # apt keys
    [ -f "$PKG_DIR/apt-keys.asc" ] && sudo apt-key add "$PKG_DIR/apt-keys.asc" 2>>"$RUN_LOG" || true

    sudo apt-get update >>"$RUN_LOG" 2>&1

    RESTORE_PACKAGES="${RESTORE_PACKAGES:-manual}"
    case "$RESTORE_PACKAGES" in
        manual)
            [ -f "$PKG_DIR/manual-packages.list" ] && {
                info "$(say restore_packages_manual)"
                xargs -a "$PKG_DIR/manual-packages.list" sudo apt-get install -y 2>>"$RUN_LOG" || true
                ok "$(say restore_packages_manual)"
            }
            ;;
        full)
            [ -f "$PKG_DIR/installed-packages.list" ] && {
                info "$(say restore_packages_full)"
                sudo dpkg --set-selections < "$PKG_DIR/installed-packages.list"
                sudo apt-get dselect-upgrade -y 2>>"$RUN_LOG" || true
                ok "$(say restore_packages_full)"
            }
            ;;
        none)
            warn "$(say restore_packages_skip)"
            ;;
        *)
            warn "Unknown RESTORE_PACKAGES=$RESTORE_PACKAGES, skipping."
            ;;
    esac
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

# --- Основной процесс ---
info "======================================================"
info "$(say start)"
info "======================================================"

echo "[$(date +%F_%T)] Restore started" >>"$RUN_LOG"

run_step "Extracting archive" extract_archive
run_step "Restoring packages" restore_packages

info "======================================================"
ok "$(say done)"
info "Log file: $RUN_LOG"
info "======================================================"

echo "[$(date +%F_%T)] Restore finished successfully" >>"$RUN_LOG"

exit 0

