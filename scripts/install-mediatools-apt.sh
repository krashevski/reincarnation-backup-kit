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
=============================================================
install-mediatools-apt.sh v1.1 — APT-based multimedia tools installer
VLC, DigiKam, Darktable, KeePassXC, Telegram-desktop, Midnight Commander, ranger, CPU-X
Author: Vladislav Krashevsky (support ChatGPT)
=============================================================
DOC

set -euo pipefail

# === Двуязычные сообщения ===
declare -A MSG=(
  [ru_start]="Старт установки мультимедиа приложений через APT/Snap"
  [en_start]="Starting multimedia applications installation via APT/Snap"

  [ru_clean_repos]="Очистка сторонних репозиториев..."
  [en_clean_repos]="Cleaning 3rd-party repositories..."

  [ru_repos_done]="Репозитории очищены. Обновляем список пакетов..."
  [en_repos_done]="Repositories cleaned. Updating package lists..."

  [ru_install_packages]="Устанавливаем необходимые пакеты..."
  [en_install_packages]="Installing required packages..."

  [ru_done]="Установка завершена!"
  [en_done]="Installation completed!"
)

L=${LANG_CHOICE:-ru}
say() { echo -e "${MSG[${L}_$1]}" "${2:-}"; }

# === Цвета ===
RED="\033[0;31m"; GREEN="\033[0;32m"; BLUE="\033[0;34m"; YELLOW="\033[1;33m"; NC="\033[0m"
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

info "$(say start)"

# --- Очистка сторонних репозиториев ---
info "$(say clean_repos)"
for file in /etc/apt/sources.list.d/*; do
    if [[ -f "$file" && "$(basename "$file")" != "ubuntu.sources" ]]; then
        info "Удаляю $file"
        sudo rm -f "$file"
    fi
done
info "$(say repos_done)"

# --- Обновление и установка пакетов ---
info "$(say install_packages)"
sudo apt update
sudo apt install -y vlc digikam darktable keepassxc mc ranger cpu-x
sudo snap install telegram-desktop

ok "$(say done)"

