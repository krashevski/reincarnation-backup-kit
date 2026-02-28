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
# check-cuda-tools.sh — проверка и управление CUDA Toolkit
# Reincarnation Backup Kit — MIT License
# Copyright (c) 2025 Vladislav Krashevsky
# =============================================================

set -euo pipefail

# --- Пути к библиотекам ---
BIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$BIN_DIR/lib"

# --- Подключение библиотек ---
source "$LIB_DIR/i18n.sh"
init_app_lang

source "$LIB_DIR/logging.sh"
source "$LIB_DIR/user_home.sh"
source "$LIB_DIR/real_user.sh"
source "$LIB_DIR/privileges.sh"
source "$LIB_DIR/context.sh"

if ! TARGET_HOME="$(resolve_target_home)"; then
    die "Cannot determine target home"
fi

if ! REAL_USER="$(resolve_real_user)"; then
    die "Cannot determine real user"
fi

# root / inhibit здесь не используем
# require_root || return 1
# inhibit_run "$0" "$@"

ACTION="${1:-}"

case "$ACTION" in
    install)
        info cuda_install
        sudo apt update
        sudo apt install -y nvidia-cuda-toolkit
        ;;
    remove)
        info cuda_remove
        sudo apt remove -y nvidia-cuda-toolkit
        ;;
    check)
        if command -v nvcc &>/dev/null; then
           info cuda_present
           exit 0
        else
           warn cuda_missing
           exit 1
        fi
        ;;
    *)
        echo "Usage: $0 {install|remove|check}"
        return 1 2>/dev/null || exit 1
        ;;
esac

exit 0