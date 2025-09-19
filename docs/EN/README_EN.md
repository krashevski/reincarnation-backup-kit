# Backup Kit — Ubuntu System Backup & Restore

[🇬🇧 English](docs/EN/README_EN.md) | [🇷🇺 Русский](docs/RU/README_RU.md)

**Reincarnation Backup Kit** is a set of Bash scripts for backup and restore when reinstalling **Ubuntu** on an SSD, as well as for creating a multimedia environment (Shotcut, GIMP+G'MIC, Krita, Audacity).

## ✨ Features

### 📦 Backup and Restore
Consists of two independent parts:
1. **System Backup** — system configuration, package lists, repositories.
2. **User Backup** — home directories (`/home/...`), documents, and personal data.

> ⚠️ Important: Both parts complement each other. You can use only the system backup, only the user backup, or both at once.

### 🎬 Multimedia Environment
Consists of two steps:
1. **Format** the selected HDD and create users.
2. **NVIDIA GPU and CUDA testing**, software installation:
   - [Shotcut](https://shotcut.org/) (video editor)
   - [GIMP+G'MIC](https://gmic.eu/) (graphics)
   - [Krita](https://krita.org/en/) (drawing)
   - [Audacity](https://www.audacityteam.org/) (sound)
   - creating presets for Shotcut

> ⚠️ Important: You can use the multimedia environment setup independently, without backup.

## 🚀 Quick Usage

```bash
git clone https://github.com/username/reincarnation-backup-kit.git
cd reincarnation-backup-kit
./install.sh

# Backup example
./backup-ubuntu-24.04.sh
./backup-restore-userdata.sh backup

# Example of a complete archive update (with deletion of the old mirror)
sudo ./backup-restore-userdata.sh backup --fresh

# Restore example
./restore-ubuntu-24.04.sh
./backup-restore-userdata.sh restore
```

## 📜 Available Scripts

- `install.sh` — universal installer for the Reincarnation Backup Kit.
- `backup-ubuntu-22.04.sh` — archiving Ubuntu 22.04 packages and configurations.
- `backup-ubuntu-24.04.sh` — archiving Ubuntu 24.04 packages and configurations.
- `backup-debian-12.sh` — archiving Debian 12 packages and configurations.
- `restore.sh` — universal system restore script.
- `restore-ubuntu-22.04.sh` — restore for Ubuntu 22.04.
- `restore-ubuntu-24.04.sh` — restore for Ubuntu 24.04.
- `restore-debian-12.sh` — restore for Debian 12.
- `backup-restore-userdata.sh` — carefully backup or restore user data.
- `safe-restore.sh` — safely initiates user data recovery, a wrapper for backup-restore-userdata.sh automates the restore readiness check.
- `hdd-setup-profiles.sh` — format the selected hard drive (HDD) and create users.
- `install-mediatools-apt.sh` —  installs multimedia software from APT.
- `check-shotcut-gpu.sh` — automatic NVIDIA configuration, GPU passthrough to Flatpak, and NVENC testing.
- `install-nvidia-cuda.sh` - установка драйвера NVIDIA и CUDA.
- `install-mediatools-flatpak.sh` — checks NVIDIA GPU and CUDA, installs multimedia software from Flathub (Shotcut, GIMP+G'MIC, Krita, Audacity) and creates Shotcut presets.
- `check-last-archive.sh` — views archives available to the user.

## ⚖️ License

MIT License © 2025 Vladislav Krashevsky

## 📬 Contact & Support

Author: Vladislav Krashevsky
Support: ChatGPT + project documentation

## 🖼️ Screenshots

<p align="center"> 
<img src="images/Backup_Kit_Install.png" width="45%"/> 
<img src="images/Backup_Kit_System_backup.png" width="45%"/> </p> 
<p align="center"> 
<img src="images/Backup_Kit_Backup_userdata.png" width="45%"/> 
<img src="images/Backup_Kit_Restore_userdata.png" width="45%"/> </p> 
<p align="center"> 
<img src="images/Backup_Kit_Shotcut_presets_ChatGPTChart.png" width="80%"/> </p> 


