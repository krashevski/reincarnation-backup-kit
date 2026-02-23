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

# Стандартная библиотека REBK
# --- Определяем BIN_DIR относительно скрипта ---
BIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Путь к библиотекам всегда относительно BIN_DIR
LIB_DIR="$BIN_DIR/lib"

source "$LIB_DIR/logging.sh"
source "$LIB_DIR/safety.sh"
source "$LIB_DIR/cleanup.sh"
source "$LIB_DIR/privileges.sh"
source "$LIB_DIR/context.sh"
source "$LIB_DIR/guards-inhibit.sh"

if [[ "${1:-}" == "--help" ]]; then
    echo "Usage: $0 [ARCHIVE]"
    echo restore_help
    echo
    exit 0
fi

# --- Настройки ---
BACKUP_DIR="/mnt/backups"
LOG_DIR="$BACKUP_DIR/logs"
RUN_LOG="$LOG_DIR/restore-dispatch-$(date +%F-%H%M%S).log"

cleanup() {
   info dispatcher_finished
}
trap cleanup EXIT INT TERM

# --- Проверки ---
if [ ! -d "$BACKUP_DIR" ]; then
    error not_found_dir
    exit 1
fi

# --- Определяем систему ---
if [ -r /etc/os-release ]; then
    source /etc/os-release
    DISTRO="$ID"
    VERSION="$VERSION_ID"
else
    error not_system
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
        error not_supported "$DISTRO" "$VERSION"
        exit 1
        ;;
esac

# --- Проверки наличия ---
if [ ! -x "$SCRIPT" ]; then
    error not_found_script "$SCRIPT"
    exit 1
fi

if [ ! -f "$ARCHIVE" ]; then
    error not_found_archive "$ARCHIVE"
    exit 1
fi

# --- Запуск ---
info "============================================================="
info restore_running "$SCRIPT" "$ARCHIVE"
info "============================================================="

{
    echo "[$(date +%F_%T)] dispatcher_started "$SCRIPT" "$ARCHIVE"
    echo "[$(date +%F_%T)] dispatcher_finished
} 2>&1 | tee -a "$RUN_LOG"

info "============================================================="
ok restore_finished
info log_file "$RUN_LOG"
info "============================================================="

exit 0
