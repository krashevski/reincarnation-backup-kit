# 📦 backup-ubuntu-24.04.sh — системный бэкап (Ubuntu 24.04)

[🇬🇧 English](../EN/README.backup-ubuntu-24.04.sh_EN.md) | [🇷🇺 Русский](README.backup-ubuntu-24.04.sh_RU.md)

**Автор:** Владислав Крашевский
**Поддержка:** ChatGPT

Этот скрипт отвечает за сохранение системной конфигурации Ubuntu 24.04: пакеты, репозитории, ключи.
Пользовательские данные не архивируются — для этого есть отдельный скрипт backup-restore-userdata.sh.

## 🚀 Что сохраняется

- список установленных пакетов (dpkg --get-selections)
- список вручную установленных пакетов (apt-mark showmanual)
- APT источники (/etc/apt/sources.list, /etc/apt/sources.list.d/)
- APT ключи (/etc/apt/keyrings/)
- логи работы Backup Kit

## 📂 Куда сохраняется

Архив:
```bash
/mnt/backups/backup-ubuntu-24.04.tar.gz
```

Структура архива:
```bash
system_packages/
    installed-packages.list
    manual-packages.list
    sources.list
    sources.list.d/
    keyrings/
    README
logs/
```

## ▶️ Запуск
```bash
./backup-ubuntu-24.04.sh
```

## ♻️ Восстановление
```bash
./restore
```

или
```bash
./restore-ubuntu-24.04.sh
```

Переменные восстановления:
- RESTORE_PACKAGES=manual — восстановить вручную установленные пакеты (рекомендуется)
- RESTORE_PACKAGES=full — восстановить полный список пакетов
- RESTORE_PACKAGES=none — пропустить восстановление пакетов
- RESTORE_LOGS=true — восстановить логи

## ⚡ Рекомендации

- Если запускается по SSH, использовать screen или tmux.


## См. также

- Reincarnation Backup Kit — Установка и Использование см. файл [README_ALL_RU.md](README_ALL_RU.md)
