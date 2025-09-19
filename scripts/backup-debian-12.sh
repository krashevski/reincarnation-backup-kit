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
backup-debian-12.sh v1.15 — System backup (Debian 12)
Part of Backup Kit — minimal restore script with simple logging
   Author: Vladislav Krashevsky with support from ChatGPT
   License: MIT
-------------------------------------------------------------
Description:
   Creates a backup archive with:
     - System packages (manual + full lists)
     - APT sources and keys
     - User backup logs
Output archive:
   backup-debian-12.tar.gz
Notes:
   - Tested on Debian 12 (Bookworm).
   - The resulting backup can be restored using
     `restore-debian-12.sh`.
   - ⚠️ User home data (~/) is NOT included here
     (use backup-restore-userdata.sh).
=============================================================
DOC

set -euo pipefail

# ===================== Localization =====================
LANG_CHOICE="${LANG_CHOICE:-en}"
declare -A MSG

if [[ "$LANG_CHOICE" == "ru" ]]; then
    MSG[START]="Backup Kit — запуск бэкапа (Debian 12)"
    MSG[END_OK]="Backup Kit — бэкап успешно завершён!"
    MSG[CLEAN]="Временные файлы очищены."
    MSG[INTERRUPT]="Бэкап прерван. Очистка временных файлов..."
    MSG[PKG]="Резервное копирование пакетов и репозиториев..."
    MSG[PKG_OK]="system_packages сохранён."
    MSG[ARCHIVE]="Создание архива"
    MSG[ARCHIVE_OK]="Архив создан"
    MSG[ARCHIVE_FAIL]="Ошибка при создании архива"
else
    MSG[START]="Backup Kit — Starting backup (Debian 12)"
    MSG[END_OK]="Backup Kit — Backup completed successfully!"
    MSG[CLEAN]="Temporary files cleaned."
    MSG[INTERRUPT]="Backup interrupted. Cleaning temporary files..."
    MSG[PKG]="Backing up installed packages and repositories..."
    MSG[PKG_OK]="system_packages saved."
    MSG[ARCHIVE]="Creating archive"
    MSG[ARCHIVE_OK]="Archive created"
    MSG[ARCHIVE_FAIL]="Archive creation failed"
fi

# ===================== Colors =====================
RED="\033[0;31m"; GREEN="\033[0;32m"; YELLOW="\033[1;33m"; BLUE="\033[0;34m"; NC="\033[0m"
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

# --- systemd-inhibit (sleep protection) ---
if [[ -z "${INHIBIT_LOCK:-}" ]]; then
    export INHIBIT_LOCK=1
    exec systemd-inhibit --what=handle-lid-switch:sleep:idle --why="Backup running" "$0" "$@"
fi

# === Paths ===
BACKUP_DIR="/mnt/backups"
WORKDIR="$BACKUP_DIR/workdir"
LOG_DIR="$BACKUP_DIR/logs"
BACKUP_NAME="$BACKUP_DIR/backup-debian-12.tar.gz"

mkdir -p "$WORKDIR" "$LOG_DIR"
RUN_LOG="$LOG_DIR/backup-$(date +%F-%H%M%S).log"

# Cleanup
cleanup() {
    rm -rf "$WORKDIR"
    info "${MSG[CLEAN]}"
}
trap cleanup EXIT INT TERM

# === Functions ===
backup_packages() {
    info "${MSG[PKG]}"
    PKG_DIR="$WORKDIR/system_packages"
    mkdir -p "$PKG_DIR"

    dpkg --get-selections > "$PKG_DIR/installed-packages.list"
    apt-mark showmanual > "$PKG_DIR/manual-packages.list"
    ls /etc/apt/sources.list.d/ > "$PKG_DIR/custom-repos.list" || true
    cp /etc/apt/sources.list "$PKG_DIR/sources.list"
    mkdir -p "$PKG_DIR/sources.list.d"
    cp -a /etc/apt/sources.list.d/* "$PKG_DIR/sources.list.d/" 2>/dev/null || true
    apt-key exportall > "$PKG_DIR/apt-keys.asc" || true

    cat > "$PKG_DIR/README" <<'EOF'
=============================================================
System Packages Backup and Restore (Debian 12)
=============================================================
This module is part of **Backup Kit v1.15**.
Contains lists of packages, repositories and GPG keys.

⚠️ Important: user data (~/) is NOT included in this backup.
Use `backup-restore-userdata.sh` for home directories.

## Restore

Use:

    ./restore-debian-12.sh

### Package restore modes

    RESTORE_PACKAGES=manual — manually installed packages (recommended)
    RESTORE_PACKAGES=full   — full list of packages
    RESTORE_PACKAGES=none   — skip packages

### Logs

    RESTORE_LOGS=true ./restore-debian-12.sh
EOF

    ok "${MSG[PKG_OK]}"
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

create_archive() {
    info "${MSG[ARCHIVE]} $BACKUP_NAME ..."
    SIZE=$(du -sb "$WORKDIR" | awk '{print $1}')
    if [ -f "$BACKUP_NAME" ]; then
        warn "$BACKUP_NAME already exists. Overwriting."
    fi
    if tar -C "$WORKDIR" -cf - . | pv -s "$SIZE" -n -w 80 | gzip > "$BACKUP_NAME"; then
        ok "${MSG[ARCHIVE_OK]}: $BACKUP_NAME"
        echo "[$(date +%F_%T)] Archive created" >>"$RUN_LOG"
    else
        error "${MSG[ARCHIVE_FAIL]}"
        echo "[$(date +%F_%T)] Archive failed" >>"$RUN_LOG"
        exit 1
    fi
}

# === Main ===
info "======================================================"
info "${MSG[START]}"
info "======================================================"

echo "[$(date +%F_%T)] Backup started" >>"$RUN_LOG"

run_step "Backing up system packages" backup_packages
run_step "Creating archive" create_archive

info "======================================================"
ok "${MSG[END_OK]}"
info "Log file: $RUN_LOG"
info "======================================================"

echo "[$(date +%F_%T)] Backup finished successfully" >>"$RUN_LOG"

exit 0

