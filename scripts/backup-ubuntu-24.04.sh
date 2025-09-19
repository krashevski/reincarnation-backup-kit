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
backup-ubuntu-24.04.sh v1.15 — System backup (Ubuntu 24.04)
Part of Backup Kit — minimal restore script with simple logging
   Author: Vladislav Krashevsky with support from ChatGPT
   License: MIT
=============================================================
DOC

set -euo pipefail

# === Colors ===
RED="\033[0;31m"; GREEN="\033[0;32m"; YELLOW="\033[1;33m"; BLUE="\033[0;34m"; NC="\033[0m"
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARNING]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

# === Messages ===
declare -A MSG_RU=(
    [start]="Запуск резервного копирования системы (Ubuntu 24.04)"
    [change_owner]="Меняю владельца каталога на"
    [no_dir]="Каталог не существует, проверьте монтирование."
    [clean_tmp]="Очистка временных файлов..."
    [tmp_cleaned]="Временные файлы очищены."
    [backup_pkgs]="Резервное копирование пакетов и репозиториев..."
    [pkgs_done]="Системные пакеты сохранены."
    [create_archive]="Создание архива"
    [archive_exists]="Архив уже существует. Переименовываю в .old"
    [archive_done]="Архив создан"
    [archive_fail]="Ошибка при создании архива"
    [done]="Резервное копирование завершено успешно!"
)

declare -A MSG_EN=(
    [start]="Starting system backup (Ubuntu 24.04)"
    [change_owner]="Changing owner of directory to"
    [no_dir]="Directory does not exist, check mount point."
    [clean_tmp]="Cleaning temporary files..."
    [tmp_cleaned]="Temporary files cleaned."
    [backup_pkgs]="Backing up system packages and repositories..."
    [pkgs_done]="System packages saved."
    [create_archive]="Creating archive"
    [archive_exists]="Archive already exists. Renaming to .old"
    [archive_done]="Archive created"
    [archive_fail]="Archive creation failed"
    [done]="System backup completed successfully!"
)

# === Language autodetect ===
if [[ "${LANG:-}" =~ ^ru ]]; then
    declare -n MSG=MSG_RU
else
    declare -n MSG=MSG_EN
fi

# --- Inhibit recursion via systemd-inhibit ---
if [[ -z "${INHIBIT_LOCK:-}" ]]; then
    export INHIBIT_LOCK=1
    exec systemd-inhibit --what=handle-lid-switch:sleep:idle --why="Backup in progress" "$0" "$@"
fi

# === Paths ===
BACKUP_DIR="/mnt/backups"
WORKDIR="$BACKUP_DIR/workdir"
LOG_DIR="$BACKUP_DIR/logs"
BACKUP_NAME="$BACKUP_DIR/backup-ubuntu-24.04.tar.gz"

mkdir -p "$WORKDIR" "$LOG_DIR"
RUN_LOG="$LOG_DIR/backup-$(date +%F-%H%M%S).log"

# === Ownership check ===
if [ -d "$BACKUP_DIR" ]; then
    owner=$(stat -c %U "$BACKUP_DIR")
    if [ "$owner" != "$USER" ]; then
        info "${MSG[change_owner]} $USER:$USER"
        sudo chown -R "$USER:$USER" "$BACKUP_DIR"
        sudo chmod -R 755 "$BACKUP_DIR"
    fi
else
    error "${MSG[no_dir]}"
    exit 1
fi

# === Cleanup on exit ===
cleanup() {
    info "${MSG[clean_tmp]}"
    rm -rf "$WORKDIR"
    ok "${MSG[tmp_cleaned]}"
}
trap cleanup EXIT INT TERM

# === Backup packages ===
backup_packages() {
    info "${MSG[backup_pkgs]}"
    PKG_DIR="$WORKDIR/system_packages"
    mkdir -p "$PKG_DIR"

    dpkg --get-selections > "$PKG_DIR/installed-packages.list"
    dpkg-query -W -f='${Package} ${Version}\n' > "$PKG_DIR/installed-packages-versions.list"
    apt-mark showmanual > "$PKG_DIR/manual-packages.list"

    ls /etc/apt/sources.list.d/ > "$PKG_DIR/custom-repos.list" || true
    cp /etc/apt/sources.list "$PKG_DIR/sources.list"
    mkdir -p "$PKG_DIR/sources.list.d"
    cp -a /etc/apt/sources.list.d/* "$PKG_DIR/sources.list.d/" 2>/dev/null || true

    mkdir -p "$PKG_DIR/keyrings"
    cp -a /etc/apt/keyrings/* "$PKG_DIR/keyrings/" 2>/dev/null || true

    # === Dual-language README ===
    cat > "$PKG_DIR/README" <<'EOF'
=============================================================
System Packages Backup and Restore (Ubuntu 24.04)
=============================================================
This module is part of **Backup Kit v1.15**.
Contains package lists, repositories and GPG keyrings.

⚠️ Note: User home data (~/) is not included here.
Use `backup-restore-userdata.sh` for user data backup.

## Restore
Run:

    ./restore-ubuntu-24.04.sh

### Packages
    RESTORE_PACKAGES=manual — restore manually installed packages (recommended)
    RESTORE_PACKAGES=full   — restore full list
    RESTORE_PACKAGES=none   — skip packages

=============================================================
Резервное копирование и восстановление пакетов (Ubuntu 24.04)
=============================================================
Этот модуль входит в **Backup Kit v1.15**.
Содержит списки пакетов, репозиториев и GPG ключей.

⚠️ Важно: данные пользователей (~/) не включены сюда.
Используйте `backup-restore-userdata.sh` для бэкапа.

## Восстановление
Запустите:

    ./restore-ubuntu-24.04.sh

### Пакеты
    RESTORE_PACKAGES=manual — восстановить вручную установленные пакеты (рекомендуется)
    RESTORE_PACKAGES=full   — восстановить полный список пакетов
    RESTORE_PACKAGES=none   — пропустить восстановление пакетов
EOF

    ok "${MSG[pkgs_done]}"
}

# === Run step ===
run_step() {
    local name="$1"; local func="$2"
    info "$name..."
    if "$func" >>"$RUN_LOG" 2>&1; then
        ok "$name completed."
    else
        error "$name failed. Check $RUN_LOG"
        exit 1
    fi
}

# === Create archive ===
create_archive() {
    info "${MSG[create_archive]} $BACKUP_NAME ..."
    SIZE=$(du -sb "$WORKDIR" | awk '{print $1}')

    if [ -f "$BACKUP_NAME" ]; then
        warn "${MSG[archive_exists]}"
        mv "$BACKUP_NAME" "${BACKUP_NAME}.old"
    fi

    if tar -C "$WORKDIR" -cf - . | pv -s "$SIZE" | gzip > "$BACKUP_NAME" 2>>"$RUN_LOG"; then
        ok "${MSG[archive_done]}: $BACKUP_NAME"
    else
        error "${MSG[archive_fail]}"
        exit 1
    fi
}

# === Main ===
info "======================================================"
info "Backup Kit — ${MSG[start]}"
info "======================================================"

echo "[$(date +%F_%T)] Backup started" >>"$RUN_LOG"

run_step "System packages" backup_packages
run_step "Archive" create_archive

info "======================================================"
ok "Backup Kit — ${MSG[done]}"
info "Log file: $RUN_LOG"
info "======================================================"

echo "[$(date +%F_%T)] Backup finished successfully" >>"$RUN_LOG"
exit 0

