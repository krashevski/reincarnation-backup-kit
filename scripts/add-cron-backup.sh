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
add-cron-backup.sh — add/update a cron job for cron-backup-userdata.sh
Reincarnation Backup Kit — MIT License
Copyright (c) 2025 Vladislav Krashevsky with support from ChatGPT
------------------------------------------------------------
Usage:
    sudo ./add-cron-backup.sh HH:MM [username]
Description:
    Creates a daily cron backup job
    for the given user and cron-backup-userdata.sh
=============================================================
DOC

set -euo pipefail

# Стандартная библиотека REBK
# --- Определяем BIN_DIR относительно скрипта ---
BIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Путь к библиотекам всегда относительно BIN_DIR
LIB_DIR="$BIN_DIR/lib"

# source "$(dirname "$0")/lib/init.sh"

source "$LIB_DIR/i18n.sh"
init_app_lang

source "$LIB_DIR/logging.sh"       # error / die
source "$LIB_DIR/user_home.sh"     # resolve_target_home
source "$LIB_DIR/real_user.sh"     # resolve_real_user
source "$LIB_DIR/privileges.sh"    # require_root
source "$LIB_DIR/context.sh"       # контекст выполнения
source "$LIB_DIR/guards-inhibit.sh"
source "$LIB_DIR/cleanup.sh"

if ! TARGET_HOME="$(resolve_target_home)"; then
    die "Cannot determine target home"
fi

if ! REAL_USER="$(resolve_real_user)"; then
    die "Cannot determine real user"
fi

require_root || return 1

# --- Args ---
if [[ $# -lt 1 ]]; then
    echo_msg usage "$0" >&2
    exit 1
fi

TIME="$1"
BACKUP_DIR="/mnt/backups"
mkdir -p "$BACKUP_DIR"

if ! [[ "$TIME" =~ ^([01]?[0-9]|2[0-3]):([0-5][0-9])$ ]]; then
    error invalid_format
    exit 1
fi
HOUR="${TIME%:*}"
MINUTE="${TIME#*:}"

# --- Script path ---
SCRIPT_PATH="$(realpath "$(dirname "$0")/cron-backup-userdata.sh")"
if [[ ! -x "$SCRIPT_PATH" ]]; then
    error script_error
    exit 1
fi

LOG_DIR="$BACKUP_DIR/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/backup-userdata_${REAL_USER}_$(date +%F).log"

CRON_LINE="$MINUTE $HOUR * * * ionice -c2 -n7 nice -n10 "$SCRIPT_PATH" "$REAL_USER" >> "$LOG_FILE" 2>&1"

CURRENT_CRON=$(crontab -l 2>/dev/null || true)
NEW_CRON=$(echo "$CURRENT_CRON" | grep -v "$SCRIPT_PATH" || true)
NEW_CRON="$NEW_CRON"$'\n'"$CRON_LINE"
NEW_CRON=$(echo "$NEW_CRON" | sed '/^$/d')
echo "$NEW_CRON" | crontab -

ok cron_task "$REAL_USER"
info current_jobs
crontab -l

run_cron_test() {
   /usr/bin/ionice -c2 -n7 /usr/bin/nice -n10 "$SCRIPT_PATH" "$REAL_USER" >> "$LOG_FILE" 2>&1
}

info run_test

if run_cron_test; then
    ok test_done "$LOG_FILE"
else
    error test_failed "$LOG_FILE"
    return 1
fi

exit 0