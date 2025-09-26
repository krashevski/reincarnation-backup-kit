#!/bin/bash
# =============================================================
# show-system-mounts.sh — список точек монтирования и симлинков
# Reincarnation Backup Kit — MIT License
# Copyright (c) 2025 Vladislav Krashevsky
# =============================================================

set -euo pipefail

# ----------------------------
# Language setup
# ----------------------------
LANGUAGE="${LANGUAGE:-ru}"  # default Russian

declare -A MSG_RU=(
  [physical_disks]="===== Информация о физических дисках ====="
  [mounts_header]="===== Список точек монтирования ====="
  [symlinks_header]="===== Символические ссылки в %s ====="
  [crontab_header]="===== Строка в crontab ====="
)

declare -A MSG_EN=(
  [physical_disks]="===== Information about physical disks ====="
  [mounts_header]="===== List of mount points ====="
  [symlinks_header]="===== Symbolic links in %s ====="
  [crontab_header]="===== Crontab entries ====="
)

msg() {
  local key="$1"; shift
  case "$LANGUAGE" in
    ru) printf "${MSG_RU[$key]}\n" "$@" ;;
    en) printf "${MSG_EN[$key]}\n" "$@" ;;
    *)  printf "${MSG_EN[$key]}\n" "$@" ;; # fallback English
  esac
}

# --- Функция для информации о дисках ---
show_disks_info() {
    for dev in /sys/block/sd*; do
        name=$(basename "$dev")
        rota=$(cat "$dev/queue/rotational")
        type=$([ "$rota" -eq 1 ] && echo "HDD" || echo "SSD")
        size=$(lsblk -dn -o SIZE "/dev/$name")
        model=$(cat "/sys/block/$name/device/model" 2>/dev/null || echo "Unknown")
        echo "$name: $type, $size, $model"
    done
}

# ----------------------------
# Determine home of real user
# ----------------------------
if [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != "root" ]]; then
    USER_HOME="/home/$SUDO_USER"
else
    USER_HOME="${HOME:-/home/$USER}"
fi

# ----------------------------
# Output
# ----------------------------

echo
msg physical_disks
show_disks_info

echo
msg mounts_header
lsblk -o NAME,PATH,LABEL,MOUNTPOINT,FSTYPE,UUID -e 7,11

echo
msg symlinks_header "$USER_HOME"
find "$USER_HOME" -maxdepth 1 -type l -printf "%f -> %l\n"

echo
msg crontab_header
if sudo crontab -l 2>/dev/null; then
  :
else
  echo "(empty)"
fi
echo

