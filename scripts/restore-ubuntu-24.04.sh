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
restore-ubuntu-24.04.sh — system restore (Ubuntu 24.04)
Reincarnation Backup Kit — MIT License
Copyright (c) 2025 Vladislav Krashevsky with support from ChatGPT
DOC

set -euo pipefail

# --- Пути к библиотекам ---
BIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$BIN_DIR/lib"

# --- Подключение библиотек ---
source "$LIB_DIR/i18n.sh" || die "Failed to load i18n"
init_app_lang

source "$LIB_DIR/logging.sh"
source "$LIB_DIR/user_home.sh"
source "$LIB_DIR/real_user.sh"
source "$LIB_DIR/runner.sh"
source "$LIB_DIR/privileges.sh"
source "$LIB_DIR/context.sh"
source "$LIB_DIR/guards-inhibit.sh"
source "$LIB_DIR/cleanup.sh"
source "$LIB_DIR/system_detect.sh"

if ! TARGET_HOME="$(resolve_target_home)"; then
    die "Cannot determine target home"
fi

if ! REAL_USER="$(resolve_real_user)"; then
    die "Cannot determine real user"
fi

require_root || exit 1
# inhibit_run "$0" "$@"

# === Настройки ===
BACKUP_DIR="/mnt/backups/REBK"
WORKDIR="$BACKUP_DIR/workdir"
LOG_DIR="$BACKUP_DIR/logs"
mkdir -p "$WORKDIR" "$LOG_DIR"
BACKUP_NAME="$BACKUP_DIR/backup-ubuntu-24.04.tar.gz"
RUN_LOG="$LOG_DIR/res-ubuntu-$(date +%F_%H%M%S).log"

if [ -d "$BACKUP_DIR" ]; then
    owner=$(stat -c %U "$BACKUP_DIR")
    if [ "$owner" != "$REAL_USER" ]; then
        info backup_change_owner "$REAL_USER:$REAL_USER"
        chown -R "$REAL_USER:$REAL_USER" "$BACKUP_DIR"
        chmod -R u+rwX,go+rX "$BACKUP_DIR"
    fi
else
    die backup_no_dir
fi

# Проверка архива
if [ ! -f "$BACKUP_NAME" ]; then
    error res_archive_not "$BACKUP_NAME"
    exit 1
fi

# --- Очистка WORKDIR ---
# Регистрируем $WORKDIR и устанавливаем trap
register_cleanup "$WORKDIR"
trap 'cleanup' EXIT INT TERM
info msg_workdir_cleaning $WORKDIR
cleanup_workdir
mkdir -p "$WORKDIR"
ok msg_workdir_cleaned $WORKDIR

# === Функции ===
extract_archive() {
    info res_extracting
    if pv "$BACKUP_NAME" | tar -xzv --skip-old-files -C "$WORKDIR" >>"$RUN_LOG" 2>&1; then
        ok res_extracting_ok
    else
        error res_extracting_fail
        exit 1
    fi
}

restore_system_packages() {
    PKG_DIR="$BACKUP_DIR/system/packages"

    info res_packages_full
    if sudo dpkg --set-selections < "$PKG_DIR/installed-packages.list" && \
        sudo apt-get -y dselect-upgrade >>"$RUN_LOG" 2>&1; then
        ok res_full_ok
    else
        error res_full_fail
        exit 1
    fi
}

restore_user_packages() {
    PKG_DIR="$BACKUP_DIR/system/packages"

    info res_packages_manual
    if xargs -a "$PKG_DIR/manual-packages.list" sudo apt install -y >>"$RUN_LOG" 2>&1; then
        ok res_manual_ok
    else
        error res_manual_fail
        exit 1
    fi
}

restore_repos_and_keys() {
    info res_apt_sources
    PKG_DIR="$BACKUP_DIR/system/packages"

    if [ ! -d "$PKG_DIR" ]; then
        error res_apt_fail
        exit 1
    fi

    sudo cp -a "$PKG_DIR/sources.list" /etc/apt/sources.list
    sudo cp -a "$PKG_DIR/sources.list.d/"* /etc/apt/sources.list.d/ 2>/dev/null || true
    sudo mkdir -p /etc/apt/keyrings
    sudo cp -a "$PKG_DIR/keyrings/"* /etc/apt/keyrings/ 2>/dev/null || true

    sudo apt update >>"$RUN_LOG" 2>&1 || warn res_apt_fail
    ok res_apt_ok
}

MODE="${1:-full}"

case "$MODE" in
    full)
        DO_SYSTEM=1
        DO_USER=0
        ;;
    manual)
        DO_SYSTEM=0
        DO_USER=1
        ;;
    *)
        die "Unknown mode: $MODE"
        ;;
esac

# === Основной процесс ===
echo "=============================================================" | tee -a "$RUN_LOG"
info "REBK — $(echo_msg res_start)"
info res_started

run_step "$(say step_archive)" extract_archive

if [[ $DO_SYSTEM -eq 1 ]]; then
    run_step "$(say step_system_packages)" restore_system_packages || die step_restore_fail
    run_step "$(say step_repos_and_keys)" restore_repos_and_keys || die step_restore_fail
fi

if [[ $DO_USER -eq 1 ]]; then
    run_step "$(say step_user_packages)" restore_user_packages
fi

ok res_done
info res_log_file $RUN_LOG
info "======================================================"

exit 0