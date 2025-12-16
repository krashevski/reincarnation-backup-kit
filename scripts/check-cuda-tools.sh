#!/bin/bash
# =============================================================
# check-cuda-tools.sh — Проверка и управление CUDA Toolkit
# Reincarnation Backup Kit — MIT License
# Copyright (c) 2025 Vladislav Krashevsky
# =============================================================

set -euo pipefail

# --- Цвета ---
RED="\033[0;31m"; GREEN="\033[0;32m"; BLUE="\033[0;34m"; YELLOW="\033[1;33m"; NC="\033[0m"
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

# --- Язык ---
LANG_CODE="ru"
[[ "${LANG:-}" == en* ]] && LANG_CODE="en"

declare -A MSG
MSG=(
  [ru_installed]="CUDA Toolkit уже установлен."
  [en_installed]="CUDA Toolkit is already installed."
  [ru_not_installed]="CUDA Toolkit не установлен."
  [en_not_installed]="CUDA Toolkit is not installed."
  [ru_install_prompt]="Хотите установить CUDA Toolkit (~2 ГБ)? y/n: "
  [en_install_prompt]="Do you want to install CUDA Toolkit (~2 GB)? y/n: "
  [ru_remove_prompt]="Хотите удалить CUDA Toolkit? y/n: "
  [en_remove_prompt]="Do you want to remove CUDA Toolkit? y/n: "
  [ru_installing]="Установка CUDA Toolkit..."
  [en_installing]="Installing CUDA Toolkit..."
  [ru_removing]="Удаление CUDA Toolkit..."
  [en_removing]="Removing CUDA Toolkit..."
  [ru_done]="Операция завершена."
  [en_done]="Operation completed."
)

say() { echo -ne "${MSG[${LANG_CODE}_$1]}"; }

# --- Проверка наличия CUDA Toolkit ---
if command -v nvcc &>/dev/null; then
    ok "$(say installed)"
    read -rp "$(say remove_prompt)" resp
    if [[ "$resp" =~ ^[Yy]$ ]]; then
        info "$(say removing)"
        sudo apt remove --purge -y nvidia-cuda-toolkit
        sudo apt autoremove -y
        ok "$(say done)"
    else
        info "CUDA Toolkit сохранён."
    fi
else
    warn "$(say not_installed)"
    read -rp "$(say install_prompt)" resp
    if [[ "$resp" =~ ^[Yy]$ ]]; then
        info "$(say installing)"
        sudo apt update
        sudo apt install -y nvidia-cuda-toolkit
        ok "$(say done)"
    else
        info "CUDA Toolkit не установлен."
    fi
fi

exit 0


