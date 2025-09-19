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
check-shotcut-gpu.sh v1.0 — Проверка Flatpak Shotcut с GPU/NVENC/OpenGL
Automatic NVIDIA detection, CUDA, GPU passthrough, NVENC test
Author: Vladislav Krashevsky
=============================================================
DOC

set -euo pipefail

# === Двуязычные сообщения ===
declare -A MSG=(
  [ru_start]="Старт проверки Shotcut GPU/NVENC/OpenGL"
  [en_start]="Starting Shotcut GPU/NVENC/OpenGL check"

  [ru_nvidia_detect]="Проверка NVIDIA GPU..."
  [en_nvidia_detect]="Checking for NVIDIA GPU..."

  [ru_nvidia_found]="NVIDIA GPU обнаружена."
  [en_nvidia_found]="NVIDIA GPU detected."

  [ru_driver_missing]="Драйвер NVIDIA не установлен, устанавливаем..."
  [en_driver_missing]="NVIDIA driver not installed, installing..."

  [ru_driver_ok]="Драйвер NVIDIA работает."
  [en_driver_ok]="NVIDIA driver works."

  [ru_cuda_missing]="CUDA Toolkit не найден, устанавливаем..."
  [en_cuda_missing]="CUDA Toolkit not found, installing..."

  [ru_cuda_ok]="CUDA Toolkit найден."
  [en_cuda_ok]="CUDA Toolkit found."

  [ru_nvidia_warn]="Драйвер NVIDIA не работает корректно."
  [en_nvidia_warn]="NVIDIA driver not working properly."

  [ru_no_gpu]="NVIDIA GPU не обнаружена."
  [en_no_gpu]="No NVIDIA GPU detected."

  [ru_flatpak_check]="Проверка Flatpak..."
  [en_flatpak_check]="Checking Flatpak..."

  [ru_flathub_add]="Добавляем Flathub репозиторий..."
  [en_flathub_add]="Adding Flathub repository..."

  [ru_gpu_passthrough]="Проброс GPU и кодеков для Shotcut Flatpak..."
  [en_gpu_passthrough]="Passing GPU and codecs to Shotcut Flatpak..."

  [ru_opengl_check]="Проверка OpenGL..."
  [en_opengl_check]="Checking OpenGL..."

  [ru_opengl_ok]="OpenGL доступен внутри Flatpak Shotcut"
  [en_opengl_ok]="OpenGL available inside Flatpak Shotcut"

  [ru_opengl_warn]="OpenGL GPU недоступен внутри Flatpak Shotcut."
  [en_opengl_warn]="OpenGL GPU not available inside Flatpak Shotcut."

  [ru_nvenc_check]="Проверка NVENC кодеков через ffmpeg..."
  [en_nvenc_check]="Checking NVENC encoders via ffmpeg..."

  [ru_nvenc_ok]="NVENC доступен"
  [en_nvenc_ok]="NVENC available"

  [ru_nvenc_warn]="NVENC недоступен."
  [en_nvenc_warn]="NVENC not available"

  [ru_4k_test]="Запуск тестового экспорта 4K видео через NVENC..."
  [en_4k_test]="Running test 4K export via NVENC..."

  [ru_4k_skip]="Тестовый экспорт 4K пропущен (GPU/NVENC недоступен)."
  [en_4k_skip]="4K test export skipped (GPU/NVENC unavailable)."

  [ru_4k_ok]="Тестовое 4K видео создано"
  [en_4k_ok]="Test 4K video created"

  [ru_done]="Проверка завершена"
  [en_done]="Check completed"
)

L=${LANG_CHOICE:-ru}
say() { echo -e "${MSG[${L}_$1]}" "${2:-}"; }

# === Цвета ===
RED="\033[0;31m"; GREEN="\033[0;32m"; BLUE="\033[0;34m"; YELLOW="\033[1;33m"; NC="\033[0m"
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

# --- systemd-inhibit ---
if [[ -z "${INHIBIT_LOCK:-}" ]]; then
    export INHIBIT_LOCK=1
    exec systemd-inhibit --what=handle-lid-switch:sleep:idle --why="$(say start)" "$0" "$@"
fi

# --- Настройки ---
BACKUP_DIR="/mnt/backups"
WORKDIR="$BACKUP_DIR/workdir"
LOG_DIR="$BACKUP_DIR/logs"
LOG_FILE="$LOG_DIR/check-shotcut-gpu.log"
mkdir -p "$WORKDIR" "$LOG_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

info "$(say start)"

GPU_AVAILABLE=false
NVENC_AVAILABLE=false

# --- NVIDIA ---
info "$(say nvidia_detect)"
if lspci | grep -i nvidia &>/dev/null; then
    info "$(say nvidia_found)"
    if ! command -v nvidia-smi &>/dev/null; then
        info "$(say driver_missing)"
        sudo ubuntu-drivers autoinstall
    fi
    if nvidia-smi &>/dev/null; then
        ok "$(say driver_ok)"
        GPU_AVAILABLE=true
        if ! command -v nvcc &>/dev/null; then
            warn "$(say cuda_missing)"
            sudo apt update
            sudo apt install -y nvidia-cuda-toolkit
        else
            ok "$(say cuda_ok)"
        fi
    else
        warn "$(say nvidia_warn)"
    fi
else
    info "$(say no_gpu)"
fi

# --- Flatpak ---
info "$(say flatpak_check)"
if ! command -v flatpak &>/dev/null; then
    info "Installing flatpak..."
    sudo apt update
    sudo apt install -y flatpak
fi
if ! flatpak remotes | grep -q flathub; then
    info "$(say flathub_add)"
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

# --- GPU passthrough & env ---
info "$(say gpu_passthrough)"
LD_LIBRARY_PATH="/usr/lib/nvidia:${LD_LIBRARY_PATH:-}"
LIBGL_DRIVERS_PATH="/usr/lib/x86_64-linux-gnu/dri:${LIBGL_DRIVERS_PATH:-}"
flatpak override --user --env=LD_LIBRARY_PATH="$LD_LIBRARY_PATH" org.shotcut.Shotcut || true
flatpak override --user --env=LIBGL_DRIVERS_PATH="$LIBGL_DRIVERS_PATH" org.shotcut.Shotcut || true
flatpak override --user --device=all org.shotcut.Shotcut || true

# --- OpenGL check ---
info "$(say opengl_check)"
OPENGL_RENDERER=$(flatpak run --command=glxinfo org.shotcut.Shotcut 2>/dev/null | grep "OpenGL renderer" || true)
if [ -n "$OPENGL_RENDERER" ]; then
    ok "$(say opengl_ok): $OPENGL_RENDERER"
else
    warn "$(say opengl_warn)"
fi

# --- NVENC check ---
info "$(say nvenc_check)"
NVENC_LIST=$(flatpak run --command=ffmpeg org.shotcut.Shotcut -hide_banner -encoders | grep nvenc || true)
if [ -n "$NVENC_LIST" ]; then
    ok "$(say nvenc_ok): $NVENC_LIST"
    NVENC_AVAILABLE=true
else
    warn "$(say nvenc_warn)"
fi

# --- Test 4K export ---
if $GPU_AVAILABLE && $NVENC_AVAILABLE; then
    info "$(say 4k_test)"
    TMP_VIDEO="$HOME/shotcut_test_4k.mp4"
    ffmpeg -f lavfi -i testsrc=duration=2:size=3840x2160:rate=30 \
           -c:v h264_nvenc -b:v 5000k -y "$TMP_VIDEO"
    if [ -f "$TMP_VIDEO" ]; then
        ok "$(say 4k_ok): $TMP_VIDEO"
        rm -f "$TMP_VIDEO"
    else
        warn "Test 4K export failed."
    fi
else
    info "$(say 4k_skip)"
fi

info "$(say done): $LOG_FILE"

