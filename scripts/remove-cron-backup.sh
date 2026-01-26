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
# 2. Объявляем ассоциативный массив MSG (будет расширяться при source)
# -------------------------------------------------------------
declare -A MSG

# -------------------------------------------------------------
# 3. Функция загрузки сообщений
# -------------------------------------------------------------
load_messages() {
    local lang="$1"
    # очищаем предыдущие ключи
    MSG=()

    case "$lang" in
        ru)
            source "$SCRIPT_DIR/i18n/messages_ru.sh"
            ;;
        en)
            source "$SCRIPT_DIR/i18n/messages_en.sh"
            ;;
        *)
            echo "Unknown language: $lang" >&2
            return 1
            ;;
    esac
}

# -------------------------------------------------------------
# 4. Безопасный say
# -------------------------------------------------------------
say() {
    local key="$1"; shift
    local msg="${MSG[${key}]:-$key}"

    if [[ $# -gt 0 ]]; then
        printf "$msg\n" "$@"
    else
        printf '%s\n' "$msg"
    fi
}


# -------------------------------------------------------------
# 5. Kjuuth ok
# -------------------------------------------------------------
ok() {
    local key="$1"; shift
    local fmt
    fmt="$(say "$key")"
    printf "%b[OK]%b %b\n" \
        "${GREEN:-}" \
        "${NC:-}" \
        "$(printf "$fmt" "$@")"
}


# -------------------------------------------------------------
# 6. Функция info для логирования
# -------------------------------------------------------------
info() {
    local key="$1"; shift
    local fmt
    fmt="$(say "$key")"
    printf "%b[INFO]%b %b\n" \
        "${BLUE:-}" \
        "${NC:-}" \
        "$(printf "$fmt" "$@")" >&2
}


# -------------------------------------------------------------
# 7. Функция warn для логирования
# -------------------------------------------------------------
warn() {
    local key="$1"; shift
    local fmt
    fmt="$(say "$key")"
    printf "%b[WARN]%b %b\n" \
        "${YELLOW:-}" \
        "${NC:-}" \
        "$(printf "$fmt" "$@")" >&2
}

# -------------------------------------------------------------
# 8. Функция error для логирования
# -------------------------------------------------------------
error() {
    local key="$1"; shift
    local fmt
    fmt="$(say "$key")"
    printf "%b[ERROR]%b %b\n" \
        "${RED:-}" \
        "${NC:-}" \
        "$(printf "$fmt" "$@")" >&2
}


# -------------------------------------------------------------
# 9. Функция echo_echo_msg для логирования
# -------------------------------------------------------------
echo_msg() {
    local key="$1"; shift
    local fmt
    fmt="$(say "$key")"
    printf "%b\n" "$(printf "$fmt" "$@")"
}

# -------------------------------------------------------------
# 10. Функция die для логирования
# -------------------------------------------------------------
die() {
    error "$@"
    exit 1
}

# -------------------------------------------------------------
# 11. Устанавливаем язык по умолчанию и загружаем переводы
# -------------------------------------------------------------
LANG_CODE="${LANG_CODE:-ru}"
load_messages "$LANG_CODE"

# --- Проверка root только для команд, где нужны права ---
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
  echo "-----"

  new_root_cron=$(printf "%s\n" "$root_cron" | grep -vF "$SCRIPT_PATH" | grep -vF "$SCRIPT_BASENAME" || true)

  update_crontab_from_var "root" "$new_root_cron"

  echo "-----"
  ecdho_msg after
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

