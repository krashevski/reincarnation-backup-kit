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
restore-userdata.sh v2.0 — Backup Kit Safe Restore
Reincarnation Backup Kit — MIT License
Copyright (c) 2025 Vladislav Krashevsky with support from ChatGPT
------------------------------------------------------------
Features:
- Correctly displays localized messages
- Guaranteed to initiate a safe restore (SAFE=1)
- Checks both backup directories separately
- Logging and progress are the same as backup-restore-userdata.sh
======================================================================
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

# === Пути ===
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
RESTORE_SCRIPT="$SCRIPT_DIR/backup-restore-userdata.sh"
BACKUP_DIR="${BACKUP_DIR:-/mnt/backups/REBK}"
BR_WORKDIR="$BACKUP_DIR/bares_workdir"
USERDATA_DIR="$BR_WORKDIR/user_data"
ARCHIVE_DIR="$BR_WORKDIR/tar_archive"
LOG_DIR="$BACKUP_DIR/logs"
mkdir -p "$BACKUP_DIR" "$USERDATA_DIR" "$ARCHIVE_DIR" "$LOG_DIR"
RUN_LOG="$LOG_DIR/res-userdata-$(date +%F-%H%M%S).log"

# === Проверка скрипта ===
if [[ ! -x "$RESTORE_SCRIPT" ]]; then
    error resud_no_script "$RESTORE_SCRIPT"
    exit 1
fi

# === Проверка каталогов резервных копий ===
backup_ok=true
for dir in "$USERDATA_DIR" "$ARCHIVE_DIR"; do
    if [[ ! -d "$dir" ]]; then
        error resud_no_dir "$dir"
        backup_ok=false
    fi
done
$backup_ok || exit 1

echo "=============================================================" | tee -a "$RUN_LOG"

# === Запуск восстановления ===
info resud_recovery_info

# Перенаправляем вывод в лог с прогрессом
if SAFE=1 FORCE_COLOR=1 sudo -E bash "$RESTORE_SCRIPT" restore "$@" \
    > >(tee -a "$RUN_LOG") 2>&1; then
    ok resud_recovery_finished
else
    warn resud_recovery_warnings "$RUN_LOG"
    exit 0 
fi

echo "=============================================================" | tee -a "$RUN_LOG"

exit 0