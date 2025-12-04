# 🌿 Работа с ветками Git и GitHub

[![License: CC BY-SA 4.0](https://licensebuttons.net/l/by-sa/4.0/88x31.png)](https://creativecommons.org/licenses/by-sa/4.0/)

[🇬🇧 English](../EN/README_GIT_BRANCHES_EN.md) | [🇷🇺 Русский](README_GIT_BRANCHES_RU.md)

Краткая инструкция по безопасной работе с ветками в репозитории Reincarnation Backup Kit.

## Основные ветки

| Ветка                   | Назначение                                                               |
| ----------------------- | ------------------------------------------------------------------------ |
| `main`                  | Основная защищённая ветка. Содержит стабильную версию проекта.           |
| `local-working-version` | Ветка для локальной работы и экспериментов.                              |
| `feature/...`           | Ветки для новых функций или изменений (например `feature/i18n-updates`). |
| `backup-before-*`       | Резервные ветки перед крупными изменениями.                              |

## 🆕 Создание новой feature-ветки
### Переключаемся на main и подтягиваем последние изменения
```bash
git checkout main
git pull origin main
```

### Создаём новую ветку для работы над задачей
```bash
git checkout -b feature/i18n-updates
```

> [I] Все коммиты лучше делать в этой ветке.

Для синхронизации с GitHub:
```bash
git push -u origin feature/i18n-updates
```

## 🔀 Pull Request (слияние изменений в main)
1. На GitHub откройте репозиторий → вкладка Pull requests → New pull request.
2. Установите:
   1. base: main
   2. compare: ваша feature-ветка
3. В форме для существующих измененений напишите заголовок и описание изменений.
4. Нажмите Create pull request → Merge pull request (после проверки).
5. После слияния ветка feature может быть удалена для чистоты истории.

## 💾 Создание резервной ветки перед крупными изменениями
```bash
git checkout main
git branch backup-before-i18n
git push origin backup-before-i18n
```

> [I] Это позволяет всегда сохранить текущее состояние перед масштабными изменениями.

## 🔍 Проверка состояния веток
### Все локальные ветки
```bash
git branch -vv
```

### Все ветки на GitHub
```bash
git fetch origin
git branch -r
```

## Рекомендации по работе

- Никогда не пушьте напрямую в main, если включена защита ветки.
- Перед слиянием убедитесь, что все локальные изменения закоммичены.
- Используйте feature-ветки для новых задач и экспериментов.
- Создавайте резервные ветки перед критическими изменениями.

## 📝 Мини-последовательность работы с README через ветку feature/update-readme
1. Перейти в ветку документации:
```bash
git checkout feature/update-readme
```

2. Подтянуть последние изменения с GitHub
```bash
git fetch origin
git rebase origin/feature/update-readme
```

##№ Смотри также
- Шпаргалка: безопасный rebase README [README_GIT_REBASE_RU.md](README_GIT_REBASE_RU.md)

3. Внести изменения в локальные файлы README:
- docs/RU/README_GIT_REBASE_RU.md
- docs/EN/README_GIT_REBASE_EN.md

4. Добавить изменения в индекс:
```bash
git add docs/RU/README_GIT_REBASE_RU.md
git add docs/EN/README_GIT_REBASE_EN.md
```

5. Создать коммит:
```bash
git commit -m "Обновление README_GIT_REBASE: исправления и дополнения"
```

6. Отправить изменения на GitHub:
```bash
git push origin feature/update-readme
```

> ⚠️ Команда git push сама не создаёт PR (Pull Request), но гарантирует, что на сервере есть актуальная версия ветки для PR.

## 📝 Мини-последовательность обновление main из feature-ветки для README

1. Перейти в main и обновить с GitHub:
```bash
git checkout main
git pull origin main
```

2. Слить изменения из feature-ветки:
```bash
git merge feature/update-readme
```

3. Разрешите возможные конфликты (если видны <<<<<<<, =======, >>>>>>> в открывшемся файле, оставьте нужный текст и сохраните файл).

4. Запушьте обновлённый main на GitHub:
```bash
git push origin main
```

## 🌳 О схеме ветвления

Наглядно: 
```text
      main
       |
       | Pull / Merge
       |
backup-before-i18n   ← Резервная ветка перед крупными изменениями
       |
       |
feature/i18n-updates  ← Ветка для новой функции или изменения
       |
       | Работа и коммиты
       |
feature/fix-bug       ← Другая feature-ветка
       |
       | Merge Pull Request
       |
      main
```
      
Объяснение схемы:
1. main — основная защищённая ветка, содержит стабильную версию проекта.
2. backup-before-* — создаётся перед крупными изменениями, чтобы можно было быстро откатиться.
3. feature/... — ветки для работы над конкретной задачей или новой функцией.
4. Merge Pull Request — после завершения работы feature-ветки изменения сливаются в main через Pull Request.
5. После слияния feature-ветка может быть удалена, а main остаётся защищённой.

## Смотри также

- Шпаргалка: безопасный rebase README [README_GIT_REBASE_RU.md](README_GIT_REBASE_RU.md)
- Мини-шпаргалка по Git [README_GIT_RU.md](README_GIT_RU.md)
