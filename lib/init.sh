#!/usr/bin/env bash
# =============================================================
# REBKJ/lib/init.sh — единый файл инициализации общих скриптов для REBK
# -------------------------------------------------------------
# Использование init.sh
:<<'DOC'
source "$(dirname "$0")/lib/init.sh"
DOC

# 1. Защита от повторной инициализации
[[ -n "${_GITSEC_INIT_LOADED:-}" ]] && return 0
_GITSEC_INIT_LOADED=1

# 2. Подключение общего lib (shared-lib)
SHARED_LIB="$HOME/scripts/shared-lib"

if [[ -f "$SHARED_LIB/lib/init_core.sh" ]]; then
    source "$SHARED_LIB/lib/init_core.sh" # logging, net, context
else
    echo "[FATAL] shared-lib not found: $SHARED_LIB/lib/init_core.sh"
    exit 1
fi

# 3. Структура проекта
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
BIN_DIR="$BASE_DIR/bin"
STATE_DIR="$BASE_DIR/state"
LOGS_DIR="$BASE_DIR/logs"
RUN_LOG="$LOGS_DIR/lib/git-security.log"
LIB_DIR="$SHARED_LIB"
export BASE_DIR BIN_DIR STATE_DIR LOGS_DIR RUN_LOG LIB_DIR

# 4. Базовые библиотеки
source "$LIB_DIR/lib/user_home.sh"
source "$LIB_DIR/logging.sh"
source "$LIB_DIR/safety.sh"
source "$LIB_DIR/privileges.sh"
source "$LIB_DIR/context.sh"
source "$LIB_DIR/guards-inhibit.sh"

# 5. Общие traps (если нужно)
# source "$LIB_DIR/cleanup.sh"
# trap cleanup EXIT

# 6. Подключение i18n (опционально)
if [[ -f "$SHARED_LIB/lib/i18n.sh" ]]; then
    source "$SHARED_LIB/lib/i18n.sh"
    command -v init_app_lang >/dev/null && init_app_lang
fi