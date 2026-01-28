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
backup-ubuntu-22.04.sh v1.16 — System backup (Ubuntu 22.04)
Part of Backup Kit — minimal restore script with simple logging
Author: Vladislav Krashevsky
=============================================================
DOC

set -euo pipefail

# -------------------------------------------------------------
# Colors (safe for set -u)
# -------------------------------------------------------------
if [[ "${FORCE_COLOR:-0}" == "1" || -t 1 ]]; then
    RED="\033[0;31m"
    GREEN="\033[0;32m"
    YELLOW="\033[1;33m"
    BLUE="\033[0;34m"
    NC="\033[0m"
else
    RED=""; GREEN=""; YELLOW=""; BLUE=""; NC=""
fi

# -------------------------------------------------------------
# 1. Определяем директорию скрипта
# -------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -------------------------------------------------------------
# 2. Объявляем ассоциативный массив MSG
# -------------------------------------------------------------
declare -A MSG

# -------------------------------------------------------------
# 3. Функция загрузки сообщений
# -------------------------------------------------------------
load_messages() {
    local lang="$1"
    MSG=()
    case "$lang" in
        ru) source "$SCRIPT_DIR/i18n/messages_ru.sh" ;;
        en) source "$SCRIPT_DIR/i18n/messages_en.sh" ;;
        *) echo "Unknown language: $lang" >&2; return 1 ;;
    esac
}

# -------------------------------------------------------------
# 4. Безопасный say
# -------------------------------------------------------------
say() {
    local key="$1"; shift
    local msg="${MSG[$key]:-$key}"
    if [[ $# -gt 0 ]]; then
        printf "$msg" "$@"
    else
        printf '%s' "$msg"
    fi
}

# -------------------------------------------------------------
# 4a. echo_msg безопасный (возвращает строку)
# -------------------------------------------------------------
echo_msg() {
    say "$@"
}

# -------------------------------------------------------------
# 5-8. Логирование
# -------------------------------------------------------------
ok() {
    local key="$1"; shift
    local msg
    msg="$(say "$key" "$@")"
    printf "%b[OK]%b %b\n" "${GREEN:-}" "${NC:-}" "$msg" | tee -a "$RUN_LOG" >&2
}

info() {
    local key="$1"; shift
    local msg
    msg="$(say "$key" "$@")"
    printf "%b[INFO]%b %s\n" "${BLUE:-}" "${NC:-}" "$msg" | tee -a "$RUN_LOG" >&2
}

warn() {
    local key="$1"; shift
    local msg
    msg="$(say "$key" "$@")"
    printf "%b[WARN]%b %b\n" "${YELLOW:-}" "${NC:-}" "$msg" | tee -a "$RUN_LOG" >&2
}

error() {
    local key="$1"; shift
    local msg
    msg="$(say "$key" "$@")"
    printf "%b[ERROR]%b %b\n" "${RED:-}" "${NC:-}" "$msg" | tee -a "$RUN_LOG" >&2
}

# -------------------------------------------------------------
# 10. die
# -------------------------------------------------------------
die() {
    error "$@"
    exit 1
}

# -------------------------------------------------------------
# 11. Язык и загрузка сообщений
# -------------------------------------------------------------
LANG_CODE="${LANG_CODE:-ru}"
load_messages "$LANG_CODE"

# -------------------------------------------------------------
# Проверка root
# -------------------------------------------------------------
require_root() {
    if [[ $EUID -ne 0 ]]; then
        error run_sudo
        return 1
    fi
}

REAL_HOME="${HOME:-/home/$USER}"
if [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != "root" ]]; then
    REAL_HOME="/home/$SUDO_USER"
fi

# -------------------------------------------------------------
# Inhibit recursion via systemd-inhibit
# -------------------------------------------------------------
if [[ -t 1 ]] && command -v systemd-inhibit >/dev/null 2>&1; then
    if [[ -z "${INHIBIT_LOCK:-}" ]]; then
        export INHIBIT_LOCK=1
        exec systemd-inhibit \
            --what=handle-lid-switch:sleep:idle \
            --why="Backup in progress" \
            "$0" "$@"
    fi
fi

# -------------------------------------------------------------
# Paths
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
# -------------------------------------------------------------
# Backup packages (Ubuntu 22.04)
# -------------------------------------------------------------
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

    # Ubuntu 22.04 — старый механизм ключей
    apt-key exportall > "$PKG_DIR/apt-keys.asc" || true

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
step_ok="completed successfully"
step_fail="failed"

run_step() {
    local name="$1"
    local func="$2"

    declare -F "$func" >/dev/null || die "Function not found: $func"

    if "$func"; then
        ok "$name - $step_ok"
    else
        error "$name - $step_fail (see $RUN_LOG)"
        return 1
    fi
}

# -------------------------------------------------------------
# Create archive
# -------------------------------------------------------------
create_archive() {
    require_root || return 1

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
# Main
# -------------------------------------------------------------
info "======================================================"
info "Backup Kit — $(echo_msg backup_start)"
info "======================================================"

info backup_started

run_step "System packages" backup_packages || die "Backup failed"
run_step "Archive" create_archive

info "======================================================"
ok "Backup Kit — $(echo_msg backup_sucess)"
info log_file "$RUN_LOG"
info "======================================================"

info backup_finished

exit 0


