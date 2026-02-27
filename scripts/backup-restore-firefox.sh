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
:<<'DOC'
backup-restore-firefox.sh - 
Reincarnation Backup Kit — MIT License
Copyright (c) 2025 Vladislav Krashevsky with support from ChatGPT
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

# Библиотека Firefox
source "$LIB_DIR/guards-firefox.sh"

# -------------------------------------------------------------
# Firefox backup / restore (REBK)
# -------------------------------------------------------------

BACKUP_ROOT="$TARGET_HOME/backups/REBK/firefox"
PROFILE_BACKUP_DIR="$BACKUP_ROOT/profile"

detect_firefox_base() {
    local paths=(
        "$REAL_HOME/snap/firefox/common/.mozilla/firefox"
        "$REAL_HOME/.mozilla/firefox"
        "$REAL_HOME/.var/app/org.mozilla.firefox/.mozilla/firefox"
    )

    for p in "${paths[@]}"; do
        if [[ -f "$p/profiles.ini" ]]; then
            echo "$p"
            return 0
        fi
    done

    return 1
}

FIREFOX_BASE="$(detect_firefox_base)" || {
    error msg_firefox_not_ini
    read -rp "$(echo_msg menu_firefox_return)"
    exit 0
}

PROFILES_INI="$FIREFOX_BASE/profiles.ini"


DATE_TAG="$(date +%Y-%m)"
ARCHIVE_NAME="firefox-profile-$DATE_TAG.tar.gz"

# -------------------------------------------------------------
require_not_running() {
    if firefox_is_running; then
        error msg_firefox_running
        return 1
    fi
    return 0
}

# -------------------------------------------------------------
detect_default_profile() {
    [[ -f "$PROFILES_INI" ]] || {
        error msg_firefox_not_ini 
        return 1
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

    # --- guard: Firefox не должен быть запущен ---
    set +e
    require_not_running
    local rr=$?
    set -e

    if [[ $rr -ne 0 ]]; then
        read -rp "$(echo_msg menu_firefox_return)"
        return 0
    fi

    # --- определение профиля ---
    set +e
    local profile_rel
    profile_rel="$(detect_default_profile)"
    local dr=$?
    set -e

    if [[ $dr -ne 0 ]]; then
        read -rp "$(echo_msg menu_firefox_return)"
        return 0
    fi

    local profile_path="$FIREFOX_BASE/$profile_rel"

    if [[ ! -d "$profile_path" ]]; then
        error msg_firefox_not_profile "$profile_path"
        read -rp "$(echo_msg menu_firefox_return)"
        return 0
    fi

    mkdir -p "$PROFILE_BACKUP_DIR"

    info msg_firefox_archiving

    # --- критическая операция ---
    set +e
    tar -czf "$PROFILE_BACKUP_DIR/$ARCHIVE_NAME" "$profile_path"
    local tr=$?
    set -e

    if [[ $tr -ne 0 ]]; then
        error msg_firefox_tar_failed
        read -rp "$(echo_msg menu_firefox_return)"
        return 0
    fi

    info msg_firefox_done
    info msg_firefox_profile_archive "$PROFILE_BACKUP_DIR/$ARCHIVE_NAME"

    read -rp "$(echo_msg menu_firefox_return)"
}


# -------------------------------------------------------------
restore_firefox_profile() {

    # --- guard: Firefox не должен быть запущен ---
    set +e
    require_not_running
    local rr=$?
    set -e

    if [[ $rr -ne 0 ]]; then
        read -rp "$(echo_msg menu_firefox_return)"
        return 0
    fi

    info msg_firefox_available
    ls -1 "$PROFILE_BACKUP_DIR"

    echo
    read -rp "$(echo_msg msg_firefox_enter_name)" archive

    local archive_path="$PROFILE_BACKUP_DIR/$archive"

    if [[ ! -f "$archive_path" ]]; then
        error msg_firefox_not_found
        read -rp "$(echo_msg menu_firefox_return)"
        return 0
    fi

    info msg_firefox_recovering

    # --- критическая операция ---
    set +e
    tar -xzf "$archive_path" -C /
    local tr=$?
    set -e

    if [[ $tr -ne 0 ]]; then
        error msg_firefox_tar_failed
        read -rp "$(echo_msg menu_firefox_return)"
        return 0
    fi

    info msg_firefox_recovered
    info msg_firefox_open

    read -rp "$(echo_msg menu_firefox_return)"
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
# Если скрипт запущен напрямую
# -------------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    # Если передано имя функции, вызываем её
    if [[ $# -ge 1 ]]; then
        func="$1"
        if declare -f "$func" > /dev/null; then
            "$func"
        else
            echo "Function '$func' not found"
            exit 1
        fi
    else
        # Иначе запускаем меню
        menu
    fi
fi

