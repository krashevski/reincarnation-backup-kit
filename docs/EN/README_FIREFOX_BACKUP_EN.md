# Firefox Backup

[🇬🇧 English](README_FIREFOX_BACKUP_EN.md) | [🇷🇺 Русский](../RU/README_FIREFOX_BACKUP_RU.md)

This README describes the process of archiving and restoring Firefox.

## 🔁 Monthly Archiving Procedure

📅 Once a month
- 📌 Export bookmarks → bookmarks-YYYY-MM.html
- 📦 Archive full profile → firefox-profile-YYYY-MM.tar.gz
- 💾 (optional) copy to external media / DVD / NAS

## Archiving the current Firefox profile

Find the current profile:
1. Open Firefox
2. In the address bar, go to:
```bash
about:profiles
```

3. The working profile should have:
- ✅ This is the default profile
- ✅ Currently in use

The root directory will be set to the path to the working profile.

### Removing obsolete profiles
👉 If the current profile contains all the necessary bookmarks, history, and extensions, then the remaining profiles can be removed.
Refreshing Firefox will make recovery easier.
In about:profiles:
- For profiles you no longer need, click "Delete Profile."
- Agree to delete files (if you definitely don't need them).

### Archive bookmarks only
```bash
# done via the Firefox UI
Menu → Bookmarks → Manage → Import and Backup → Export to HTML
```
and save
```bash
~/backups/REBK/firefox/bookmarks/bookmarks-2026-01.html
```

### 📦 Archive the full Firefox profile

```bash
tar -czf ~/backups/REBK/firefox/profile/firefox-profile-2026-01.tar.gz \
/home/vladislav/snap/firefox/common/.mozilla/firefox/8pefenhl.default-release-3
```

Preserved in full:
- bookmarks
- passwords
- extensions
- settings
- containers
- about:config

## ♻️ Restore (when reinstalling the system)

### Import bookmarks only
```bash
Firefox → Bookmarks → Manage → Import and Backups → Import from HTML
```

### Restore full profile
```bash
cd ~/backups/REBK/firefox/profile
tar -xzf firefox-profile-2026-01.tar.gz -C ~/
```

The archive contains the full profile path and will be restored to its original location.
Then:
```bash
about:profiles → Set as default profile
```

## 🧊 Principles

- ❌ Firefox Sync is not used
- ✅ All data is available offline
- ✅ Recovery is possible without internet connection
