#!/usr/bin/env bash
# -------------------------------------------------------------
# /scripts/lib/deps.sh — проверка команд и установка пакетов
# -------------------------------------------------------------

set -o errexit
set -o pipefail

# подключаем логирование и i18n
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/logging.sh"

check_and_install_deps() {
    local REQUIRED_PKGS=("$@")
    local MISSING_PKGS=()

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
        die "unknown_package_manager" "${MISSING_PKGS[*]}"
    fi

    # --- повторная проверка ---
    for pkg in "${REQUIRED_PKGS[@]}"; do
        if ! command -v "$pkg" >/dev/null 2>&1; then
            error "'$pkg' ${MSG[deps_missing]}"
            return 1
        fi
    done

    ok deps_ok
}
