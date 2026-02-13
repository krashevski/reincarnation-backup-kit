#!/usr/bin/env bash
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
# backup-restore-firefox.sh
# Reincarnation Backup Kit — Text Menu Interface (draft)
# MIT License — Copyright (c) 2025 Vladislav Krashevsky support ChatGPT
# =============================================================

set -euo pipefail

# --- Определяем BIN_DIR относительно скрипта ---
BIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Путь к библиотекам всегда относительно BIN_DIR
LIB_DIR="$BIN_DIR/lib"

source "$LIB_DIR/logging.sh"
source "$LIB_DIR/privileges.sh"
source "$LIB_DIR/context.sh"
source "$LIB_DIR/guards-inhibit.sh"

# inhibit_run "$0" "$@"

# -------------------------------------------------------------
# Firefox backup / restore (REBK)
# -------------------------------------------------------------

BACKUP_ROOT="$HOME/backups/REBK/firefox"
PROFILE_BACKUP_DIR="$BACKUP_ROOT/profile"

FIREFOX_BASE="$HOME/snap/firefox/common/.mozilla/firefox"
PROFILES_INI="$FIREFOX_BASE/profiles.ini"

DATE_TAG="$(date +%Y-%m)"
ARCHIVE_NAME="firefox-profile-$DATE_TAG.tar.gz"

# -------------------------------------------------------------
require_not_running() {
    if pgrep -x firefox >/dev/null; then
        error msg_firefox_close
        exit 1
    fi
}

# -------------------------------------------------------------
detect_default_profile() {
    [[ -f "$PROFILES_INI" ]] || {
        error msg_firefox_not_ini 
        exit 1
    }

    awk '
        /^\[Profile/ { p=0 }
        /^Default=1/ { p=1 }
        p && /^Path=/ {
            sub("Path=", "", $0)
            print $0
            exit
        }
    ' "$PROFILES_INI"
}

# -------------------------------------------------------------
backup_firefox_profile() {
    require_not_running

    local profile_rel
    profile_rel="$(detect_default_profile)"

    local profile_path="$FIREFOX_BASE/$profile_rel"

    [[ -d "$profile_path" ]] || {
        error msg_firefox_not_profile $profile_path
        exit 1
    }

    mkdir -p "$PROFILE_BACKUP_DIR"

    info msg_firefox_archiving 
    echo "   $profile_path"

    tar -czf "$PROFILE_BACKUP_DIR/$ARCHIVE_NAME" "$profile_path"

    info msg_firefox_done
    echo "   $PROFILE_BACKUP_DIR/$ARCHIVE_NAME"
}

# -------------------------------------------------------------
restore_firefox_profile() {
    require_not_running

    info msg_firefox_available
    ls -1 "$PROFILE_BACKUP_DIR"

    echo
    read -rp "$(echo_msg msg_firefox_enter_name)" archive

    local archive_path="$PROFILE_BACKUP_DIR/$archive"

    [[ -f "$archive_path" ]] || {
        error msg_firefox_not_found 
        exit 1
    }

    info msg_firefox_recovering 
    tar -xzf "$archive_path" -C /

    info msg_firefox_recovered 
    info msg_firefox_open 
}

# -------------------------------------------------------------
menu() {
    clear
    echo "---------------------------------------"
    echo_msg menu_firefox_backres
    echo "---------------------------------------"
    echo_msg menu_firefox_backup
    echo_msg menu_firefox_restore
    echo_msg menu_firefox_exit
    echo
    echo "-----------------------------------------"
    read -rp "$(echo_msg menu_firefox_options)" choice

    case "$choice" in
        1) backup_firefox_profile ;;
        2) restore_firefox_profile ;;
        0) exit 0 ;;
        *) warn menu_invalid_choice ;;
    esac
}

# -------------------------------------------------------------
# Проверка: если скрипт запущен напрямую, показываем меню
# -------------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    menu
fi
