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
check-shotcut-gpu.sh — automatic NVIDIA detection, CUDA, GPU passthrough, NVENC test
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
inhibit_run "$0" "$@"

# --- Настройки ---
BACKUP_DIR="/mnt/backups/REBK"
WORKDIR="$BACKUP_DIR/workdir"
LOG_DIR="$BACKUP_DIR/logs"
RUN_LOG="$LOG_DIR/check-shotcut-gpu.log"
mkdir -p "$WORKDIR" "$LOG_DIR"
exec > >(tee -a "$RUN_LOG") 2>&1

info gpu_start

GPU_AVAILABLE=false
NVENC_AVAILABLE=false

# --- NVIDIA ---
info gpu_nvidia_detect
if lspci | grep -i nvidia &>/dev/null; then
    info gpu_nvidia_found
    if ! command -v nvidia-smi &>/dev/null; then
        info gpu_driver_missing
        sudo ubuntu-drivers autoinstall
    fi
    if nvidia-smi &>/dev/null; then
        ok gpu_driver_ok
        GPU_AVAILABLE=true
        if ! command -v nvcc &>/dev/null; then
            warn gpu_cuda_missing
            sudo apt update
            sudo apt install -y nvidia-cuda-toolkit
        else
            ok gpu_cuda_ok
        fi
    else
        warn gpu_nvidia_warn
    fi
else
    info gpu_no_gpu
fi

# --- Flatpak ---
info gpu_flatpak_check
if ! command -v flatpak &>/dev/null; then
    info gpu_flatpak_install
    sudo apt update
    sudo apt install -y flatpak
fi
if ! flatpak remotes | grep -q flathub; then
    info gpu_flathub_add
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

# --- GPU passthrough & env ---
info gpu_passthrough
LD_LIBRARY_PATH="/usr/lib/nvidia:${LD_LIBRARY_PATH:-}"
LIBGL_DRIVERS_PATH="/usr/lib/x86_64-linux-gnu/dri:${LIBGL_DRIVERS_PATH:-}"
flatpak override --user --env=LD_LIBRARY_PATH="$LD_LIBRARY_PATH" org.shotcut.Shotcut || true
flatpak override --user --env=LIBGL_DRIVERS_PATH="$LIBGL_DRIVERS_PATH" org.shotcut.Shotcut || true
flatpak override --user --device=all org.shotcut.Shotcut || true

# --- OpenGL check ---
info gpu_opengl_check
OPENGL_RENDERER=$(flatpak run --command=glxinfo org.shotcut.Shotcut 2>/dev/null | grep "OpenGL renderer" || true)
if [ -n "$OPENGL_RENDERER" ]; then
    ok gpu_opengl_ok $OPENGL_RENDERER
else
    warn gpu_opengl_warn
fi

# --- NVENC check ---
info gpu_nvenc_check
NVENC_LIST=$(flatpak run --command=ffmpeg org.shotcut.Shotcut -hide_banner -encoders | grep nvenc || true)
if [ -n "$NVENC_LIST" ]; then
    ok gpu_nvenc_ok $NVENC_LIST
    NVENC_AVAILABLE=true
else
    warn gpu_nvenc_warn
fi

# --- Test 4K export ---
if $GPU_AVAILABLE && $NVENC_AVAILABLE; then
    info gpu_4k_test
    TMP_VIDEO="$HOME/shotcut_test_4k.mp4"
    ffmpeg -f lavfi -i testsrc=duration=2:size=3840x2160:rate=30 \
           -c:v h264_nvenc -b:v 5000k -y "$TMP_VIDEO"
    if [ -f "$TMP_VIDEO" ]; then
        ok gpu_4k_ok $TMP_VIDEO
        rm -f "$TMP_VIDEO"
    else
        warn gpu_4k_failed
    fi
else
    info gpu_4k_skip
fi

info gpu_done $RUN_LOG