# 📦 Backup Kit — Cron Backup Scripts

[🇬🇧 English](README_CRON_EN.md) | [🇷🇺 Русский](,,/RU/README_CRON_RU.md)

A set of 4 scripts for automatic backup of user data using cron.

## 🛠 Contents:

1. add-cron-backup.sh — adds or updates a cron job for daily backups.
2. cron-backup-userdata.sh — performs a backup (rsync + tar), checks free space, and clears logs.
3. clean-backup-logs.sh — deletes old logs (by default, older than 30 days).
4. remove-cron-backup.sh — removes the backup cron job.

## ⚙ Requirements:

- Linux (Ubuntu/Debian or compatible)
- rsync, tar, cron
- Root privileges (via sudo)

## 🚀 Installation:

Copy the scripts to a directory, such as /usr/local/bin/backup-kit, and make them executable:
```bash
chmod +x add-cron-backup.sh cron-backup-userdata.sh clean-backup-logs.sh remove-cron-backup.sh
```

##📌 Usage:

### Add task:
```bash
sudo ./add-cron-backup.sh 10:30
```

Runs a backup every day at 10:30.

### Delete a task:
```bash
sudo ./remove-cron-backup.sh
```

### Perform a manual backup:
```bash
sudo ./cron-backup-userdata.sh
```

### Clear old logs:
```bash
./clean-backup-logs.sh
```

## 📂 Directories:

Backups: /mnt/backups/br_workdir/user_data/<username>
Archives: /mnt/backups/br_workdir/tar_archive
Logs: /mnt/backups/logs
