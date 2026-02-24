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

# --- Пути к библиотекам ---
BIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$BIN_DIR/lib"

# --- Подключение библиотек ---
source "$LIB_DIR/i18n.sh"
init_app_lang

source "$LIB_DIR/logging.sh"
source "$LIB_DIR/user_home.sh"
source "$LIB_DIR/real_user.sh"
source "$LIB_DIR/privileges.sh"
source "$LIB_DIR/context.sh"
source "$LIB_DIR/guards-inhibit.sh"
source "$LIB_DIR/system_detect.sh"

if ! TARGET_HOME="$(resolve_target_home)"; then
    die "Cannot determine target home"
fi

if ! REAL_USER="$(resolve_real_user)"; then
    die "Cannot determine real user"
fi

require_root || return 1
# inhibit_run "$0" "$@"

# --- Detect system ---
detect_system || exit 1
# echo "[DEBUG] DISTRO_ID=$DISTRO_ID, DISTRO_VER=$DISTRO_VER"

## layout / policy
BACKUP_DIR="/mnt/backups"
LOG_DIR="$BACKUP_DIR/logs"
WORKDIR="$BACKUP_DIR/workdir"

# --- Определяем скрипт и архив ---
SCRIPT=""
ARCHIVE="${1:-}"

case "$DISTRO_ID-$DISTRO_VER" in
    ubuntu-24.04)
        SCRIPT="$TARGET_HOME/bin/restore-ubuntu-24.04.sh"
        ARCHIVE="${ARCHIVE:-$BACKUP_DIR/backup-ubuntu-24.04.tar.gz}"
        ;;
    ubuntu-22.04)
        SCRIPT="$TARGET_HOME/bin/restore-ubuntu-22.04.sh"
        ARCHIVE="${ARCHIVE:-$BACKUP_DIR/backup-ubuntu-22.04.tar.gz}"
        ;;
    debian-12)
        SCRIPT="$TARGET_HOME/bin/restore-debian-12.sh"
        ARCHIVE="${ARCHIVE:-$BACKUP_DIR/backup-debian-12.tar.gz}"
        ;;
    *)
        error not_supported "$DISTRO_ID" "$DISTRO_VER"
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
