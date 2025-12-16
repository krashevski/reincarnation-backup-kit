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
# Reincarnation Backup Kit — MIT License
# Copyright (c) 2025 Vladislav Krashevsky with support from ChatGPT
# Wrapper: backup-system.sh
# -------------------------------------------------------------
# Обёртка для системного бэкапа (Ubuntu 24.04)
# Автоматически вызывает подходящий скрипт backup-<distro>-<version>.sh
# =============================================================

set -euo pipefail

# --- systemd-inhibit ---
if [[ -z "${INHIBIT_LOCK:-}" ]]; then
    export INHIBIT_LOCK=1
    exec systemd-inhibit --what=handle-lid-switch:sleep:idle --why="Running system backup" "$0" "$@"
fi

# === Цвета ===
RED="\033[0;31m"; GREEN="\033[0;32m"; BLUE="\033[0;34m"; NC="\033[0m"
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

require_root() {
    if [[ $EUID -ne 0 ]]; then
        error "Root privileges required!"
        return 1
    fi
}

# === Определение языка ===
if [[ "${LANG:-}" == ru* ]]; then
    LANG_MODE="ru"
else
    LANG_MODE="en"
fi

# === Сообщения ===
declare -A MSG
if [[ $LANG_MODE == "ru" ]]; then
    MSG[distro_found]="Обнаружен дистрибутив"
    MSG[no_script]="❌ Нет подходящего скрипта для"
else
    MSG[distro_found]="Detected distribution"
    MSG[no_script]="❌ No backup script found for"
fi

# --- Дистрибутив ---
DISTRO_ID=$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
DISTRO_VER=$(grep '^VERSION_ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
info "${MSG[distro_found]}: $DISTRO_ID $DISTRO_VER"

SCRIPT_DIR="$(dirname "$0")"
TARGET="$SCRIPT_DIR/backup-${DISTRO_ID}-${DISTRO_VER}.sh"

if [[ ! -x "$TARGET" ]]; then
    error "${MSG[no_script]} ${DISTRO_ID}-${DISTRO_VER}"
    exit 1
fi

exec "$TARGET" "$@"

