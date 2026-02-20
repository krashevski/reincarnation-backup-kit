#!/usr/bin/env bash
# =============================================================
# /lib/cleanup.sh - библиотека только функции
# -------------------------------------------------------------
# использование cleanup.sh
:<<'DOC'
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"
WORKDIR="/tmp/my_workdir"

source "$LIB_DIR/cleanup.sh"

# Регистрация рабочей директории
register_cleanup "$WORKDIR"

# Настройка trap на выход/прерывание
trap 'cleanup_custom; cleanup_workdir' EXIT INT TERM

# Пользовательские действия очистки
cleanup_custom() {
    echo "[INFO] Дополнительная очистка выполнена"
}

# Создаём рабочую директорию для примера
mkdir -p "$WORKDIR"

echo "Работаем с $WORKDIR..."
DOC
# =============================================================

register_cleanup() {
    local workdir="$1"
    CLEANUP_WORKDIR="$workdir"
}

cleanup_workdir() {
    [[ -n "$CLEANUP_WORKDIR" ]] || return 0
    safe_rm_rf "$CLEANUP_WORKDIR"
}

cleanup_custom() {
    :
}

# основная функция, на которую ссылается trap
cleanup() {
    cleanup_custom
    cleanup_workdir
}

