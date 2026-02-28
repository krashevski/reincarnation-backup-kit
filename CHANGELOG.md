# Changelog — Reincarnation Backup Kit

All changes follow [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) and the project uses [Semantic Versioning](https://semver.org/).

## [2.0.0] - 2026-02-28
### Added
- Bash library of common functions.
- Centralized translation system (i18n) with language support:
  - Russian
  - English
  - Japanese

### Changed
- Completely redesigned the REBK installation directory structure.
- Changed the backup directory structure.

### Breaking Changes
- REBK installation paths and backup directories have been changed; user scripts and documentation need to be updated.

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

