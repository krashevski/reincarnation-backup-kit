#!/usr/bin/env bash
# =============================================================
# install-man.sh — безопасная установка man-страниц REBK с поддержкой локалей
# Требуется root
# =============================================================

set -euo pipefail

# Определяем BIN_DIR и PROJECT_ROOT
BIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$BIN_DIR/../.." && pwd)"

# Пути к логам
LOG_FILE="/var/log/rebk-man-install.log"

# Проверка root
if [[ $EUID -ne 0 ]]; then
    echo "Error: install-man.sh must be run as root" >&2
    exit 1
fi

echo "Starting REBK man pages installation: $(date)" | tee -a "$LOG_FILE"

# Список локалей
LOCALES=("en" "ru" "ja")

for LANG in "${LOCALES[@]}"; do
    if [[ "$LANG" == "en" ]]; then
        SRC_DIR="$PROJECT_ROOT/docs/man/man8"
        TARGET_DIR="/usr/share/man/man8"
    else
        SRC_DIR="$PROJECT_ROOT/docs/man/$LANG/man8"
        TARGET_DIR="/usr/share/man/$LANG/man8"
    fi

    if [[ ! -d "$SRC_DIR" ]]; then
        echo "Warning: source directory not found: $SRC_DIR" | tee -a "$LOG_FILE"
        continue
    fi

    mkdir -p "$TARGET_DIR"

    for FILE in "$SRC_DIR"/*.8; do
        BASENAME=$(basename "$FILE")
        cp "$FILE" "$TARGET_DIR/$BASENAME"
        gzip -f "$TARGET_DIR/$BASENAME"
        echo "Installed man page ($LANG): $BASENAME" | tee -a "$LOG_FILE"
    done
done

# Обновление базы man
echo "Updating man database..." | tee -a "$LOG_FILE"
mandb

echo "REBK man pages installation completed: $(date)" | tee -a "$LOG_FILE"

# Можно сразу открыть man для проверки
man rebk-users-home-restore || true

