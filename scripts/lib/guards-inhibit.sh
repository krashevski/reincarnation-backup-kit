
# Универсальные guard-модули (lock + inhibit + recursion check)

# -------------------------------------------------------------
# Ключевые обязанности:
# проверка: уже под inhibit или нет;
# защита от самоперезапуска;
# единая точка входа для systemd-inhibit
# -------------------------------------------------------------
 
# inhibit.sh

if [[ -n "${REBK_INHIBITED:-}" ]]; then
    return 0
fi

export REBK_INHIBITED=1

inhibit_run() {
    systemd-inhibit \
        --who="REBK" \
        --why="Backup in progress" \
        --what=shutdown:sleep \
        "$@"
}

# Использование inhibit.sh
# source "$LIB_DIR/inhibit.sh"
# inhibit_run "$@"
