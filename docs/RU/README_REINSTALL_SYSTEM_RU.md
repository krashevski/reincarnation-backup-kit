# README_REINSTALL_SYSTEM.md

[🇬🇧 English](docs/EN/README_REINSTALL_SYSTEM_EN.md) | [🇷🇺 Русский](docs/RU/README_REINSTALL_SYSTEM_RU.md)

**Автор:** Владислав Крашевский
**Поддержка:** ChatGPT

Порядок установки операционной системы Ubuntu на SSD и выполнения скриптов Backup Kit

---

## Установка Ubuntu на SSD

1. Установите Ubuntu на SSD как обычно.
2. Создайте одного пользователя (например, `admin`) для администрирования системы.
3. Настройте языки систем и клавиатуру.
3. Система готова для запуска последующих скриптов.

## Выполнение `hdd-setup-profiles.sh`

- Скрипт выполняется **от root**.
- Форматирует выбранный HDD и создаёт **три раздела** для пользователей.
- Создаёт пользователей:
  1. `admin` (существующий)
  2. `USER2` и `USER3` (новые пользователи с временным паролем `password`)
- Добавляет UUID разделов в `/etc/fstab` и монтирует их.
- Логи сохраняются в `/mnt/backups/logs/hdd_setup_profiles_restore.log`.

## Установка мультимедийной среды `install_mediatools_flatpak.sh`

- Скрипт автоматически проверит систему NVIDIA на поддержку GPU, CUDA.
- Установит мультимедийную среду Shotcut, GIMP+G'MIC, Krita, Audacity из репозитария Flathub.
- Создаст каталоги для Shotcut Proxy и символических ссылок на каталоги больших файлов.
- Настроит Shotcut (Proxy + Preview Scaling)
- Создаст готовые пресеты Shotcut для сохранения
- Протестирует GPU и ffmpeg для Shotcut

## Fвтоматическая настройка NVIDIA, проброс GPU в Flatpak `check-shotcut-gpu.sh`

Скрипт автоматически настраивает NVIDIA, пробрасывает GPU в Flatpak, тестирует NVENC для настрйки GPU при Shotcut.

## Запуск `restore.sh`

- Определяет дистрибутив (`ubuntu-22.04`, `ubuntu-24.04` и т.д.).
- Запускает соответствующий скрипт восстановления системы:
  - `restore-ubuntu-XX.XX.sh`
- Восстанавливает систему, пакеты и конфигурации на SSD.

## Запуск safe-restore-userdata.sh

- Этот скрипт лучше выполнять вручную в локальной консоли TTY3 (Cirl+Alt+F3) без графической оболочки.
- Восстанавливает домашние каталоги и данные пользователей из резервной копии.
- Доступны все три пользователя (admin, USER2, USER3).

## Замена временных паролей

После восстановления администратор меняет временные пароли для USER2 и USER3 на что-то безопасное.
Пример:
```bash
passwd USER2
passwd USER3
```

## Установка софта из репозитария APT

Очистка лишних репозиториев и установка софта из репозитария APT или Snap: VLC, DigiKam, Darktable, KeePassXC, Telegram-desktop, Midnight Commander, ranger, CPU-X.
```bash
install_mediatools_apt.sh
```

## Итог:

- SSD с одним пользователем (admin) → HDD с тремя разделами и пользователями.
- После restore.sh и  safe-restore-userdata.sh система полностью восстановлена.
- Временные пароли легко поменять.

## См. также

- SSD + HDD разметка для Linux (под монтаж в Shotcut) см. файл [README_SSD_SETUP_RU.md](docs/RU/README_SSD_SETUP_RU.md)
- Подключения второго диска в Linux см. файл [README_DISK_RU.md](docs/RU/README_DISK_RU.md)
- Reincarnation Backup Kit — Установка и Использование см. файл [README_ALL_RU.md](docs/RU/README_ALL_RU.md)


