#!/usr/bin/env bash
# -------------------------------------------------------------
# /scripts/lib/logging.sh — эталонная библиотека логирования REBK
# -------------------------------------------------------------

set -o errexit
set -o pipefail

# -------------------------------------------------------------
# Цвета
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
# i18n
# -------------------------------------------------------------
declare -Ag MSG

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$LIB_DIR/.." && pwd)"

load_messages() {
    local lang="$1"
    MSG=()
    case "$lang" in
        ru) source "$ROOT_DIR/i18n/messages_ru.sh" ;;
        en) source "$ROOT_DIR/i18n/messages_en.sh" ;;
        *)
            echo "Unknown language: $lang" >&2
            return 1
            ;;
    esac
}

LANG_CODE="${LANG_CODE:-ru}"
load_messages "$LANG_CODE"

say() {
    local key="$1"; shift
    local msg="${MSG[$key]:-$key}"
    [[ $# -gt 0 ]] && printf "$msg" "$@" || printf '%s' "$msg"
}

# -------------------------------------------------------------
# Лог-функции
# -------------------------------------------------------------
: "${RUN_LOG:=/dev/null}"

ok() {
    printf "%b[OK]%b %b\n" "$GREEN" "$NC" "$(say "$@")" | tee -a "$RUN_LOG"
}

info() {
    printf "%b[INFO]%b %b\n" "$BLUE" "$NC" "$(say "$@")" | tee -a "$RUN_LOG"
}

warn() {
    printf "%b[WARN]%b %b\n" "$YELLOW" "$NC" "$(say "$@")" | tee -a "$RUN_LOG" >&2
}

error() {
    printf "%b[ERROR]%b %b\n" "$RED" "$NC" "$(say "$@")" | tee -a "$RUN_LOG" >&2
    return 1
}

die() {
    local code=1
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        code="$1"
        shift
    fi
    error "$@"
    exit "$code"
}
