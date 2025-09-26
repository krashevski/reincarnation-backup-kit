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
backup-ubuntu-22.04.sh v1.15 — System backup (Ubuntu 22.04)
Part of Backup Kit — minimal restore script with simple logging
   Author: Vladislav Krashevsky with support from ChatGPT
   License: MIT
-------------------------------------------------------------
Description:
   Creates a backup archive with:
     - System packages (manual + full lists, with versions)
     - APT sources and keys
     - User backup logs
Output archive:
   backup-ubuntu-22.04-YYYYMMDD-HHMMSS.tar.gz
Notes:
   - Tested on Ubuntu 22.04 LTS.
   - The resulting backup can be restored using
     `restore-ubuntu-22.04.sh`.
   - ⚠️ User home data (~/) is included in this backup.
=============================================================
DOC

set -euo pipefail

# --- systemd-inhibit (sleep protection) ---
if [[ -z "${INHIBIT_LOCK:-}" ]]; then
    export INHIBIT_LOCK=1
    exec systemd-inhibit --what=handle-lid-switch:sleep:idle --why="Backup running" "$0" "$@"
fi

# ===================== Colors =====================
RED="\033[0;31m"; GREEN="\033[0;32m"; YELLOW="\033[1;33m"; BLUE="\033[0;34m"; NC="\033[0m"
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }


# ===================== Localization =====================
LANG_CHOICE="${LANG_CHOICE:-en}"  # default English
declare -A MSG

if [[ "$LANG_CHOICE" == "ru" ]]; then
    MSG[START]="Backup Kit — запуск системного бэкапа (Ubuntu 22.04)"
    MSG[END_OK]="Backup Kit — системный бэкап успешно завершён!"
    MSG[CHANGE_OWNER]="Меняю владельца каталога на"
    MSG[NO_DIR]="Каталог не существует, проверьте монтирование."
    MSG[CLEAN]="Временные файлы очищены."
    MSG[PKG]="Резервное копирование пакетов и репозиториев..."
    MSG[PKG_OK]="system_packages сохранён."
    MSG[ARCHIVE]="Создание архива"
    MSG[ARCHIVE_OK]="Архив создан"
    MSG[ARCHIVE_FAIL]="Ошибка при создании архива"
    MSG[run_sudo]="Скрипт нужно запускать с правами root (sudo)"
    MSG[step_ok]="Шаг выполнен."
    MSG[step_fail]="Шаг завершился с ошибкой. Проверьте лог."
else
    MSG[START]="Backup Kit — Starting system backup (Ubuntu 22.04)"
    MSG[END_OK]="Backup Kit — System backup completed successfully!"
    MSG[CHANGE_OWNER]="Changing directory owner to"
    MSG[NO_DIR]="Directory does not exist, check mounting."
    MSG[CLEAN]="Temporary files cleaned."
    MSG[PKG]="Backing up installed packages and repositories..."
    MSG[PKG_OK]="system_packages saved."
    MSG[ARCHIVE]="Creating archive"
    MSG[ARCHIVE_OK]="Archive created"
    MSG[ARCHIVE_FAIL]="Archive creation failed"
    MSG[run_sudo]="The script must be run with root rights (sudo)"
    MSG[step_ok]="Step completed."
    MSG[step_fail]="Step completed with an error. Check the log."
fi

# --- Проверка root только для команд, где нужны права ---
require_root() {
    if [[ $EUID -ne 0 ]]; then
        error "${MSG[run_sudo]}"
        return 1
    fi
}

# --- Paths ---
BACKUP_DIR="/mnt/backups"
WORKDIR="$BACKUP_DIR/workdir"
LOG_DIR="$BACKUP_DIR/logs"
mkdir -p "$WORKDIR" "$LOG_DIR"
TIMESTAMP=$(date +%F-%H%M%S)
BACKUP_NAME="$BACKUP_DIR/backup-ubuntu-22.04-$TIMESTAMP.tar.gz"
RUN_LOG="$LOG_DIR/backup-$TIMESTAMP.log"

# === Ownership check ===
if [ -d "$BACKUP_DIR" ]; then
    real_user="${SUDO_USER:-$USER}"
    owner=$(stat -c %U "$BACKUP_DIR")

    if [ "$owner" != "$real_user" ]; then
        info "${MSG[CHANGE_OWNER]} $real_user:$real_user"
        sudo chown -R "$real_user:$real_user" "$BACKUP_DIR"
        sudo chmod -R u+rwX,go+rX "$BACKUP_DIR"
    fi
else
    error "${MSG[NO_DIR]}"
    exit 1
fi

# === Cleanup on exit ===
cleanup() {
    info "${MSG[clean_tmp]}"
    rm -rf "$WORKDIR"
    ok "${MSG[CLEAN]}"
}
trap cleanup EXIT INT TERM

# --- Backup functions ---
backup_packages() {
    info "${MSG[PKG]}"
    PKG_DIR="$WORKDIR/system_packages"
    mkdir -p "$PKG_DIR"

    dpkg --get-selections > "$PKG_DIR/installed-packages.list"
    apt-mark showmanual > "$PKG_DIR/manual-packages.list"
    apt list --installed > "$PKG_DIR/versions.list"

    ls /etc/apt/sources.list.d/ > "$PKG_DIR/custom-repos.list" || true
    cp /etc/apt/sources.list "$PKG_DIR/sources.list"
    mkdir -p "$PKG_DIR/sources.list.d"
    cp -a /etc/apt/sources.list.d/* "$PKG_DIR/sources.list.d/" 2>/dev/null || true
    apt-key exportall > "$PKG_DIR/apt-keys.asc" || true

    cat > "$PKG_DIR/README" <<'EOF'
=============================================================
System Packages Backup and Restore (Ubuntu 22.04)
=============================================================
This module is part of **Backup Kit v1.15**.
Contains lists of packages, versions, repositories, and GPG keys.

⚠️ User data (~/) is included in this backup.

## Restore

Use:

    ./restore-ubuntu-22.04.sh <archive>

### Restore package modes

    RESTORE_PACKAGES=manual — manually installed packages (recommended)
    RESTORE_PACKAGES=full   — full list of packages
    RESTORE_PACKAGES=none   — skip packages

### Logs

    RESTORE_LOGS=true ./restore-ubuntu-22.04.sh <archive>
EOF

    ok "${MSG[PKG_OK]}"
}

run_step() {
    local name="$1"
    local func="$2"
    info "$name..."
    if "$func" >>"$RUN_LOG" 2>&1; then
        ok "$name — ${MSG[step_ok]}"
        echo "[$(date +%F_%T)] $name completed" >>"$RUN_LOG"
    else
        error "$name — ${MSG[step_fail]}: $RUN_LOG"
        echo "[$(date +%F_%T)] $name failed" >>"$RUN_LOG"
        exit 1
    fi
}

create_archive() {
    info "${MSG[ARCHIVE]} $BACKUP_NAME ..."
    SIZE=$(du -sb "$WORKDIR" | awk '{print $1}')
    
    require_root && { error "Root required for backup"; exit 1; }
    
    if tar -C "$WORKDIR" -cf - . | pv -s "$SIZE" -n -w 80 | gzip > "$BACKUP_NAME"; then
        ok "${MSG[ARCHIVE_OK]}: $BACKUP_NAME"
    else
        error "${MSG[ARCHIVE_FAIL]}"
        exit 1
    fi
}

# --- Main ---
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

