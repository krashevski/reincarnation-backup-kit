#!/usr/bin/env bash
# =============================================================
#  /scriptslib/i18n.sh — интернационализация и определение языка
# =============================================================

detect_system_lang() {
    local lang

    # Приоритет: LC_ALL > LANG
    lang="${LC_ALL:-${LANG:-}}"

    # Если язык не определён
    [[ -z "$lang" ]] && {
        echo "en"
        return
    }

    # ru_RU.UTF-8 → ru
    lang="${lang%%_*}"
    lang="${lang,,}"

    case "$lang" in
        en|ru)
            echo "$lang"
            ;;
        *)
            echo "en"
            ;;
    esac
}

# -------------------------------------------------------------
# init_app_lang
# Инициализация APP_LANG (если не задан)
# -------------------------------------------------------------
init_app_lang() {
    if [[ -z "${APP_LANG:-}" ]]; then
        APP_LANG="$(detect_system_lang)"
        export APP_LANG
    fi
}

# Экспорт API — объявляем функции как read-only (без ошибок в Bash)
declare -fr detect_system_lang init_app_lang