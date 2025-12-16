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
install_mediatools_flatpak.sh v1.1 — Multimedia Environment Installer
Ubuntu 24.04: Shotcut, GIMP+G'MIC, Krita, Audacity
Auto-check NVIDIA GPU, CUDA, NVENC, OpenGL, Proxy, Presets
Author: Vladislav Krashevsky
=============================================================
DOC

set -euo pipefail

# === Двуязычные сообщения ===
declare -A MSG=(
  [ru_start]="Старт установки мультимедиа среды"
  [en_start]="Starting multimedia environment installation"

  [ru_nvidia_detected]="NVIDIA GPU обнаружена."
  [en_nvidia_detected]="NVIDIA GPU detected."

  [ru_nvidia_driver_install]="Драйвер NVIDIA не установлен, устанавливаем..."
  [en_nvidia_driver_install]="NVIDIA driver not installed, installing..."

  [ru_nvidia_driver_ok]="Драйвер NVIDIA работает."
  [en_nvidia_driver_ok]="NVIDIA driver is working."

  [ru_cuda_found]="CUDA Toolkit найден."
  [en_cuda_found]="CUDA Toolkit found."

  [ru_cuda_install]="CUDA Toolkit не найден. Устанавливаем..."
  [en_cuda_install]="CUDA Toolkit not found. Installing..."

  [ru_cuda_ok]="CUDA Toolkit успешно установлен."
  [en_cuda_ok]="CUDA Toolkit successfully installed."

  [ru_cuda_fail]="Не удалось установить CUDA Toolkit."
  [en_cuda_fail]="Failed to install CUDA Toolkit."

  [ru_no_nvidia]="NVIDIA GPU не обнаружена."
  [en_no_nvidia]="NVIDIA GPU not detected."

  [ru_flatpak_install]="Flatpak не найден, устанавливаем..."
  [en_flatpak_install]="Flatpak not found, installing..."

  [ru_flathub_add]="Добавляем Flathub репозиторий..."
  [en_flathub_add]="Adding Flathub repository..."

  [ru_symlinks]="Символические ссылки созданы"
  [en_symlinks]="Symlinks created"

  [ru_presets_created]="Пресеты Shotcut созданы."
  [en_presets_created]="Shotcut presets created."

  [ru_nvenc"]="NVENC доступен: 4K будет через GPU."
  [en_nvenc"]="NVENC available: 4K will use GPU."

  [ru_no_nvenc]="NVENC недоступен: 4K будет через CPU."
  [en_no_nvenc]="NVENC unavailable: 4K will use CPU."

  [ru_opengl_ok]="OpenGL GPU доступен."
  [en_opengl_ok]="OpenGL GPU available."

  [ru_opengl_fail]="OpenGL GPU недоступен внутри Flatpak."
  [en_opengl_fail]="OpenGL GPU not available inside Flatpak."

  [ru_finished]="Установка и настройка завершены!"
  [en_finished]="Installation and configuration completed!"
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
mkdir -p "$WORKDIR" "$LOG_DIR"
LOG_FILE="$LOG_DIR/install_mediatools.log"

echo "[`date`] $(say start)" > "$LOG_FILE"

# ----------------- Шаг 0: NVIDIA GPU и CUDA -----------------
GPU_AVAILABLE=false
NVENC_AVAILABLE=false

if lspci | grep -i nvidia &>/dev/null; then
    info "$(say nvidia_detected)" | tee -a "$LOG_FILE"
    if ! command -v nvidia-smi &>/dev/null; then
        info "$(say nvidia_driver_install)" | tee -a "$LOG_FILE"
        sudo ubuntu-drivers autoinstall
    fi
    if nvidia-smi &>/dev/null; then
        ok "$(say nvidia_driver_ok)" | tee -a "$LOG_FILE"
        if command -v nvcc &>/dev/null; then
            ok "$(say cuda_found)" | tee -a "$LOG_FILE"
            GPU_AVAILABLE=true
        else
            warn "$(say cuda_install)" | tee -a "$LOG_FILE"
            sudo apt update
            sudo apt install -y nvidia-cuda-toolkit
            if command -v nvcc &>/dev/null; then
                ok "$(say cuda_ok)" | tee -a "$LOG_FILE"
                GPU_AVAILABLE=true
            else
                error "$(say cuda_fail)" | tee -a "$LOG_FILE"
            fi
        fi
    else
        warn "NVIDIA driver not working" | tee -a "$LOG_FILE"
    fi
else
    info "$(say no_nvidia)" | tee -a "$LOG_FILE"
fi

# ----------------- Шаг 1: Flatpak -----------------
if ! command -v flatpak &>/dev/null; then
    info "$(say flatpak_install)" | tee -a "$LOG_FILE"
    sudo apt update
    sudo apt install -y flatpak
fi

# ----------------- Шаг 2: Flathub -----------------
if ! flatpak remotes | grep -q flathub; then
    info "$(say flathub_add)" | tee -a "$LOG_FILE"
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

# ----------------- Шаг 3: Установка медиа-программ -----------------
flatpak install -y flathub org.shotcut.Shotcut
flatpak install -y flathub org.gimp.GIMP.Plugin.GMic//3
flatpak install -y flathub org.gimp.GIMP
flatpak install -y flathub org.kde.krita
flatpak install -y flathub org.audacityteam.Audacity

# ----------------- Шаг 4: Символические ссылки -----------------
mkdir -p /mnt/shotcut /mnt/storage/Видео /mnt/storage/Музыка /mnt/storage/Изображения
ln -sfn /mnt/shotcut "$HOME/shotcut"
ln -sfn /mnt/storage/Видео "$HOME/Видео"
ln -sfn /mnt/storage/Музыка "$HOME/Музыка"
ln -sfn /mnt/storage/Изображения "$HOME/Изображения"
ok "$(say symlinks)" | tee -a "$LOG_FILE"

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
ok "Proxy и Preview Scaling включены." | tee -a "$LOG_FILE"

# ----------------- Шаг 5: GPU/NVENC для Flatpak -----------------
if $GPU_AVAILABLE; then
    info "Пропуск GPU в Flatpak Shotcut..." | tee -a "$LOG_FILE"
    flatpak override --user --device=all org.shotcut.Shotcut
    flatpak run --command=ffmpeg org.shotcut.Shotcut -hide_banner -encoders | grep nvenc && NVENC_AVAILABLE=true
fi

# ----------------- Шаг 6: Пресеты Shotcut -----------------
SHOTCUT_PRESET_DIR="$HOME/.local/share/Shotcut/backup/presets"
mkdir -p "$SHOTCUT_PRESET_DIR"

if $NVENC_AVAILABLE; then
    CODEC_4K="h264_nvenc"
    RESOURCE_4K="GPU"
    ok "$(say nvenc)" | tee -a "$LOG_FILE"
else
    CODEC_4K="libx264"
    RESOURCE_4K="CPU"
    warn "$(say no_nvenc)" | tee -a "$LOG_FILE"
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
ok "$(say presets_created)" | tee -a "$LOG_FILE"

# ----------------- Шаг 7: OpenGL -----------------
info "Проверка OpenGL внутри Flatpak Shotcut..." | tee -a "$LOG_FILE"
if flatpak run --command=glxinfo org.shotcut.Shotcut 2>/dev/null | grep -i "OpenGL renderer" &>/dev/null; then
    ok "$(say opengl_ok)" | tee -a "$LOG_FILE"
else
    warn "$(say opengl_fail)" | tee -a "$LOG_FILE"
fi

echo "=== ✅ $(say finished) ===" | tee -a "$LOG_FILE"

