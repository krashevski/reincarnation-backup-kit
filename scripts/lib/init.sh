#!/usr/bin/env bash
# =============================================================
# /scripts/lib/init.sh — единый файл инициализации скриптов REBK
# -------------------------------------------------------------
# Использование init.sh
:<<'DOC'
source "$(dirname "$0")/lib/init.sh"

info start
ok completed
DOC

# Корень проекта (работает и при прямом запуске)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

# -------------------------------------------------------------
# RUN_USER: кто инициировал запуск
# -------------------------------------------------------------
RUN_USER="${SUDO_USER:-$USER}"
export RUN_USER

# -------------------------------------------------------------
# i18n
# -------------------------------------------------------------
source "$PROJECT_ROOT/lib/i18n.sh"
init_app_lang

# Общие библиотеки
source "$PROJECT_ROOT/lib/logging.sh"
