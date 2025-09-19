# README_REINSTALL_SYSTEM.md

[🇬🇧 English](README_REINSTALL_SYSTEM_EN.md) | [🇷🇺 Русский](../RU/README_REINSTALL_SYSTEM_RU.md)

**Author:** Vladislav Krashevskiy
**Support:** ChatGPT

How to install Ubuntu on an SSD and run Backup Kit scripts

---

## Installing Ubuntu on an SSD

1. Install Ubuntu on the SSD as usual.
2. Create one user (e.g., admin) for system administration.
3. Configure system languages ​​and keyboard.
3. The system is ready to run subsequent scripts.

## Executing `hdd-setup-profiles.sh`

- The script is run as root.
- Formats the selected HDD and creates three partitions for users.
- Creates users:
1. `admin` (existing)
2. `USER2` and `USER3` (new users with a temporary password of `password`)
- Adds partition UUIDs to `/etc/fstab` and mounts them.
- Logs are saved to `/mnt/backups/logs/hdd_setup_profiles_restore.log`.

## Installing the multimedia environment `install_mediatools_flatpak.sh`

- The script will automatically check your NVIDIA system for GPU and CUDA support.
- Installs the multimedia environments Shotcut, GIMP+G'MIC, Krita, and Audacity from the Flathub repository.
- Creates directories for the Shotcut Proxy and symbolic links to large file directories. - Configure Shotcut (Proxy + Preview Scaling)
- Create ready-made Shotcut presets for saving
- Test GPU and ffmpeg for Shotcut

## Automatic NVIDIA configuration, GPU passthrough to Flatpak `check-shotcut-gpu.sh`

This script automatically configures NVIDIA, passes the GPU to Flatpak, and tests NVENC for GPU configuration for Shotcut.

## Run `restore.sh`

- Detects the distribution (`ubuntu-22.04`, `ubuntu-24.04`, etc.).
- Runs the corresponding system restore script:
- `restore-ubuntu-XX.XX.sh`
- Restores the system, packages, and configurations to the SSD.

## Running safe-restore-userdata.sh

- This script is best run manually in the local TTY3 console (Cirl+Alt+F3) without a graphical shell.
- Restores home directories and user data from a backup.
- All three users (admin, USER2, USER3) are accessible.

## Changing temporary passwords

After recovery, the administrator changes the temporary passwords for USER2 and USER3 to something secure.
Example:
```bash
passwd USER2
passwd USER3
```

## Installing software from the APT repository

Cleaning up unnecessary repositories and installing software from the APT or Snap repository: VLC, DigiKam, Darktable, KeePassXC, Telegram-desktop, Midnight Commander, ranger, CPU-X.
```bash
install_mediatools_apt.sh
```

## Summary:

- SSD with one user (admin) → HDD with three partitions and users.
- After running restore.sh and safe-restore-userdata.sh, the system is completely restored.
- Temporary passwords are easy to change.

## See also

- SSD + HDD partitioning for Linux (for mounting in Shotcut) see [README_SSD_SETUP_EN.md](README_SSD_SETUP_EN.md)
- Connecting a second drive in Linux see [README_DISK_EN.md](README_DISK_EN.md)
- Reincarnation Backup Kit - Installation and Usage see [README_ALL_EN.md](README_ALL_EN.md)
