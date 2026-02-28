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
backup-debian-12.sh v1.16 — System backup (Debian 12)
Part of Backup Kit — minimal restore script with simple logging
Author: Vladislav Krashevsky
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

require_root || return 1
# inhibit_run "$0" "$@"

# -------------------------------------------------------------
# Настройки
# -------------------------------------------------------------
BACKUP_DIR="/mnt/backups/REBK"
WORKDIR="$BACKUP_DIR/workdir"
LOG_DIR="$BACKUP_DIR/logs"
mkdir -p "$WORKDIR" "$LOG_DIR"
BACKUP_NAME="$BACKUP_DIR/backup-ubuntu-24.04.tar.gz"
readonly RUN_LOG="$LOG_DIR/bap-ubuntu-$(date +%F-%H%M%S).log"

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

# --- Очистка WORKDIR ---
# Регистрируем $WORKDIR и устанавливаем trap
register_cleanup "$WORKDIR"
trap 'cleanup' EXIT INT TERM
info install_workdir_cleaning $WORKDIR
cleanup_workdir
mkdir -p "$WORKDIR"
ok install_workdir_cleaned

# -------------------------------------------------------------
# Backup packages
# -------------------------------------------------------------
backup_packages() {
    PKG_DIR="$BACKUP_DIR/system/packages"
    mkdir -p "$PKG_DIR"

    dpkg --get-selections > "$PKG_DIR/installed-packages.list"

    ls /etc/apt/sources.list.d/ > "$PKG_DIR/custom-repos.list" || true
    cp /etc/apt/sources.list "$PKG_DIR/sources.list"
    mkdir -p "$PKG_DIR/sources.list.d"
    cp -a /etc/apt/sources.list.d/* "$PKG_DIR/sources.list.d/" 2>/dev/null || true
    apt-key exportall > "$PKG_DIR/apt-keys.asc" || true

    cat > "$PKG_DIR/README" <<'EOF'
=============================================================
System Packages Backup and Restore (Debian 12)
=============================================================
This module is part of Backup Kit v1.16.
Contains package lists, repositories and GPG keyrings.
EOF

    ok backup_system_pkgs
}

backup_user_packages() {
    PKG_DIR="$BACKUP_DIR/system/packages"
    mkdir -p "$PKG_DIR"

    apt-mark showmanual > "$PKG_DIR/manual-packages.list"

    cat > "$PKG_DIR/README_USER_PACKAGES" <<'EOF'
=============================================================
User packages backup (Debian 12)
=============================================================
This module is part of REBK
Contains User-installed packages
EOF

    ok backup_user_pkgs
}

# -------------------------------------------------------------
# Create archive
# -------------------------------------------------------------
create_archive() {
    info backup_create_archive "$BACKUP_NAME..."

    [[ -d "$WORKDIR" ]] || die "WORKDIR missing: $WORKDIR"

    SIZE=$(du -sb "$WORKDIR" 2>/dev/null | awk '{print $1}')
    SIZE=${SIZE:-0}

    if [[ -f "$BACKUP_NAME" ]]; then
        warn backup_archive_exists
        rm -f "${BACKUP_NAME}.old"
        mv "$BACKUP_NAME" "${BACKUP_NAME}.old"
    fi

    if tar -C "$BACKUP_DIR" -cf - system | pv -s "$SIZE" | gzip > "$BACKUP_NAME"; then
        ok backup_archive_done "$BACKUP_NAME"
    else
        error backup_archive_fail
        return 1
    fi
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

# -------------------------------------------------------------
# Основной процесс
# -------------------------------------------------------------
echo "=============================================================" | tee -a "$RUN_LOG"
info "REBK — $(echo_msg backup_start)"
info backup_started

if [[ $DO_SYSTEM -eq 1 ]]; then
    run_step "$(say step_system_packages)" backup_system_packages || die step_backup_fail
fi

if [[ $DO_USER -eq 1 ]]; then
    run_step "$(say step_user_packages)" backup_user_packages || die step_backup_fail
fi
run_step "$(say step_archive)" create_archive

ok "REBK — $(echo_msg backup_sucess)"
info backup_log_file "$RUN_LOG"
echo "=============================================================" | tee -a "$RUN_LOG"

exit 0