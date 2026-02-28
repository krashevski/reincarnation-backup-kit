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
clean-backup-logs.sh — remove old logs
Reincarnation Backup Kit — MIT License
Copyright (c) 2025 Vladislav Krashevsky with support from ChatGPT
DOC

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

DAYS="${1:-7}"
LOG_DIR="/mnt/backups/REBK/logs"
[[ -d "$LOG_DIR" ]] || exit 0

info clean_logs_removing "$DAYS"
find "$LOG_DIR" -type f -name "*.log" -mtime +$DAYS -delete
info clean_logs_done