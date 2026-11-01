# Установка

Единственный репозиторий: `https://github.com/vbobovoz/bootstrap`.
Конфиг Neovim входит в него как `config/nvim`; отдельно клонировать его не нужно.

Из корня bootstrap:

```bash
bash install.sh --only neovim  # редактор, зависимости и конфиг
bash install.sh --only fonts  # Nerd Font, если нужен
```

На настроенной машине достаточно `bash install.sh --config nvim`.
Для существующих плагинов после переноса lockfile:

```vim
:lua vim.pack.update(nil, { target = 'lockfile' })
```

Просмотреть и подтвердить изменения, затем перезапустить Neovim. Это синхронизирует
плагины с версиями из твоей репы, вместо произвольного обновления до latest.

Предпосылки macOS/Ubuntu, Homebrew, новые устройства и бэкапы:
[основной README](../../../README.md). Сторонние плагины и официальные инструменты
скачиваются при установке. Личные репозитории исходного автора не используются.

Инструменты Mason ставятся по первому открытию соответствующего языка.
Например, Go запрашивает gopls/goimports/gofumpt/golangci-lint, YAML —
yamlls/Prettier/yamllint, Bash — bashls/ShellCheck/shfmt. `:Mason` показывает состояние.

AI-подсказки обслуживает NeoCodeium; для сервиса нужна собственная авторизация.
Sidekick использует твои отдельно установленные CLI-агенты.
