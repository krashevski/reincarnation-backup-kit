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
install-nvidia-cuda.sh v1.1 — установка драйвера NVIDIA и CUDA
Поддержка: GTX 1650, Ubuntu/Debian
Author: Vladislav + ChatGPT
=============================================================
DOC

set -euo pipefail

# === Двуязычные сообщения ===
declare -A MSG=(
  [ru_update]="Шаг 1: Обновление списка пакетов"
  [en_update]="Step 1: Updating package list"

  [ru_driver_install]="Шаг 2: Автоматическая установка драйвера NVIDIA"
  [en_driver_install]="Step 2: Automatic NVIDIA driver installation"

  [ru_driver_check]="Шаг 3: Проверка, что драйвер установлен"
  [en_driver_check]="Step 3: Checking if NVIDIA driver is installed"

  [ru_driver_error]="Драйвер NVIDIA не найден. Проверьте логи установки."
  [en_driver_error]="NVIDIA driver not found. Check installation logs."

  [ru_modprobe]="Шаг 4: Перезагрузка модулей ядра NVIDIA"
  [en_modprobe]="Step 4: Reloading NVIDIA kernel modules"

  [ru_gpu_info]="Шаг 5: Проверка карты и версии драйвера"
  [en_gpu_info]="Step 5: Checking GPU and driver version"

  [ru_cuda_check]="Шаг 6: Проверка поддержки CUDA"
  [en_cuda_check]="Step 6: Checking CUDA support"

  [ru_cuda_install]="CUDA toolkit не найден, устанавливаем..."
  [en_cuda_install]="CUDA toolkit not found, installing..."

  [ru_cuda_version]="Шаг 7: Проверка версии CUDA"
  [en_cuda_version]="Step 7: Checking CUDA version"

  [ru_cuda_warn]="nvcc не найден. CUDA может работать только через драйвер."
  [en_cuda_warn]="nvcc not found. CUDA may work only via driver."

  [ru_cuda_smi]="Проверка CUDA через nvidia-smi"
  [en_cuda_smi]="Checking CUDA via nvidia-smi"

  [ru_done]="Установка завершена! GPU готов для ускорения Shotcut и 4K"
  [en_done]="Installation completed! GPU ready for Shotcut acceleration and 4K"
)

L=${LANG_CHOICE:-ru}
say() { echo -e "${MSG[${L}_$1]}" "${2:-}"; }

# === Цвета ===
RED="\033[0;31m"; GREEN="\033[0;32m"; BLUE="\033[0;34m"; YELLOW="\033[1;33m"; NC="\033[0m"
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

# --- Логирование ---
LOG_DIR="/mnt/backups/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/install-nvidia-cuda.log"
exec > >(tee -a "$LOG_FILE") 2>&1

# === Шаги ===
info "$(say update)"
sudo apt update

info "$(say driver_install)"
sudo ubuntu-drivers autoinstall

info "$(say driver_check)"
if ! command -v nvidia-smi &>/dev/null; then
    error "$(say driver_error)"
    exit 1
fi
ok "nvidia-smi OK"

info "$(say modprobe)"
sudo modprobe nvidia

info "$(say gpu_info)"
nvidia-smi

info "$(say cuda_check)"
if ! command -v nvcc &>/dev/null; then
    info "$(say cuda_install)"
    sudo apt install -y nvidia-cuda-toolkit
else
    ok "CUDA toolkit found"
fi

info "$(say cuda_version)"
nvcc --version || warn "$(say cuda_warn)"

info "$(say cuda_smi)"
nvidia-smi -q | grep -i "CUDA Version"

ok "$(say done)"

