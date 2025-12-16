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
clean-backup-logs.sh — Remove old logs
Reincarnation Backup Kit — MIT License
Copyright (c) 2025 Vladislav Krashevsky with support from ChatGPT
=============================================================
DOC

LANG_CODE="en"
[[ "${LANG:-}" == ru* ]] && LANG_CODE="ru"

declare -A MSG_RU MSG_EN
MSG_RU=(
  [removing]="Удаляем логи старше %s дней..."
  [done]="Очистка логов завершена."
)
MSG_EN=(
  [removing]="Removing logs older than %s days..."
  [done]="Log cleanup complete."
)
msg() { case "$LANG_CODE" in ru) printf "${MSG_RU[$1]}\n" "${@:2}" ;; en) printf "${MSG_EN[$1]}\n" "${@:2}" ;; esac; }

DAYS="${1:-7}"
LOG_DIR="/mnt/backups/logs"
[[ -d "$LOG_DIR" ]] || exit 0

echo "$(msg removing "$DAYS")"
find "$LOG_DIR" -type f -name "*.log" -mtime +$DAYS -delete
echo "$(msg done)"

