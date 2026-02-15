#!/usr/bin/env bash
# install-man.sh — безопасная установка man-страниц REBK с поддержкой локалей
# Требуется root
# Требуется root
# Использование install-man.sh
:<<'DOC'
# --- Определяем BIN_DIR относительно скрипта ---
BIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Путь к библиотекам всегда относительно BIN_DIR
LIB_DIR="$BIN_DIR/lib"

source "$LIB_DIR/logging.sh"
source "$LIB_DIR/privileges.sh"
source "$LIB_DIR/install-man.sh"

require_root
ensure_man_pages           # Проверяем/устанавливаем man-страницы
man rebk-users-home-restore
DOC

set -euo pipefail

ensure_man_pages() {
    if ! man -w rebk-users-home-restore >/dev/null 2>&1; then
        info man_not_found
        if [[ $(id -u) -eq 0 ]]; then
            install_man_pages
            info man_installed
        else
            warn man_install_sudo
        fi
    fi
}

install_man_pages() {
    # Проверка root
    if [[ $EUID -ne 0 ]]; then
        error error_run_root >&2
        exit 1
    fi

    LOCALES=("en" "ru" "ja")
    PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
    MAN_SRC_DIR="$PROJECT_ROOT/docs/man"
    LOG_FILE="/var/log/rebk-man-install.log"

    info man_install_start $(date) | tee -a "$LOG_FILE"

    for LANG in "${LOCALES[@]}"; do
        if [[ "$LANG" == "en" ]]; then
            SRC_DIR="$MAN_SRC_DIR/man8"
            TARGET_DIR="/usr/share/man/man8"
        else
            SRC_DIR="$MAN_SRC_DIR/$LANG/man8"
            TARGET_DIR="/usr/share/man/$LANG/man8"
        fi

        if [[ ! -d "$SRC_DIR" ]]; then
            warn directory_not_found $SRC_DIR | tee -a "$LOG_FILE"
            continue
        fi

        mkdir -p "$TARGET_DIR"

        for FILE in "$SRC_DIR"/*.8; do
            BASENAME=$(basename "$FILE")
            sudo --preserve-env=LANG,LC_ALL bash -c "cp '$FILE' '$TARGET_DIR/$BASENAME' && gzip -f '$TARGET_DIR/$BASENAME'"
            info man_installed $LANG $BASENAME | tee -a "$LOG_FILE"
        done
    done  # <-- закрытие цикла LANG

    info updating_mandb | tee -a "$LOG_FILE"
    sudo --preserve-env=LANG,LC_ALL mandb

    info install_completed $(date) | tee -a "$LOG_FILE"
}
