# Backup Kit — Ubuntu System Backup & Restore Scripts

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
![Made with Bash](https://img.shields.io/badge/Made%20with-Bash-1f425f.svg)
![Ubuntu 24.04 Tested](https://img.shields.io/badge/Ubuntu-24.04-brightgreen.svg)
![Debian 12 Supported](https://img.shields.io/badge/Debian-12-orange.svg)
![GitHub Repo Size](https://img.shields.io/github/repo-size/username/backup-kit)
![GitHub stars](https://img.shields.io/github/stars/username/backup-kit?style=social)

[🇬🇧 English](docs/EN/README_EN.md) | [🇷🇺 Русский](docs/RU/README_RU.md)

**Reincarnation Backup Kit** is a set of Bash scripts for backup and restore when reinstalling **Ubuntu** on an SSD, as well as for creating a multimedia environment (Shotcut, GIMP+G'MIC, Krita, Audacity).

---

## Why this project?

When reinstalling Linux, I often worried about losing my work, videos or photos.
With this Backup Kit I can make archives anytime, and when it's time to reinstall,
I do it without stress — everything is safe, and recovery is simple.

The main goal: **save your nerves during system reinstallations**.

## ✨ Features

### 🗄️ Backup and Restore
Consists of two independent parts:
1. **System Backup** — system configuration, package lists, repositories.
2. **User Backup** — home directories (/home/...), documents, and personal data.

> ⚠️ Important: Both parts complement each other. You can use only the system backup, only the user backup, or both at once.

### 🎬 Creating a Multimedia Environment
Consists of two steps:
1. **Format** the selected HDD and create users.
2. **NVIDIA GPU and CUDA testing**, software installation:
   - [Shotcut](https://shotcut.org/) (video editor)
   - [GIMP+G'MIC](https://gmic.eu/) (graphics)
   - [Krita](https://krita.org/en/) (drawing)
   - [Audacity](https://www.audacityteam.org/) (sound)
   - creating presets for Shotcut

> ⚠️ Important: You can only use the multimedia environment creation feature under Ubuntu, regardless of a backup.

## 📂 Structure

backup_kit/
├── scripts/
│ ├── install.sh # installer
│ ├── backup-ubuntu-22.04.sh # Ubuntu 22.04 backup
│ ├── backup-ubuntu-24.04.sh # Ubuntu 24.04 backup
│ ├── backup-debian-12.sh # Debian 12 backup
│ ├── restore.sh # system restore
│ ├── restore-ubuntu-22.04.sh # Ubuntu 22.04 restore
│ ├── restore-ubuntu-24.04.sh # Ubuntu 24.04 restore
│ ├── restore-debian-12.sh # Debian 12 restore
│ ├── backup-restore-userdata.sh # user data backup/restore
│ ├── safe-restore.sh # safe user data restore
│ ├── hdd-setup-profiles.sh # format HDD and create users
│ ├── install-mediatools-apt.sh # install media software via APT
│ ├── install-mediatools-flatpak.sh # install media software via Flathub
│ ├── install-nvidia-cuda.sh # installation of the NVIDIA and CUDA drivers
│ ├── check-shotcut-gpu.sh # NVIDIA GPU check
│ └── check-last-archive.sh # view available archives
├── docs/
│ ├── EN/
│ │ ├── README_EN.md # main README (English)
│ │ ├── README_ALL_EN.md # full documentation
│ │ ├── README_DIFF_EN.md # differences between versions
│ │ ├── README_DISK_EN.md # working with SSD/HDD
│ │ ├── README_REINSTALL_SYSTEM_EN.md # reinstalling the system
│ │ ├── README_SHOTCUT_EN.md # using Shotcut
│ └── RU/
│ ├── README_RU.md # main README (Russian)
│ ├── README_ALL_RU.md # полная документация
│ ├── README_DIFF_RU.md # отличия версий
│ ├── README_DISK_RU.md # работа с SSD/HDD
│ ├── README_REINSTALL_SYSTEM_RU.md # переустановка системы
│ ├── README_SHOTCUT_RU.md # работа с Shotcut
│ ├── README_SSD_SETUP_RU.md # настройка системы на SSD
├── images/
│ ├── Backup_Kit_SSD_partitions.png
│ ├── Backup_Kit_HDD_userdata_partitions.png
│ ├── Backup_Kit_Install.png
│ ├── Backup_Kit_Directory.png
│ ├── Backup_Kit_System_backup.png
│ ├── Backup_Kit_Ranger_logs_read.png
│ ├── Backup_Kit_Backup_userdata.png
│ ├── Backup_Kit_Restore_userdata.png
│ └── Backup_Kit_Shotcut_presets_ChatGPTChart.png
├── patches/
│ ├── hdd-setup-profiles.patch
│ └── global-backupkit.diff
└── LICENSE

## 🚀 Quick Start / Быстрый старт

```bash
git clone https://github.com/username/backup-kit.git
cd backup-kit
./install.sh
./backup-ubuntu-24.04.sh
./restore
./backup-restore-userdata.sh backup
./backup-restore-userdata.sh backup --fresh
./backup-restore-userdata.sh restore
```

## 📖 Documentation / Документация

- [📖 Documentation (EN)](docs/EN/README_ALL_EN.md)
- [📖 Документация (RU)](docs/RU/README_ALL_RU.md)

## ⚖️ License / Лицензия

MIT License © 2025 Vladislav Krashevsky

## Contact and support / Контакты и поддержка

Author: Vladislav Krashevsky
Support: ChatGPT and project documentation

## 🖼️ Screenshots

<p align="center"> 
<img src="images/Backup_Kit_Install.png" width="45%"/> 
<img src="images/Backup_Kit_System_backup.png" width="45%"/> </p> 
<p align="center"> 
<img src="images/Backup_Kit_Backup_userdata.png" width="45%"/> 
<img src="images/Backup_Kit_Restore_userdata.png" width="45%"/> </p> 
<p align="center"> 
<img src="images/Backup_Kit_Shotcut_presets_ChatGPTChart.png" width="80%"/> </p> 

