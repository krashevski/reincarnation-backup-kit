# 📝 Мини-шпаргалка по Git

Краткий набор команд для удобной работы с Git и GitHub.
Этих команд достаточно для повседневной работы над проектом.

## 🔄 Добавление и сохранение изменений
### Проверить статус (что изменилось)
```bash
git status
```

### Добавить все изменённые файлы
```bash
git add .
```

### Сделать коммит с сообщением
- Новая функциональность: 
```bash
git commit -m "feat: описание изменений"
```

- Документация:
```bash
git commit -m "docs: описание изменений"
```

- Исправление ошибок: 
```bash
git commit -m "fix: опечатки в ..."
```

- Исправление конкретного кейса:
```bash 
git commit -m "fix: robust printf в msg() для обработки --fresh и подобных аргументов"
``` 
- Правка для безопасности:
```bash
git commit -m "fix(security): exclude archive disk from formatting" -m "Added a safety check to prevent accidental formatting of the archive disk.
The selected backup disk is now excluded from the list of available disks for formatting.

Limitation on the maximum number of users is still pending and will be added in a future update."
```

- Исправление ссылок на изображения
```bash 
git commit -m "fix: image links in README files"
```

## 🚀 Отправка изменений на GitHub
### Отправить изменения в ветку main
```bash
git push origin main
```

## 📥 Получение обновлений из GitHub
### Подтянуть последние изменения из main
```bash
git pull origin main
```

## 📝 Полезные проверки
### Посмотреть историю коммитов
```bash
git log --oneline --graph --decorate --all
```

### Проверить подключение удалённого репозитория
```bash
git remote -v
```

## 📌 Рекомендуемая последовательность работы
```bash
git status
git add .
git commit -m "..."
git push origin main
```
