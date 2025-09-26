# Backup Kit — Резервное копирование и восстановление системы Ubuntu

[🇬🇧 English](../EN/README_EN.md) | [🇷🇺 Русский](README_RU.md)

**Reincarnation Backup Kit** — это набор Bash-скриптов для резервного копирования и восстановления при переустановке **Ubuntu** на SSD, а также для создания мультимедийного окружения (Shotcut, GIMP+G'MIC, Krita, Audacity).

## ✨ Возможности

### 📦 Резервное копирование и восстановление
Состоит из двух независимых частей:
1. **Резервное копирование системы** — конфигурация системы, списки пакетов, репозитории.
2. **Резервное копирование пользователя** — домашние каталоги (`/home/...`), документы и личные данные.

> ⚠️ Важно: обе части дополняют друг друга. Вы можете использовать только резервную копию системы, только резервную копию пользователя или обе сразу.

### 🎬 Мультимедийная среда
Состоит из двух шагов:
1. **Форматирование** выбранного жёсткого диска и создание пользователей.
2. **Тестирование видеокарты NVIDIA и CUDA**, установка программного обеспечения:
- [Shotcut](https://shotcut.org/) (видеоредактор)
- [GIMP+G'MIC](https://gmic.eu/) (графика)
- [Krita](https://krita.org/en/) (рисование)
- [Audacity](https://www.audacityteam.org/) (звук)
- создание шаблонов для Shotcut

> ⚠️ Важно: Вы можете использовать настройку мультимедийной среды независимо, без резервной копии.

## Текстовое меню Reincarnation Backup Kit

После установки вы можете использовать простое текстовое меню:
```bash
~/bin/menu.sh
```

> ⚠️ Меню запустится автоматически после успешной установки.
> ⚠️ Для некоторых операций требуются права root (sudo).


## 🚀 Быстрое использование

```bash
git clone https://github.com/username/reincarnation-backup-kit.git
cd reincarnation-backup-kit
./install.sh

# Пример резервного копирования
./backup-system.sh
sudo ./backup-userdata.sh

# Пример полное обновление архива (с удалением старого зеркала)
sudo ./backup-userdata.sh --fresh

# Пример восстановления
./restore-system.sh
sudo ./restore-userdata.sh
```

## 📜 Доступные скрипты

- `install.sh` — универсальный установщик для Reincarnation Backup Kit.
- `backup-system.sh` - резервное копирование системных настроек и пакетов (оболочка).
- `backup-ubuntu-22.04.sh` — резервное копирование Ubuntu 22.04.
- `backup-ubuntu-24.04.sh` — резервное копирование Ubuntu 24.04.
- `backup-debian-12.sh` — резервное копирование Debian 12.
- `restore-system.sh` — универсальное восстановление системы (оболочка).
- `restore-ubuntu-22.04.sh` — восстановление для Ubuntu 22.04.
- `restore-ubuntu-24.04.sh` — восстановление для Ubuntu 24.04.
- `restore-debian-12.sh` — восстановление для Debian 12.
- `backup-restore-userdata.sh` — резервное копирование и восстановление пользовательских данных.
- `backup-userdata.sh` - резервное копирование пользовательских данных (оболочка для backup-restore-userdata.sh).
- `restore-userdata.sh` — безопасное восстановление данных (оболочка для backup-restore-userdata.sh).
- `hdd-setup-profiles.sh` — форматирование HDD и создание пользователей.
- `install-mediatools-apt.sh` — установка мультимедиа из APT.
- `check-shotcut-gpu.sh` — автоконфигурация NVIDIA, проброс GPU в Flatpak, тестирование NVENC.
- `install-nvidia-cuda.sh` - установка драйвера NVIDIA и CUDA.
- `install-mediatools-flatpak.sh` — проверка NVIDIA + CUDA, установка мультимедиа из Flathub, пресеты Shotcut.
- `check-last-archive.sh` — просмотр доступных архивов.
- `add-cron-backup.sh` - добавление задания cron для ежедневного резервного копирования.
- `cron-backup-userdata.sh` - выполняет архивирование данных пользователя в /mnt/backups/user_data/.
- `clean-backup-logs.sh` - удаление старые журналы резервного копирования. 
- `remove-cron-backup.sh` - удаляет cron-задачу резервного копирования.
- `show-system-mounts.sh` - Просмотр точек монтирования системы, символических ссылок и заданий cron.
- `check-cuda-tools.sh` - проверка и управление CUDA Toolkit.
- `menu.sh` - Текстовое меню для Reincarnation Backup Kit.

## ⚖️ Лицензия

Лицензия MIT © 2025 Владислав Крашевский

## 📬 Контакты и поддержка

Автор: Владислав Крашевский
Поддержка: ChatGPT + документация проекта

## 🖼️ Скриншоты

<p align="center"> 
<img src="../../images/Backup_Kit_Install.png" width="45%"/> 
<img src="../../images/Backup_Kit_Text_Menu.png" width="45%"/> </p>  </p> 
<p align="center"> 
<img src="../../images/Backup_Kit_System_backup.png" width="45%"/>
<img src="../../images/Backup_Kit_Backup_userdata.png" width="45%"/> </p> 
<p align="center"> 
<img src="../../images/Backup_Kit_System_Mounts.png" width="45%"/>
<img src="../../images/Backup_Kit_Shotcut_presets_ChatGPTChart.png" width="45%"/> </p> 
