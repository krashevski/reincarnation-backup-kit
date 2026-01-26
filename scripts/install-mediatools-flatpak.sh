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

# -------------------------------------------------------------
# Colors (safe for set -u)
# -------------------------------------------------------------
if [[ "${FORCE_COLOR:-0}" == "1" || -t 1 ]]; then
    RED="\033[0;31m"
    GREEN="\033[0;32m"
    YELLOW="\033[1;33m"
    BLUE="\033[0;34m"
    NC="\033[0m"
else
    RED=""; GREEN=""; YELLOW=""; BLUE=""; NC=""
fi


# -------------------------------------------------------------
# 1. Определяем директорию скрипта
# -------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -------------------------------------------------------------
# 2. Объявляем ассоциативный массив MSG (будет расширяться при source)
# -------------------------------------------------------------
declare -A MSG

# -------------------------------------------------------------
# 3. Функция загрузки сообщений
# -------------------------------------------------------------
load_messages() {
    local lang="$1"
    # очищаем предыдущие ключи
    MSG=()

    case "$lang" in
        ru)
            source "$SCRIPT_DIR/i18n/messages_ru.sh"
            ;;
        en)
            source "$SCRIPT_DIR/i18n/messages_en.sh"
            ;;
        *)
            echo "Unknown language: $lang" >&2
            return 1
            ;;
    esac
}

# -------------------------------------------------------------
# 4. Безопасный say
# -------------------------------------------------------------
say() {
    local key="$1"; shift
    local msg="${MSG[${key}]:-$key}"

    if [[ $# -gt 0 ]]; then
        printf "$msg\n" "$@"
    else
        printf '%s\n' "$msg"
    fi
}


# -------------------------------------------------------------
# 5. Kjuuth ok
# -------------------------------------------------------------
ok() {
    local key="$1"; shift
    local fmt
    fmt="$(say "$key")"
    printf "%b[OK]%b %b\n" \
        "${GREEN:-}" \
        "${NC:-}" \
        "$(printf "$fmt" "$@")"
}


# -------------------------------------------------------------
# 6. Функция info для логирования
# -------------------------------------------------------------
info() {
    local key="$1"; shift
    local fmt
    fmt="$(say "$key")"
    printf "%b[INFO]%b %b\n" \
        "${BLUE:-}" \
        "${NC:-}" \
        "$(printf "$fmt" "$@")" >&2
}


# -------------------------------------------------------------
# 7. Функция warn для логирования
# -------------------------------------------------------------
warn() {
    local key="$1"; shift
    local fmt
    fmt="$(say "$key")"
    printf "%b[WARN]%b %b\n" \
        "${YELLOW:-}" \
        "${NC:-}" \
        "$(printf "$fmt" "$@")" >&2
}

# -------------------------------------------------------------
# 8. Функция error для логирования
# -------------------------------------------------------------
error() {
    local key="$1"; shift
    local fmt
    fmt="$(say "$key")"
    printf "%b[ERROR]%b %b\n" \
        "${RED:-}" \
        "${NC:-}" \
        "$(printf "$fmt" "$@")" >&2
}


# -------------------------------------------------------------
# 9. Функция echo_echo_msg для логирования
# -------------------------------------------------------------
echo_msg() {
    local key="$1"; shift
    local fmt
    fmt="$(say "$key")"
    printf "%b\n" "$(printf "$fmt" "$@")"
}

# -------------------------------------------------------------
# 10. Функция die для логирования
# -------------------------------------------------------------
die() {
    error "$@"
    exit 1
}

# -------------------------------------------------------------
# 11. Устанавливаем язык по умолчанию и загружаем переводы
# -------------------------------------------------------------
LANG_CODE="${LANG_CODE:-ru}"
load_messages "$LANG_CODE"

# --- Проверка root только для команд, где нужны права ---
require_root() {
    if [[ $EUID -ne 0 ]]; then
        error run_sudo
        return 1
    fi
}

REAL_HOME="${HOME:-/home/$USER}"
if [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != "root" ]]; then
    REAL_HOME="/home/$SUDO_USER"
fi

# --- Inhibit recursion via systemd-inhibit ---
if [[ -t 1 ]] && command -v systemd-inhibit >/dev/null 2>&1; then
    if [[ -z "${INHIBIT_LOCK:-}" ]]; then
        export INHIBIT_LOCK=1
        exec systemd-inhibit \
            --what=handle-lid-switch:sleep:idle \
            --why="Backup in progress" \
            "$0" "$@"
    fi
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
    info nvidia_detected | tee -a "$LOG_FILE"
    if ! command -v nvidia-smi &>/dev/null; then
        info nvidia_driver_install) | tee -a "$LOG_FILE"
        sudo ubuntu-drivers autoinstall
    fi
    if nvidia-smi &>/dev/null; then
        ok nvidia_driver_ok | tee -a "$LOG_FILE"
        if command -v nvcc &>/dev/null; then
            ok cuda_found | tee -a "$LOG_FILE"
            GPU_AVAILABLE=true
        else
            warn cuda_install | tee -a "$LOG_FILE"
            sudo apt update
            sudo apt install -y nvidia-cuda-toolkit
            if command -v nvcc &>/dev/null; then
                ok cuda_ok | tee -a "$LOG_FILE"
                GPU_AVAILABLE=true
            else
                error cuda_fail | tee -a "$LOG_FILE"
            fi
        fi
    else
        warn driver_not | tee -a "$LOG_FILE"
    fi
else
    info no_nvidia | tee -a "$LOG_FILE"
fi

# ----------------- Шаг 1: Flatpak -----------------
if ! command -v flatpak &>/dev/null; then
    info flatpak_install | tee -a "$LOG_FILE"
    sudo apt update
    sudo apt install -y flatpak
fi

# ----------------- Шаг 2: Flathub -----------------
if ! flatpak remotes | grep -q flathub; then
    info flathub_add | tee -a "$LOG_FILE"
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

# ----------------- Шаг 3: Установка медиа-программ -----------------
flatpak install -y flathub org.shotcut.Shotcut
flatpak install -y flathub org.gimp.GIMP.Plugin.GMic//3
flatpak install -y flathub org.gimp.GIMP
flatpak install -y flathub org.kde.krita
flatpak install -y flathub org.audacityteam.Audacity

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
    info gpu_skip | tee -a "$LOG_FILE"
    flatpak override --user --device=all org.shotcut.Shotcut
    flatpak run --command=ffmpeg org.shotcut.Shotcut -hide_banner -encoders | grep nvenc && NVENC_AVAILABLE=true
fi

# ----------------- Шаг 6: Пресеты Shotcut -----------------
SHOTCUT_PRESET_DIR="$HOME/.local/share/Shotcut/backup/presets"
mkdir -p "$SHOTCUT_PRESET_DIR"

if $NVENC_AVAILABLE; then
    CODEC_4K="h264_nvenc"
    RESOURCE_4K="GPU"
    ok nvenc | tee -a "$LOG_FILE"
else
    CODEC_4K="libx264"
    RESOURCE_4K="CPU"
    warn no_nvenc | tee -a "$LOG_FILE"
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
ok presets_created | tee -a "$LOG_FILE"

# ----------------- Шаг 7: OpenGL -----------------
info "Проверка OpenGL внутри Flatpak Shotcut..." | tee -a "$LOG_FILE"
if flatpak run --command=glxinfo org.shotcut.Shotcut 2>/dev/null | grep -i "OpenGL renderer" &>/dev/null; then
    ok say opengl_ok | tee -a "$LOG_FILE"
else
    warn opengl_fail | tee -a "$LOG_FILE"
fi

echo "=== ✅ $(say finished) ===" | tee -a "$LOG_FILE"

