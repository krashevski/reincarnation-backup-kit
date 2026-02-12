#!/usr/bin/env bash
# =============================================================
# context.sh — определение пользовательского контекста REBK
# -------------------------------------------------------------
# Использование context.sh
# в каждом скрипте
:<<'DOC'
source "$LIB_DIR/context.sh"
DOC

set -o errexit
set -o pipefail

# защита от повторного подключения
[[ -n "${_REBK_CONTEXT_LOADED:-}" ]] && return 0
_REBK_CONTEXT_LOADED=1


# -------------------------------------------------------------
# REAL_HOME: домашний каталог RUN_USER
# -------------------------------------------------------------
if [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != "root" ]]; then
    REAL_HOME="/home/$SUDO_USER"
else
    REAL_HOME="${HOME:-/home/$USER}"
fi

export REAL_HOME
