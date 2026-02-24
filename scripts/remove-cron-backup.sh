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
remove-cron-backup.sh — robust removal of cron-backup-userdata.sh entries
Reincarnation Backup Kit — MIT License
Copyright (c) 2025 Vladislav Krashevsky with support from ChatGPT
-------------------------------------------------------------
Detects and removes entries from user crontab and root crontab, prints before/after
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

if ! TARGET_HOME="$(resolve_target_home)"; then
    die "Cannot determine target home"
fi

if ! REAL_USER="$(resolve_real_user)"; then
    die "Cannot determine real user"
fi

require_root || return 1

SCRIPT_BASENAME="cron-backup-userdata.sh"
SCRIPT_PATH="$(realpath "$(dirname "$0")/$SCRIPT_BASENAME")"

# helper to update crontab from variable content (safe)
update_crontab_from_var() {
  # args: <target> <content>
  local target="$1"; shift
  local content="$1"; shift

  local tmp
  tmp="$(mktemp)"
  printf "%s\n" "$content" > "$tmp"

  if [[ "$target" == "root" ]]; then
    if [[ $EUID -eq 0 ]]; then
      crontab "$tmp"
    else
      # use sudo to write root crontab
      sudo crontab "$tmp"
    fi
  else
    # target is username
    if [[ $EUID -eq 0 ]]; then
      crontab -u "$target" "$tmp"
    else
      # can't write another user's crontab without sudo
      sudo crontab -u "$target" "$tmp"
    fi
  fi

  rm -f "$tmp"
}

found_any=0

# 1) Check crontab of the original (non-sudo) user if available
TARGET_USER="${SUDO_USER:-$USER}"

# Try to read user crontab
if user_cron=$(crontab -l -u "$TARGET_USER" 2>/dev/null || true); then
  if echo "$user_cron" | grep -Fq "$SCRIPT_BASENAME" || echo "$user_cron" | grep -Fq "$SCRIPT_PATH"; then
    echo "-----"
    echo_msg before
    echo "$user_cron"
    echo "-----"

    # remove lines containing either the basename or full path
    new_user_cron=$(printf "%s\n" "$user_cron" | grep -vF "$SCRIPT_PATH" | grep -vF "$SCRIPT_BASENAME" || true)
    update_crontab_from_var "$TARGET_USER" "$new_user_cron"

    echo "-----"
    echo_msg after
    crontab -l -u "$TARGET_USER" 2>/dev/null || echo "(empty)"
    echo_msg removed_user "$TARGET_USER"
    found_any=1
    exit 0
  fi
else
  # could not read user crontab (permission), warn but continue
  printf "%s\n" echo_msg err_read "$TARGET_USER" >&2
fi

# 2) Check root crontab
# read root crontab into variable (using sudo only if not root)
if [[ $EUID -eq 0 ]]; then
  root_cron=$(crontab -l 2>/dev/null || true)
else
  root_cron=$(sudo crontab -l 2>/dev/null || true)
fi

if echo "$root_cron" | grep -Fq "$SCRIPT_BASENAME" || echo "$root_cron" | grep -Fq "$SCRIPT_PATH"; then
  echo "-----"
  echo_msg before
  echo "$root_cron"

  new_root_cron=$(printf "%s\n" "$root_cron" | grep -vF "$SCRIPT_PATH" | grep -vF "$SCRIPT_BASENAME" || true)

  update_crontab_from_var "root" "$new_root_cron"

  echo "-----"
  echo_msg after
  if [[ $EUID -eq 0 ]]; then
    crontab -l 2>/dev/null || echo "(empty)"
  else
    sudo crontab -l 2>/dev/null || echo "(empty)"
  fi
  echo_msg removed_root
  found_any=1
  exit 0
fi

# nothing found
echo_msg none
exit 0