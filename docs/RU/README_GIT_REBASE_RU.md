# 🌿 Шпаргалка: безопасный rebase README

[![License: CC BY-SA 4.0](https://licensebuttons.net/l/by-sa/4.0/88x31.png)](https://creativecommons.org/licenses/by-sa/4.0/)

[🇬🇧 English](../EN/README_GIT_REBASE_EN.md) | [🇷🇺 Русский](README_GIT_REBASE_RU.md)

Короткая и безопасная последовательность действий для завершения rebase и публикация README

## Подготовка

Перед rebase убедитесь, что ваши локальные изменения сохранены:
```bash
git status       # проверяем, что рабочая директория чистая
git add .        # или git stash для временного сохранения изменений
```

## Запуск rebase

```bash
git fetch origin
git rebase origin/main
```

> [I] Git попытается применить ваши коммиты поверх main:
> [I] Если нет конфликтов, rebase пройдет автоматически.

## Конфликты при rebase

Если появятся конфликтные маркеры:
```bash
<<<<<<< HEAD
(ваша версия)
=======
(версия из main)
>>>>>>> commit_hash
```

> **HEAD** — ваша локальная версия  
> **commit_hash** — версия из ветки `main`

Действия:
1. Откройте файл в редакторе (например, nano):
```bash
nano docs/EN/README_GIT_BRANCHES_EN.md
```

2. Удалите маркеры <<<<<<<, =======, >>>>>>>.
3. Оставьте финальный текст, который нужен.
4. Cохраните и выйдите (Ctrl+O → Enter → Ctrl+X в nano).

## Пометьте файлы как решённые

```bash
git add docs/EN/README_GIT_BRANCHES_EN.md
git add docs/RU/README_GIT_BRANCHES_RU.md
```

## Продолжите rebase

```bash
git rebase --continue
```

- Если есть ещё конфликты, повторите шаги 3–5 для них.
- Когда конфликтов больше нет, rebase завершится.

Если хотите отменить rebase, используйте:
```bash
git rebase --abort
```

## Проверка состояния

```bash
git status
git log --oneline --graph --decorate -5
```

- Убедитесь, что ветка чистая и все коммиты применены.
- Все ваши README коммиты применены.

## Публикация на GitHub

```bash
git push origin feature/i18n-updates
```

Если история переписана (из-за rebase), безопасно использовать:
```bash
git push --force-with-lease origin feature/i18n-updates
```

> [I] Всегда используйте --force-with-lease, чтобы не перезаписать чужие изменения на сервере.

## Советы

- Всегда сначала pull/fetch, чтобы минимизировать конфликты.
- Сохраняйте резервную копию локальных изменений (git stash), если не уверены.
- Для текстовых файлов (README, docs) проще вручную объединять версии при конфликте.
- Используйте одинаковый стиль коммитов и сообщений, чтобы легко ориентироваться.
