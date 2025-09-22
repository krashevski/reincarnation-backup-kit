#!/bin/bash
# =============================================================
# Reincarnation Backup Kit — MIT License
# Copyright (c) 2025 Vladislav Krashevsky
# Wrapper: backup-system.sh
# -------------------------------------------------------------
# Обёртка для системного бэкапа (Ubuntu 24.04)
# Автоматически вызывает подходящий скрипт backup-<distro>-<version>.sh
# =============================================================

set -euo pipefail

# === Определение языка ===
if [[ "${LANG:-}" == ru* ]]; then
    LANG_MODE="ru"
else
    LANG_MODE="en"
fi

# === Цвета ===
RED="\033[0;31m"; GREEN="\033[0;32m"; BLUE="\033[0;34m"; NC="\033[0m"
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

# --- systemd-inhibit ---
if [[ -z "${INHIBIT_LOCK:-}" ]]; then
    export INHIBIT_LOCK=1
    exec systemd-inhibit --what=handle-lid-switch:sleep:idle --why="Running system backup" "$0" "$@"
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

