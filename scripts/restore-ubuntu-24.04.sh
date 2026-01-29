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

# --- Проверка root только для команд, где нужны права ---
require_root() {
    if [[ $EUID -ne 0 ]]; then
        error "$(say run_sudo)"
        return 1
    fi
}

if [[ -n "${REBK_INHIBITED:-}" ]]; then
    return 0
fi

export REBK_INHIBITED=1

# Очистка при выходе
cleanup() {
    info clean_tmp
    rm -rf "$WORKDIR"
    ok clean_ok
}
trap cleanup EXIT INT TERM

inhibit_run() {
    systemd-inhibit \
        --who="REBK" \
        --why="Backup in progress" \
        --what=shutdown:sleep \
        "$@"
}

# -------------------------------------------------------------
# Настройки
# -------------------------------------------------------------
BACKUP_DIR="/mnt/backups"
WORKDIR="$BACKUP_DIR/workdir"
LOG_DIR="$BACKUP_DIR/logs"
BACKUP_NAME="$BACKUP_DIR/backup-ubuntu-24.04.tar.gz"
mkdir -p "$WORKDIR" "$LOG_DIR"
RUN_LOG="$LOG_DIR/restore-$(date +%F-%H%M%S).log"

# -------------------------------------------------------------
# Проверка архива
# -------------------------------------------------------------
if [ ! -f "$BACKUP_NAME" ]; then
    error archive_not_found "$BACKUP_NAME"
    exit 1
fi

# -------------------------------------------------------------
# Функции
# -------------------------------------------------------------
extract_archive() {
    info extracting
    if pv "$BACKUP_NAME" | tar -xzv --skip-old-files -C "$WORKDIR" >>"$RUN_LOG" 2>&1; then
        ok extract_ok
    else
        error extract_fail
        return 1
    fi
}

restore_repos_and_keys() {
    info repos
    PKG_DIR="$BACKUP_DIR/system/packages"

    if [ ! -d "$PKG_DIR" ]; then
        error repos_fail
        return 1
    fi

    sudo cp -a "$PKG_DIR/sources.list" /etc/apt/sources.list
    sudo cp -a "$PKG_DIR/sources.list.d/"* /etc/apt/sources.list.d/ 2>/dev/null || true
    sudo mkdir -p /etc/apt/keyrings
    sudo cp -a "$PKG_DIR/keyrings/"* /etc/apt/keyrings/ 2>/dev/null || true

    sudo apt update >>"$RUN_LOG" 2>&1 || warn apt_failed
    ok repos_ok
}

restore_packages() {
    PKG_DIR="$BACKUP_DIR/system/packages"
    mode="$RESTORE_PACKAGES"

    case "$mode" in
        manual)
            info packages_manual

            if [[ ! -f "$PKG_DIR/manual-packages.list" ]]; then
                error packages_list_missing "$PKG_DIR/manual-packages.list"
                return 1
            fi


            if xargs -a "$PKG_DIR/manual-packages.list" sudo apt install -y \
                >>"$RUN_LOG" 2>&1; then
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

: "${RESTORE_PACKAGES:=manual}"

restore_logs() {
    if [ "${RESTORE_LOGS:-false}" = "true" ]; then
        info relogs
        mkdir -p "$BACKUP_DIR/logs"
        cp -a "$BACKUP_DIR/system/packages/README" "$BACKUP_DIR/logs/" 2>/dev/null || true
        ok relogs_ok
    else
        info relogs_skip
    fi
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
# Основной процесс
# -------------------------------------------------------------
info "======================================================"
info "REBK — $(echo_msg re_start)" 
info "======================================================"

info re_started

run_step "$(say step_extract)" extract_archive
run_step "$(say step_repos)" restore_repos_and_keys
run_step "$(say step_packages)" restore_packages
run_step "$(say step_logs)" restore_logs

info "======================================================"
ok "REBK — $(echo_msg re_done)"
info re_log_file "$RUN_LOG"
info "======================================================"

info re_success

exit 0

