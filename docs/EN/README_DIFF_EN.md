# README_DIFF.md — Using Backup Kit Diff Patches

[🇬🇧 English](README_DIFF_EN.md) | [🇷🇺 Русский](../RU/README_DIFF_RU.md)

## 1️⃣ Preparation

Suppose you have two versions of a directory:
Old version: backup-old/
New version: backup/

Change to the directory that contains both:
```bsh
cd /path/to/parent_directory
```

## 2️⃣ Creating a Diff Patch

```bash
diff -ruN backup-old backup > backup-update.patch
```

Explanations:
- -r — recursive, through all subfolders.
- -u — unified format (easy to read, standard for patches).
- -N — include new files not present in the old version.
- > — save the result to the file backup_kit_update.patch.

## 3️⃣ Applying a Patch

On another machine or an older version of backup-old, you can apply the patch like this:
```bash
patch -p1 -d backup-old < backup-update.patch
```

- -p1 removes one directory level (backup-old/).
- -d — specifies the working directory where to apply the patch.

After this, your old version will be updated to the new one.

## 4️⃣ Tips

- Before applying the patch, it is recommended to make a backup copy of the old directory.
- The diff patch will contain only the changes and new files, without duplicating everything.
- If necessary, you can create patches for individual scripts in a similar manner.

## See also:

- To save the Ubuntu 24.04 system configuration: packages, repositories, keys, see the file [README.backup-ubuntu-24.04_EN.md](README.backup-ubuntu-24.04_EN.md)
