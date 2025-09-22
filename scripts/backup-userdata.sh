#!/bin/bash
# =============================================================
# Reincarnation Backup Kit — MIT License
# Copyright (c) 2025 Vladislav Krashevsky
# Wrapper: backup-userdata.sh
# -------------------------------------------------------------
# Обёртка для резервного копирования пользовательских данных
# Вызов реального скрипта backup-restore-userdata.sh с аргументом "backup"
# Дополнительные параметры (например, --fresh) передаются далее.
# =============================================================

set -euo pipefail
SCRIPT_DIR="$(dirname "$0")"
exec "$SCRIPT_DIR/backup-restore-userdata.sh" backup "$@"

