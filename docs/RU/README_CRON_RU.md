# 📦 Backup Kit — Скрипты резервного копирования с cron

[🇬🇧 English](../EN/README_CRON_EN.md) | [🇷🇺 Русский](README_CRON_RU.md)

Набор из 4-х скриптов для автоматического резервного копирования пользовательских данных с помощью cron.

## 🛠 Состав:

1. add-cron-backup.sh — добавляет или обновляет cron-задачу для ежедневного бэкапа.
2. cron-backup-userdata.sh — выполняет бэкап (rsync + tar), проверяет свободное место, вызывает очистку логов.
3. clean-backup-logs.sh — удаляет старые логи (по умолчанию старше 30 дней).
4. remove-cron-backup.sh — удаляет cron-задачу резервного копирования.

## ⚙ Требования:

- Linux (Ubuntu/Debian или совместимые)
- rsync, tar, cron
- Права root (через sudo)

## 🚀 Установка:

Скопируйте скрипты в каталог, например /usr/local/bin/backup-kit и сделайте их исполняемыми:
```bash
chmod +x add-cron-backup.sh cron-backup-userdata.sh clean-backup-logs.sh remove-cron-backup.sh
```

##📌 Использование:

### Добавить задачу:
```bash
sudo ./add-cron-backup.sh 10:30
```

Запустит резервное копирование каждый день в 10:30.

### Удалить задачу:
```bash
sudo ./remove-cron-backup.sh
```

### Выполнить бэкап вручную:
```bash
sudo ./cron-backup-userdata.sh
```

### Очистить старые логи:
```bash
./clean-backup-logs.sh
```

## 📂 Директории:

Бэкапы: /mnt/backups/br_workdir/user_data/<username>
Архивы: /mnt/backups/br_workdir/tar_archive
Логи: /mnt/backups/logs
