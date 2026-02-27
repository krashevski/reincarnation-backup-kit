#!/usr/bin/env bash
set -euo pipefail

BIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$BIN_DIR/lib"

source "$LIB_DIR/i18n.sh"
init_app_lang
source "$LIB_DIR/logging.sh"
init_app_lang

usage() {
    say last_usage
    exit 1
}

[[ $# -eq 1 ]] || usage
USER="$1"

BACKUP_DIR="/mnt/backups/REBK"
ARCHIVE_DIR="$BACKUP_DIR/bares_workdir/tar_archive"

declare -a files=()

shopt -s nullglob
files=( "$ARCHIVE_DIR/${USER}"_*.tar.gz )
shopt -u nullglob

if (( ${#files[@]} == 0 )); then
    error last_no_archives "$USER"
    exit 1
fi

# Находим последний архив
latest=$(printf '%s\n' "${files[@]}" | xargs -d '\n' stat -c '%Y %n' \
         | sort -nr \
         | head -n1 \
         | cut -d' ' -f2-)

# Получаем размер и дату
size=$(du -h "$latest" | cut -f1)
mtime=$(stat -c '%y' "$latest" | cut -d. -f1)

ok last_archive "$USER"
echo_msg last_file  "$latest"
echo_msg last_date  "$mtime"
echo_msg last_size  "$size"

exit 0