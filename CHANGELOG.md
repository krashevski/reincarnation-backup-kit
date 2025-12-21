# Changelog — Reincarnation Backup Kit

Все изменения следуют [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) и проект использует [Semantic Versioning](https://semver.org/).

## [1.0.0] - 2025-12-18
### Added
- Initial release of **Reincarnation Backup Kit**.
- Bash scripts for:
  - System backup (`backup-system.sh`) and restore (`restore-system.sh`).
  - User data backup (`backup-userdata.sh`) and restore (`restore-userdata.sh`).
  - Disk formatting, user creation and symlink management (`hdd-setup-profiles.sh`, `setup-symlinks.sh`).
  - System mounts overview (`show-system-mounts.sh`).
  - Text menu interface (`menu.sh`) with multilingual support (i18n).
  - Utility scripts: `install.sh`, `check-last-archive.sh`, `check-cuda-tools.sh`.
- Idempotent, Ansible-style logic in all scripts.
- Multi-user aware, safe for repeated runs.
- Automatic backup via cron.
- i18n support: English and Russian.
- Screenshots and documentation included.

### Changed
- N/A (first release)

### Fixed
- N/A (first release)

