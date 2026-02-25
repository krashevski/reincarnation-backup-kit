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

# === Настройки ===
BACKUP_DIR="/mnt/backups"
WORKDIR="$BACKUP_DIR/workdir"
LOG_DIR="$BACKUP_DIR/logs"
BACKUP_NAME="$BACKUP_DIR/backup-ubuntu-24.04.tar.gz"
mkdir -p "$WORKDIR" 
RUN_LOG="$LOG_DIR/restore-$(date +%F_%H%M%S).log"
mkdir -p "$LOG_DIR"

# Очистка при выходе
cleanup() {
    info clean_tmp
    rm -rf "$WORKDIR"
    ok clean_ok
}
trap cleanup EXIT INT TERM

# Проверка архива
if [ ! -f "$BACKUP_NAME" ]; then
    error restore_archive_not "$BACKUP_NAME"
    exit 1
fi

# === Функции ===
extract_archive() {
    info restore_extracting
    if pv "$BACKUP_NAME" | tar -xzv --skip-old-files -C "$WORKDIR" >>"$RUN_LOG" 2>&1; then
        ok restore_extracting_ok
    else
        error restore_extracting_fail
        exit 1
    fi
}

restore_repos_and_keys() {
    info restore_apt_sources
    PKG_DIR="$BACKUP_DIR/system/packages"

    if [ ! -d "$PKG_DIR" ]; then
        error restore_apt_fail
        exit 1
    fi

    sudo cp -a "$PKG_DIR/sources.list" /etc/apt/sources.list
    sudo cp -a "$PKG_DIR/sources.list.d/"* /etc/apt/sources.list.d/ 2>/dev/null || true
    sudo mkdir -p /etc/apt/keyrings
    sudo cp -a "$PKG_DIR/keyrings/"* /etc/apt/keyrings/ 2>/dev/null || true

    sudo apt update >>"$RUN_LOG" 2>&1 || warn restore_apt_fail
    ok restore_apt_ok
}

restore_packages() {
    PKG_DIR="$BACKUP_DIR/system/packages"
    mode="${RESTORE_PACKAGES:-manual}"

    case "$mode" in
        manual)
            info restore_packages_manual
            if xargs -a "$PKG_DIR/manual-packages.list" sudo apt install -y >>"$RUN_LOG" 2>&1; then
                ok packages_manual_ok
            else
                error packages_manual_fail
                exit 1
            fi
            ;;
        full)
            info packages_full
            if sudo dpkg --set-selections < "$PKG_DIR/installed-packages.list" && \
               sudo apt-get -y dselect-upgrade >>"$RUN_LOG" 2>&1; then
                ok packages_full_ok
            else
                error packages_full_fail
                exit 1
            fi
            ;;
        none)
            warn packages_skip
            ;;
        *)
            error invalid_mode "$mode"
            exit 1
            ;;
    esac
}

restore_logs() {
    if [ "${RESTORE_LOGS:-false}" = "true" ]; then
        info "$(say LOGS)"
        mkdir -p "$BACKUP_DIR/logs"
        cp -a "$WORKDIR/system_packages/README" "$BACKUP_DIR/logs/" || true
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
        ok "$name $(say compl)"
        echo "[$(date +%F_%T)] $name $(say completed)" >>"$RUN_LOG"
    else
        error "$name $(say check) $RUN_LOG"
        echo "[$(date +%F_%T)] $name $(say failed)" >>"$RUN_LOG"
        exit 1
    fi
}

# === Основной процесс ===
info "======================================================"
info restore_start
info "======================================================"

echo "[$(date +%F_%T)] restore_started" >>"$RUN_LOG"

run_step "$(say extracting)" extract_archive
run_step "$(say repos_keys)" restore_repos_and_keys
run_step "$(say packages)" restore_packages
run_step "$(say logs)" restore_logs

info "======================================================"
ok "$(say DONE)"
info "$(say log_file) $RUN_LOG"
info "======================================================"

echo "[$(date +%F_%T)] $(say success)" >>"$RUN_LOG"

exit 0

