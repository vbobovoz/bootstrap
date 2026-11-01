# Bootstrap

Мой рабочий сетап для macOS и Ubuntu: Ghostty, Zsh, Starship, Neovim,
Lazygit, Yazi и CLI-инструменты. Все собственные настройки хранятся в этой репе, включая полный конфиг Neovim
в `config/nvim`. Отдельные личные репозитории для установки не нужны.

## Новый компьютер

Поддерживаемые цели: macOS с Homebrew и Ubuntu **24.04 / 26.04 LTS**.
Ubuntu-бинарники предусмотрены для amd64 и arm64. Остальные пакетные
бэкенды сохранены, но не считаются проверенными целями этого сетапа.

### macOS

1. Установить Command Line Tools: `xcode-select --install`, дождаться завершения.
2. Установить [Homebrew](https://brew.sh/) и выполнить предложенную им команду
   `brew shellenv` для своего Mac. Bootstrap сам Homebrew не устанавливает.
3. Клонировать репозиторий и запустить установку **от своего пользователя**:

```bash
git clone https://github.com/vbobovoz/bootstrap.git
cd bootstrap
bash install.sh
```

### Ubuntu

Нужны доступ к интернету, `sudo` и репозитории Ubuntu с включённым `universe`.
Установка Ghostty рассчитана на машину с графическим рабочим столом.

```bash
sudo apt-get update
sudo apt-get install -y git ca-certificates
git clone https://github.com/vbobovoz/bootstrap.git
cd bootstrap
bash install.sh
```

Если репозиторий приватный, сначала настроить доступ GitHub и использовать
авторизованный HTTPS либо SSH URL. Приватный GitLab товарища больше не нужен.

Полная установка ставит пакеты, заменяет конфиги с бэкапами, применяет настройки
Git и выбирает Zsh как login shell. Не запускать весь скрипт через `sudo`:
права будут запрошены только для системных операций. На Ubuntu используются
APT и закреплённые релизы Neovim, Node.js, Go, Helm и Tree-sitter с проверкой SHA256;
они размещаются в `/opt/bootstrap` и `/usr/local/bin`. Не добавляется unstable PPA.
На Ubuntu 24.04 Ghostty берётся из закреплённого [community-релиза](https://github.com/mkasberg/ghostty-ubuntu)
с проверкой SHA256, на 26.04 — из APT.
На macOS пакеты ставятся через Homebrew. Node.js проверяется отдельно: нужна
стабильная **26.13.0 LTS или новее**; старая установленная версия больше не
считается достаточной. Если впереди Homebrew стоит старая Node из nvm/asdf/mise,
установщик сообщит об этом вместо ложного успеха.

После установки:

1. Перезайти в систему или открыть новую login shell.
2. Открыть Ghostty: настроены Lilex Nerd Font и размер **13 pt**.
3. Запустить `nvim`, открыть файл проекта, выполнить `:Mason` и дождаться установки
   инструментов текущего языка. Первый запуск скачивает плагины и парсеры; может занять время.
4. В Neovim выполнить `:checkhealth custom` и `:checkhealth vim.lsp`.
5. В терминале: `bash install.sh --check`.

На Ubuntu без GUI, например на сервере, удобнее поставить только Neovim:

```bash
bash install.sh --only neovim
```

Clipboard в SSH-сессии зависит от терминала и окружения; наличие `xclip` /
`wl-clipboard` само по себе не создаёт графическую сессию на сервере.

## Как обновлять

Править исходники в `config/`, коммитить и пушить их в эту репу.
На другом устройстве:

```bash
cd bootstrap
git pull --ff-only
bash install.sh --configs-only
```

Это применяет конфиги **Neovim, Ghostty, Zsh и Starship**, без установки пакетов,
смены login shell и изменения Git-настроек. Если появились новые системные
зависимости, отдельно запустить нужный модуль или полную установку.

| Задача | Команда из корня репозитория |
|---|---|
| Только конфиг Neovim | `bash install.sh --config nvim` |
| Только конфиг Ghostty | `bash install.sh --config ghostty` |
| Только `.zshrc` | `bash install.sh --config zsh` |
| Только Starship | `bash install.sh --config starship` |
| Только настройки Git | `bash install.sh --config git` |
| Конфиги Neovim + Ghostty | `bash install.sh --editor-config-only` |
| Все четыре файловых конфига | `bash install.sh --configs-only` |
| Установить Neovim с зависимостями и конфигом | `bash install.sh --only neovim` |
| Установить Ghostty с конфигом | `bash install.sh --only ghostty` |
| Обновить Node.js и npm | `bash install.sh --only node` |
| Установить шрифт | `bash install.sh --only fonts` |
| Проверить основные команды и версию Neovim | `bash install.sh --check` |
| Все параметры | `bash install.sh --help` |

Для `--only` также доступны `base`, `git`, `zsh`, `starship`, `lazygit`, `yazi`.
Модуль устанавливает свой инструмент и его конфиг, если он есть; `zsh` также
меняет login shell, `git` — глобальные Git-настройки. `--only neovim` не ставит
Ghostty, шрифт, Lazygit и Yazi: их можно добавить отдельно.
Старый флаг `--nvim-config-only` остаётся алиасом `--config nvim`.

После обновления Ghostty: **Cmd+Shift+,** на Mac / **Ctrl+Shift+,** на Linux.
Если в окне менялся масштаб, сбросить его через **Cmd+0 / Ctrl+0**.
После обновления Neovim — перезапустить редактор; после `.zshrc` — новую shell.

## Что внутри

- **Ghostty:** Lilex Nerd Font 13 pt, новый размер не наследует ручной zoom.
- **Zsh:** Zinit, дополнение Tab через fzf-tab, autosuggestions, подсветка команд,
  zoxide, алиасы eza/Git. Плагины скачиваются при первом запуске shell.
- **Neovim 0.12+:** тёмная Kanagawa Wave, логотип NVIM, цветные скобки, путь файла
  справа внизу; Go, Python, Lua, JSON, YAML, GitLab CI, Compose, Kubernetes,
  Helm, Dockerfile и Bash. Go/Python/Lua форматируются при сохранении,
  YAML/Bash — вручную. Автосохранение текущего файла при потере фокуса включено.
  Автоактивации venv и собственного подбора Python-окружения нет.
- **Навигация:** `Space f g` — текст по проекту, `Space f f` — файл,
  `Shift+стрелки` — выделение, `Ctrl+Shift+←/→` — выделение по словам, `y` — копия.
- **CLI:** Git, Lazygit, Yazi, zoxide, eza, btop, rg, fd, fzf, jq, ddgr и инструменты
  превью/архивов. NeoCodeium и Sidekick в Neovim требуют собственной авторизации
  и установленных CLI-агентов; bootstrap учётные данные не переносит.

Подробнее: [настройки Neovim](config/nvim/README.md),
[горячие клавиши](config/nvim/doc/SHORTCUTS.md).

## Конфиги и бэкапы

Конфиги **копируются**, а не связываются с репой. Правки непосредственно в
`~/.config/nvim` и других установленных файлах автоматически назад не попадут.
При замене старый файл/каталог сохраняется рядом с суффиксом `.bak.ДАТА_ВРЕМЯ`.
Neovim сохраняется целым каталогом, включая локальные изменения. Перед возвратом
бэкапа закрыть приложение, отложить текущий конфиг и вернуть бэкап на его место.

Пути: `${XDG_CONFIG_HOME:-$HOME/.config}` для Neovim/Ghostty/Starship,
`${ZDOTDIR:-$HOME}/.zshrc` для Zsh. Существующий конфиг Ghostty в
`~/Library/Application Support/com.mitchellh.ghostty/` может переопределять
настройки из `~/.config/ghostty` на Mac — не держать конфликтующие настройки в двух местах.

Обновления плагинов Neovim (`:lua vim.pack.update()`) меняют установленный
`nvim-pack-lock.json`. После намеренного обновления скопировать его в
`config/nvim/nvim-pack-lock.json`, проверить и закоммитить. При переносе lockfile на существующую установку выполнить
`:lua vim.pack.update(nil, { target = "lockfile" })` и подтвердить изменения.
SSH-ключи,
Git user.name/email, kubeconfig, облачные учётные данные, Docker и доступ к кластерам
на новом компьютере настраиваются отдельно.

## Проверки репозитория

```bash
bash tests/run.sh
make -C config/nvim check
```

Для второй команды нужны Neovim 0.12+, скачанные плагины и StyLua
(устанавливается Mason). Проверки не заменяют запуск GUI и проверку clipboard
в реальной desktop-сессии. Shell-тесты проверяют маршруты CLI, бэкапы,
повторное применение и платформенную логику без установки пакетов в систему.

Результаты проверки платформ и ограничения: [tests/VALIDATION.md](tests/VALIDATION.md).
