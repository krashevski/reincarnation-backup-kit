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
install-nvidia-cuda.sh — установка драйвера NVIDIA и CUDA
Поддержка: GTX 1650, Ubuntu/Debian
Reincarnation Backup Kit — MIT License
Copyright (c) 2025 Vladislav Krashevsky with support from ChatGPT
=============================================================
DOC

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
source "$LIB_DIR/guards-inhibit.sh"

if ! TARGET_HOME="$(resolve_target_home)"; then
    die "Cannot determine target home"
fi

if ! REAL_USER="$(resolve_real_user)"; then
    die "Cannot determine real user"
fi

# root / inhibit здесь не используем
require_root || return 1
# inhibit только если есть systemd и не root-login
if command -v systemd-inhibit &>/dev/null && [[ $EUID -ne 0 ]]; then
    inhibit_run "$0" "$@"
fi

# --- Логирование ---
BACKUP_DIR="/mnt/backups/REBK"
LOG_DIR="$BACKUP_DIR/logs"
mkdir -p "$LOG_DIR"
RUN_LOG="$LOG_DIR/install-nvidia-cuda.log"
exec > >(tee -a "$RUN_LOG") 2>&1

# === Шаги ===
info cuda_update
sudo apt update

info cuda_driver_install
sudo ubuntu-drivers autoinstall

info cuda_driver_check
if ! command -v nvidia-smi &>/dev/null; then
    error cuda_driver_error
    exit 1
fi
ok cuda_smi_ok

info cuda_modprobe
sudo modprobe nvidia

info cuda_gpu_info
nvidia-smi

info cuda_manage
echo "    check-cuda-tools.sh"
info cuda_install


info cuda_version
nvcc --version || warn cuda_warn

info cuda_smi
nvidia-smi -q | grep -i "CUDA Version"

ok cuda_done_nvidia

echo "=============================================================" 

exit 0