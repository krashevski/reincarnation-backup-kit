#!/usr/bin/env bash
# =============================================================
# /lib/safety.sh — защита от опасных операций с путями
# -------------------------------------------------------------
# Использование privileges.sh
:<<'DOC'
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

source "$LIB_DIR/logging.sh"
source "$LIB_DIR/privileges.sh"
source "$LIB_DIR/safety.sh"
DOC
# =============================================================

assert_safe_path() {
    local path="$1"

    # Пусто или корень
    if [[ -z "$path" || "$path" == "/" ]]; then
        error unsafe_path "$path"
        return 1
    fi

    # Системные каталоги
    case "$path" in
        /bin|/boot|/dev|/etc|/lib|/lib64|/proc|/root|/run|/sbin|/sys|/usr|/var)
            error unsafe_path "$path"
            return 1
            ;;
    esac

    # Не под /mnt/backups
    if [[ "$path" != "$BACKUP_DIR"* ]]; then
        error unsafe_path "$path"
        return 1
    fi

    return 0
}

safe_rm_rf() {
    local path="$1"

    assert_safe_path "$path" || return 1

    rm -rf --one-file-system -- "$path"
}
