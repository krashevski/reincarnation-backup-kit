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
install_mediatools_flatpak.sh — multimedia environment installer
Ubuntu 24.04: Shotcut, GIMP+G'MIC, Krita, Audacity
Auto-check NVIDIA GPU, CUDA, NVENC, OpenGL, Proxy, Presets
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
BACKUP_DIR="/mnt/backups"
WORKDIR="$BACKUP_DIR/workdir"
LOG_DIR="$BACKUP_DIR/logs"
mkdir -p "$WORKDIR" "$LOG_DIR"
LOG_FILE="$LOG_DIR/install_mediatools.log"

echo "[`date`] flatpak_start" > "$LOG_FILE"

# ----------------- Шаг 0: NVIDIA GPU и CUDA -----------------
GPU_AVAILABLE=false
NVENC_AVAILABLE=false

if lspci | grep -i nvidia &>/dev/null; then
    info flatpak_nvidia_detected | tee -a "$LOG_FILE"
    if ! command -v nvidia-smi &>/dev/null; then
        info flatpak_nvidia_driver_install | tee -a "$LOG_FILE"
        sudo ubuntu-drivers autoinstall
    fi
    if nvidia-smi &>/dev/null; then
        ok flatpak_nvidia_driver_ok | tee -a "$LOG_FILE"
        if command -v nvcc &>/dev/null; then
            ok flatpak_cuda_found | tee -a "$LOG_FILE"
            GPU_AVAILABLE=true
        else
            warn flatpak_cuda_install | tee -a "$LOG_FILE"
            sudo apt update
            sudo apt install -y nvidia-cuda-toolkit
            if command -v nvcc &>/dev/null; then
                ok flatpak_cuda_ok | tee -a "$LOG_FILE"
                GPU_AVAILABLE=true
            else
                error flatpak_cuda_fail | tee -a "$LOG_FILE"
            fi
        fi
    else
        warn flatpak_driver_not | tee -a "$LOG_FILE"
    fi
else
    info flatpak_no_nvidia | tee -a "$LOG_FILE"
fi

# ----------------- Шаг 1: Flatpak -----------------
if ! command -v flatpak &>/dev/null; then
    info flatpak_install | tee -a "$LOG_FILE"
    sudo apt update
    sudo apt install -y flatpak
fi

# ----------------- Шаг 2: Flathub -----------------
if ! flatpak remotes | grep -q flathub; then
    info flatpak_flathub_add | tee -a "$LOG_FILE"
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

# ----------------- Шаг 3: Установка медиа-программ -----------------
flatpak install -y flathub org.shotcut.Shotcut
flatpak install -y flathub org.gimp.GIMP.Plugin.GMic//3
flatpak install -y flathub org.gimp.GIMP
flatpak install -y flathub org.kde.krita
flatpak install -y flathub org.audacityteam.Audacity

# ----------------- Шаг 4: Символические ссылки -----------------
# mkdir -p /mnt/shotcut /mnt/storage/Видео /mnt/storage/Музыка /mnt/storage/Изображения
# ln -sfn /mnt/shotcut "$HOME/shotcut"
# ln -sfn /mnt/storage/Видео "$HOME/Видео"
# ln -sfn /mnt/storage/Музыка "$HOME/Музыка"
# ln -sfn /mnt/storage/Изображения "$HOME/Изображения"
# ok flatpak_symlinks | tee -a "$LOG_FILE"

# Proxy и Preview
SHOTCUT_SETTINGS_DIR="$HOME/.config/Shotcut"
mkdir -p "$SHOTCUT_SETTINGS_DIR"
SETTINGS_FILE="$SHOTCUT_SETTINGS_DIR/shotcut.ini"

cat > "$SETTINGS_FILE" <<EOF
[Proxy]
enabled=true
size=50
format=mp4
path=/mnt/shotcut

[Preview]
scale=50
EOF
ok flatpak_proxy_enabled | tee -a "$LOG_FILE"

# ----------------- Шаг 5: GPU/NVENC для Flatpak -----------------
if $GPU_AVAILABLE; then
    info flatpak_gpu_bypass | tee -a "$LOG_FILE"
    flatpak override --user --device=all org.shotcut.Shotcut
    flatpak run --command=ffmpeg org.shotcut.Shotcut -hide_banner -encoders | grep nvenc && NVENC_AVAILABLE=true
fi

# ----------------- Шаг 6: Пресеты Shotcut -----------------
SHOTCUT_PRESET_DIR="$HOME/.local/share/Shotcut/backup/presets"
mkdir -p "$SHOTCUT_PRESET_DIR"

if $NVENC_AVAILABLE; then
    CODEC_4K="h264_nvenc"
    RESOURCE_4K="GPU"
    ok flatpak_nvenc | tee -a "$LOG_FILE"
else
    CODEC_4K="libx264"
    RESOURCE_4K="CPU"
    warn flatpak_no_nvenc | tee -a "$LOG_FILE"
fi

cat > "$SHOTCUT_PRESET_DIR/4K_export.sml" <<EOF
<mlt>
  <profile description="4K Preset" width="3840" height="2160" progressive="1" frame_rate_num="30" frame_rate_den="1" colorspace="709"/>
  <producer>
    <property name="mlt_service">avformat</property>
    <property name="resource">$RESOURCE_4K</property>
    <property name="video_width">3840</property>
    <property name="video_height">2160</property>
    <property name="pix_fmt">yuv420p</property>
    <property name="vcodec">$CODEC_4K</property>
    <property name="acodec">aac</property>
    <property name="bitrate">20000k</property>
    <property name="threads">auto</property>
  </producer>
</mlt>
EOF

# FullHD CPU HQ (статичный)
cat > "$SHOTCUT_PRESET_DIR/FullHD_CPU_HQ_export.sml" <<'EOF'
<mlt>
  <profile description="FullHD CPU HQ Preset" width="1920" height="1080" progressive="1" frame_rate_num="30" frame_rate_den="1" colorspace="709"/>
  <producer>
    <property name="mlt_service">avformat</property>
    <property name="resource">CPU</property>
    <property name="video_width">1920</property>
    <property name="video_height">1080</property>
    <property name="pix_fmt">yuv420p</property>
    <property name="vcodec">libx264</property>
    <property name="acodec">aac</property>
    <property name="bitrate">10000k</property>
    <property name="threads">auto</property>
  </producer>
</mlt>
EOF
ok flatpak_presets_created | tee -a "$LOG_FILE"

# ----------------- Шаг 7: OpenGL -----------------
info flatpak_check_opengl | tee -a "$LOG_FILE"
if flatpak run --command=glxinfo org.shotcut.Shotcut 2>/dev/null | grep -i "OpenGL renderer" &>/dev/null; then
    ok flatpak_opengl_ok | tee -a "$LOG_FILE"
else
    warn flatpak_opengl_fail | tee -a "$LOG_FILE"
fi

info flatpak_finished | tee -a "$LOG_FILE"