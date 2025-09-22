# Reincarnation Backup Kit — Installation and Usage

[🇬🇧 English](README_EN.md) | [🇷🇺 Русский](../RU/README_RU.md)

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

## Package Contents

### Installation
- `install.sh` — universal installer for the Reincarnation Backup Kit.
1. Determines the distribution and system version.
2. Copies the necessary scripts to `~/bin`.
3. Creates working directories for backups and logs.
4. Checks dependencies (`rsync`, `screen`, `tar`, `gzip`).
5. Copies the `backup_kit` archive package to `/media/backups` if necessary.

### See also
- Reinstalling the operating system, see [README_REINSTALL_SYSTEM_EN.md](README_REINSTALL_SYSTEM_EN.md)
- SSD + HDD partitioning for Linux (for mounting in Shotcut), see [README_SSD_SETUP_EN.md](README_SSD_SETUP_EN.md)
- Connecting a second disk in Linux, see [README_DISK_EN.md](README_DISK_EN.md)

### System backup
- `backup-system.sh` - creates a backup copy of system settings and packages.
- `backup-ubuntu-22.04.sh` — archiving Ubuntu 22.04 packages and configurations.
- `backup-ubuntu-24.04.sh` — archiving Ubuntu 24.04 packages and configurations.
- `backup-debian-12.sh` — archiving Debian 12 packages and configurations.

### System Restore
- `restore-ыныеуь.sh` — a universal system restore script.
- `restore-ubuntu-22.04.sh` — restore for Ubuntu 22.04.
- `restore-ubuntu-24.04.sh` — restore for Ubuntu 24.04.
- `restore-debian-12.sh` — restore for Debian 12.

### Working with User Data
- `backup-restore-userdata.sh` — carefully backup or restore user data.
- `backup-userdata.sh` - creates a backup of user data, a wrapper for `backup-restore-userdata.sh`.
- `restore-userdata.sh` - safely initiates user data recovery, a wrapper for `backup-restore-userdata.sh` automates readiness checks for recovery.

### Additional scripts
- `hdd-setup-profiles.sh` - format the selected hard drive (HDD) and create users.
- `ininstall-mediatools-flatpak.sh` - checks NVIDIA GPU and CUDA and installs the Shotcut, GIMP+G'MIC, Krita, and Audacity multimedia environments, and creates Shotcut presets.
- `check-shotcut-gpu.sh` - automatic NVIDIA configuration, GPU passthrough to Flatpak, and NVENC testing.
- `install-nvidia-cuda.sh` - installation of the NVIDIA and CUDA drivers.
- `install-mediatools-apt.sh` - cleans unnecessary repositories and installs software from the APT repository.
- `check-last-archive.sh` - views archives available to the user.

## Installation and Launch

```bash
git clone https://github.com/username/reincarnation-backup-kit.git
cd reincarnation-backup-kit
./install.sh
```

After installation, all necessary scripts are available from $HOME/bin/

## Usage

### Backup
- For a system backup, use one of the installed scripts, for example:
```bash
./backup-system.sh
```

See also:
To save the Ubuntu 24.04 system configuration: packages, repositories, keys, see the file [README.backup-ubuntu-24.04_EN.md](README.backup-ubuntu-24.04_EN.md)

- To backup user data (can be done in the local TTY3 console [Cirl+Alt+F3]):
```bash
sudo ./backup-userdata.sh backup
```

- Example of a complete archive update (with deletion of the old mirror)
```bash
sudo ./backup-userdata.sh backup --fresh
```

### Format HDD and create users in SSD/HDD logic
```bash
sudo /home/<username>/bin/hdd-setup-profiles.sh
```
### Creating a multimedia environment
```bash
install-mediatools-flatpak.sh
```
> ⚠️ Important: For fast operation of the Shotcut video editor when installing Ubuntu on an SSD, it is necessary to create a partition on the SSD for Shotcut proxy files.

See also:
SSD + HDD partitioning for Linux (for editing in Shotcut) see file [README_SSD_SETUP_EN.md](README_SSD_SETUP_EN.md)

```bash
install-mediatools-apt.sh
```

### Recovery
Run the universal system recovery script:
```bash
./restore-system.sh
```

> [I] The script will automatically detect your system and call the appropriate restore script.

After restoring the system, you can run a script to safely restore user data (this can be done in the local TTY3 console [Cirl+Alt+F3] without a graphical shell):
```bash
sudo ./restore-userdata.sh
```

## ⚖️ License

MIT License © 2025 Vladislav Krashevsky

## Contact and support

**Autor:** Vladislav Krashevsky
**Support:** ChatGPT and project documantation
