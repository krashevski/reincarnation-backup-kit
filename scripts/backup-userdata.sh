#!/bin/bash
# =============================================================
# Reincarnation Backup Kit — MIT License
# Copyright (c) 2025 Vladislav Krashevsky
# Wrapper: backup-userdata.sh
# -------------------------------------------------------------
# Обёртка для резервного копирования пользовательских данных
# Вызов реального скрипта backup-restore-userdata.sh с аргументом "backup"
# Дополнительные параметры (например, --fresh) передаются далее.
# =============================================================

set -euo pipefail

# --- Цвета ---
RED="\033[0;31m"; GREEN="\033[0;32m"; YELLOW="\033[1;33m"; BLUE="\033[0;34m"; NC="\033[0m"
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

# === Язык ===
LANG_CHOICE="${LANG_CHOICE:-ru}"  # можно менять извне
declare -A MSG_RU MSG_EN
MSG_RU=(
    [run_sudo]="Скрипт нужно запускать с правами root (sudo)"
)
MSG_EN=(
    [run_sudo]="The script must be run with root rights (sudo)"
)
say() {
    local key="$1"
    case "$LANG_CHOICE" in
        ru) echo "${MSG_RU[$key]}" ;;
        en) echo "${MSG_EN[$key]}" ;;
        *) echo "${MSG_EN[$key]}" ;; # по умолчанию EN
    esac
}

# --- Проверка root только для команд, где нужны права ---
require_root() {
    if [[ $EUID -ne 0 ]]; then
        error "$(say run_sudo)"
        return 1
    fi
}

SCRIPT_DIR="$(dirname "$0")"
exec "$SCRIPT_DIR/backup-restore-userdata.sh" backup "$@"

