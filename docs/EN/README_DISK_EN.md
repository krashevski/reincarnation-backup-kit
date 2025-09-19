# Connecting a Second Drive in Linux

[🇬🇧 English](README_DISK_EN.md) | [🇷🇺 Русский](../RU/README_DISK_RU.md)

**Author:** Vladislav Krashevsky
**Support:** ChatGPT

This README describes the process of connecting a second drive in Linux (for example, for storing backups).

---

> [!] Due to its slow performance, an external USB hard drive is not suitable for backing up user data.

## 🔍 1. Identifying the Drive

View the list of drives and partitions:

```bash
lsblk -f
```

or
```bash
sudo fdisk -l
```

Example output:
```bash
sda ext4 Ubuntu-Root
sdb
└─sdb1 ext4 backups
```

> [i] Here, sdb1 is the partition on the second drive.

## 💾 2. Create a file system (for the new drive only!)

> [!} ⚠️ Warning: This operation will delete all data on the partition!
Create an ext4 file system:
```bash
sudo mkfs.ext4 /dev/sdb1
```

## 📂 3. Temporary mounting

Create a directory for mounting and mount the partition:
```bash
sudo mkdir -p /mnt/backups
sudo mount /dev/sdb1 /mnt/backups
```

> [i} The drive is now accessible at /mnt/backups.

## ⚙️ 4. Automatic mounting at boot

To mount the drive automatically, add it to /etc/fstab. Find the partition's UUID:
```bash
sudo blkid /dev/sdb1
```

Example output:
```bash
UUID="df4ca060-a835-463a-8a58-1e34ee8c39db" TYPE="ext4"
```

1. Edit the file:
```bash
sudo nano /etc/fstab
```

2. Add the line:
```bash
UUID=df4ca060-a835-463a-8a58-1e34ee8c39db /mnt/backups ext4 defaults 0 2
```

3. Check for correctness:
```bash
sudo mount -a
```

## 👤 5. Setting permissions Access

To allow the user to work with the disk:
```bash
sudo chown -R $USER:$USER /mnt/backups
```

## 🔧 6. Using with Backup Kit

All Backup Kit scripts use the variable:
```bash
BACKUP_DIR="/mnt/backups"
```

> [i] After connecting and configuring the disk, backups will be saved automatically to /mnt/backups.

## See also

- SSD + HDD partitioning for Linux (for mounting in Shotcut) see [README_SSD_SETUP_EN.md](README_SSD_SETUP_EN.md)
- Reinstalling the operating system see [README_REINSTALL_SYSTEM_EN.md](README_REINSTALL_SYSTEM_EN.md)
- Backup Kit - Installation and Usage see [README_ALL_EN.md](README_ALL_EN.md)
