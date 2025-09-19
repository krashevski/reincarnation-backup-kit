# 📦 backup-ubuntu-22.04.sh — system backup (Ubuntu 24.04)

[🇬🇧 English](README.backup-ubuntu-24.04.sh_EN.md) | [🇷🇺 Русский](README.backup-ubuntu-24.04.sh_RU.md)

**Author:** Vladislav Krashevsky
**Support:** ChatGPT

This script is responsible for saving the Ubuntu 24.04 system configuration: packages, repositories, keys.
User data is not backed up—there is a separate script for that, backup-restore-userdata.sh.

## 🚀 What is saved

- list of installed packages (dpkg --get-selections)
- list of manually installed packages (apt-mark showmanual)
- APT sources (/etc/apt/sources.list, /etc/apt/sources.list.d/)
- APT keys (/etc/apt/keyrings/)
- Backup Kit logs

## 📂 Where is saved

Archive:
```bash
/mnt/backups/backup-ubuntu-24.04.tar.gz
```

Archive structure:
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

## ▶️ Launch
```bash
./backup-ubuntu-24.04.sh
```

## ♻️ Restore
```bash
./restore
```

or
```bash
./restore-ubuntu-24.04.sh
```

Restore variables:
- RESTORE_PACKAGES=manual — restore manually installed packages (recommended)
- RESTORE_PACKAGES=full — restore the full list of packages
- RESTORE_PACKAGES=none — skip package restoration
- RESTORE_LOGS=true — restore logs

## ⚡ Recommendations

- If running over SSH, use screen or tmux.

## See also

- Reincarnation Backup Kit — Installation and Usage, see [README_ALL_EN.md](README_ALL_EN.md)
