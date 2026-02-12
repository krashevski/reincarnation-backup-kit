#!/usr/bin/env bash
# =============================================================
# /scripts/lib/init.sh — единый файл инициализации скриптов REBK
# -------------------------------------------------------------
# Использование init.sh
#
# в каждом скрипте
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

# Язык по умолчанию
: "${APP_LANG:=en}"
export APP_LANG

# Общие библиотеки
source "$PROJECT_ROOT/lib/logging.sh"
