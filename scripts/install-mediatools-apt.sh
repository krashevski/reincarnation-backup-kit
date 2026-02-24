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
:<<'DOC'
install-mediatools-apt.sh — APT-based multimedia tools installer
VLC, DigiKam, Darktable, KeePassXC, Telegram-desktop, Midnight Commander, ranger, CPU-X
Reincarnation Backup Kit — MIT License
Copyright (c) 2025 Vladislav Krashevsky with support from ChatGPT
DOC

set -euo pipefail

# Стандартная библиотека REBK
# --- Определяем BIN_DIR относительно скрипта ---
BIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Путь к библиотекам всегда относительно BIN_DIR
LIB_DIR="$BIN_DIR/lib"

# source "$(dirname "$0")/lib/init.sh"

source "$LIB_DIR/i18n.sh"
init_app_lang

source "$LIB_DIR/logging.sh"       # error / die
source "$LIB_DIR/user_home.sh"     # resolve_target_home
source "$LIB_DIR/real_user.sh"     # resolve_real_user
source "$LIB_DIR/privileges.sh"    # require_root
source "$LIB_DIR/context.sh"       # контекст выполнения
source "$LIB_DIR/guards-inhibit.sh"
source "$LIB_DIR/cleanup.sh"

if ! TARGET_HOME="$(resolve_target_home)"; then
    die "Cannot determine target home"
fi

if ! REAL_USER="$(resolve_real_user)"; then
    die "Cannot determine real user"
fi

require_root || return 1
# inhibit_run "$0" "$@"

info apt_start

# --- Очистка сторонних репозиториев ---
info apt_clean_repos
for file in /etc/apt/sources.list.d/*; do
    if [[ -f "$file" && "$(basename "$file")" != "ubuntu.sources" ]]; then
        info apt_deleting "$file"
        sudo rm -f "$file"
    fi
done
info apt_done_repos

# Обработка блокировки apt перед запуском
if sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; then
    exit 10
fi

# --- Обновление и установка пакетов ---
info apt_install_packages
sudo apt update
sudo apt install -y vlc digikam darktable keepassxc mc ranger cpu-x
sudo snap install telegram-desktop

ok apt_done