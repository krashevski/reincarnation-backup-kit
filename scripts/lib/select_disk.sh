#!/usr/bin/env bash
# =============================================================
# lib/select_disk.sh - select disk helpers library
# -------------------------------------------------------------
# Использование select_disk.sh
:<<'DOC'
# main.sh или hdd-setup-profiles.sh
source "$SCRIPT_DIR/lib/select_disk.sh"

if ! select_disk; then
    return 0   # возврат в главное меню
fi
DOC


select_disk() {
    local DISK

    echo_msg sel_partition
    select_prompt select_disk

    select DISK in "${AVAILABLE_DISKS[@]}"; do
        case "$REPLY" in
            0)
                info exit_selected
                return 1   # пользователь отменил выбор
                ;;
            *)
                if [[ -n "$DISK" ]]; then
                    HDD="/dev/$DISK"
                    info disk_selected "$HDD"
                    return 0
                else
                    warn invalid_choice
                fi
                ;;
        esac
    done
}