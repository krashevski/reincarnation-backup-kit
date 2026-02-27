#!/usr/bin/env bash
# =============================================================
# /scripts/lib/deps.sh — dependency checks
# Requires: logging.sh
# -------------------------------------------------------------
# Использование deps.sh
#
# SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# LIB_DIR="$SCRIPT_DIR/lib"
#
# LANG_CODE=ru
# export RUN_LOG="/var/log/rebk.log"
# RUN_LOG="$HOME/rebk.log"
# source "$LIB_DIR/logging.sh"
# source "$LIB_DIR/deps.sh"
#
# check_and_install_commands git curl tar pv
# =============================================================

set -o errexit
set -o pipefail

# -------------------------------------------------------------
# Защита от повторного подключения
# -------------------------------------------------------------
[[ -n "${_REBK_DEPS_LOADED:-}" ]] && return 0
_REBK_DEPS_LOADED=1

# -------------------------------------------------------------
# runtime-проверка зависимоси от logging.sh
# -------------------------------------------------------------
type ok >/dev/null 2>&1 || {
    echo "deps.sh requires logging.sh" >&2
    return 1
}

# check_and_install_deps принимает ИМЕНА КОМАНД
check_and_install_commands() {
    local REQUIRED_PKGS=("$@")
    local MISSING_PKGS=()
    local SUDO=""
    [[ ${EUID:-$(id -u)} -ne 0 ]] && SUDO="sudo"

    # --- проверка наличия команд ---
    for pkg in "${REQUIRED_PKGS[@]}"; do
        if ! command -v "$pkg" >/dev/null 2>&1; then
            MISSING_PKGS+=("$pkg")
        fi
    done

    # --- если всё есть ---
    if [ "${#MISSING_PKGS[@]}" -eq 0 ]; then
        ok deps_ok
        return 0
    fi

    warn deps_missing_list "${MISSING_PKGS[*]}"
    info deps_install_try

    # --- определение пакетного менеджера и установка ---
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update
        sudo apt-get install -y "${MISSING_PKGS[@]}"
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y "${MISSING_PKGS[@]}"
    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y "${MISSING_PKGS[@]}"
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -Sy --noconfirm "${MISSING_PKGS[@]}"
    elif command -v zypper >/dev/null 2>&1; then
        sudo zypper install -y "${MISSING_PKGS[@]}"
    else
        die deps_unknown_manager "${MISSING_PKGS[*]}"
    fi

    # --- повторная проверка ---
    for pkg in "${REQUIRED_PKGS[@]}"; do
        if ! command -v "$pkg" >/dev/null 2>&1; then
            error deps_missing "$pkg" || true
            return 1
        fi
    done

    ok deps_ok
}

# -------------------------------------------------------------
# Экспорт say как readonly API
# -------------------------------------------------------------
readonly -f say ok info warn error die
