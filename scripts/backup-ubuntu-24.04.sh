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
backup-ubuntu-24.04.sh  — system backup (Ubuntu 24.04)
Reincarnation Backup Kit — MIT License
Copyright (c) 2025 Vladislav Krashevsky with support from ChatGPT
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

# -------------------------------------------------------------
# Настройки
# -------------------------------------------------------------
BACKUP_DIR="/mnt/backups"
WORKDIR="$BACKUP_DIR/workdir"
LOG_DIR="$BACKUP_DIR/logs"
mkdir -p "$WORKDIR" "$LOG_DIR"
BACKUP_NAME="$BACKUP_DIR/backup-ubuntu-24.04.tar.gz"
readonly RUN_LOG="$LOG_DIR/backup-$(date +%F-%H%M%S).log"

# -------------------------------------------------------------
# Ownership check
# -------------------------------------------------------------
require_root || die run_sudo

if [ -d "$BACKUP_DIR" ]; then
    real_user="${SUDO_USER:-$USER}"
    owner=$(stat -c %U "$BACKUP_DIR")
    if [ "$owner" != "$real_user" ]; then
        info change_owner "$real_user:$real_user"
        chown -R "$real_user:$real_user" "$BACKUP_DIR"
        chmod -R u+rwX,go+rX "$BACKUP_DIR"
    fi
else
    die no_dir
fi

# -------------------------------------------------------------
# Cleanup on exit
# -------------------------------------------------------------
cleanup() {
    info clean_tmp
    rm -rf "$WORKDIR"
    ok tmp_cleaned
}
trap cleanup EXIT INT TERM

# -------------------------------------------------------------
# Backup packages
# -------------------------------------------------------------
backup_packages() {
    info backup_pkgs
    PKG_DIR="$BACKUP_DIR/system/packages"
    mkdir -p "$PKG_DIR"

    dpkg --get-selections > "$PKG_DIR/installed-packages.list"
    dpkg-query -W -f='${Package} ${Version}\n' > "$PKG_DIR/installed-packages-versions.list"
    apt-mark showmanual > "$PKG_DIR/manual-packages.list"

    cp /etc/apt/sources.list "$PKG_DIR/sources.list"
    mkdir -p "$PKG_DIR/sources.list.d"
    cp -a /etc/apt/sources.list.d/* "$PKG_DIR/sources.list.d/" 2>/dev/null || true

    mkdir -p "$PKG_DIR/keyrings"
    cp -a /etc/apt/keyrings/* "$PKG_DIR/keyrings/" 2>/dev/null || true

    cat > "$PKG_DIR/README" <<'EOF'
=============================================================
System Packages Backup and Restore (Ubuntu 24.04)
=============================================================
This module is part of Backup Kit v1.16.
Contains package lists, repositories and GPG keyrings.
EOF

    ok pkgs_done
}

# -------------------------------------------------------------
# Run step
# -------------------------------------------------------------
run_step() {
    local step_key="$1"
    local func="$2"

    declare -F "$func" >/dev/null || die not_function "$func"

    if "$func"; then
        ok step_ok "$step_key"
    else
        error step_fail "$step_key" "$RUN_LOG" || true
        return 1
    fi
}

# -------------------------------------------------------------
# Create archive
# -------------------------------------------------------------
create_archive() {
    info create_archive "$BACKUP_NAME..."

    SIZE=$(du -sb "$WORKDIR" | awk '{print $1}')

    if [[ -f "$BACKUP_NAME" ]]; then
        warn archive_exists
        rm -f "${BACKUP_NAME}.old"
        mv "$BACKUP_NAME" "${BACKUP_NAME}.old"
    fi

    if tar -C "$WORKDIR" -cf - . | pv -s "$SIZE" | gzip > "$BACKUP_NAME"; then
        ok archive_done "$BACKUP_NAME"
    else
        error archive_fail
        return 1
    fi
}

# -------------------------------------------------------------
# Основной процесс
# -------------------------------------------------------------
info "======================================================"
info "REBK — $(echo_msg backup_start)"
info "======================================================"

info backup_started

run_step "$(say system_packages)" backup_packages || die backup_fail
run_step "$(say archive)" create_archive

info "======================================================"
ok "REBK — $(echo_msg backup_sucess)"
info log_file "$RUN_LOG"
info "======================================================"

info backup_finished

exit 0


