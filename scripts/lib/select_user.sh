#!/usr/bin/env bash
# =============================================================
# lib/select_user.sh - выбор пользователя для операций
# Reincarnation Backup Kit — MIT License
# -------------------------------------------------------------
# Функция: select_user <OPERATION>
#   OPERATION — строка для отображения в подсказке
# Возвращает массив SELECTED_USERS
# =============================================================

select_user() {
    local OPERATION="$1"
    local users=()
    local selections
    SELECTED_USERS=()  # глобальный массив для результата

    # Сбор всех пользователей в /home
    for d in /home/*; do
        [ -d "$d" ] && users+=("$(basename "$d")")
    done

    if [ ${#users[@]} -eq 0 ]; then
        echo "[ERROR] Нет пользователей в /home"
        return 1
    fi

    echo "Доступные пользователи:"
    for i in "${!users[@]}"; do
        printf "  %d) %s\n" "$((i+1))" "${users[$i]}"
    done

    printf "Выберите пользователя(ей) для операции «%s» (например: 1 или 1 3): " "$OPERATION"
    read -r -a selections

    for sel in "${selections[@]}"; do
        if ! [[ "$sel" =~ ^[0-9]+$ ]] || (( sel < 1 || sel > ${#users[@]} )); then
            echo "[WARN] Игнорируется некорректный выбор: $sel"
            continue
        fi
        SELECTED_USERS+=("${users[$((sel-1))]}")
    done

    if [ ${#SELECTED_USERS[@]} -eq 0 ]; then
        echo "[ERROR] Не выбран ни один пользователь"
        return 1
    fi
}