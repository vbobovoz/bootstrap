# Проверка macOS и Ubuntu — 2026-11-01

| Среда | Что проверено | Результат |
|---|---|---|
| macOS 27.0.1, Apple Silicon | Bash 3.2, shell-тесты, ShellCheck, синтаксис Zsh, `--check`, штатный валидатор Ghostty, изолированный `make check` Neovim | OK |
| Ubuntu 24.04 arm64, Docker | Полная установка, повторное применение, обновление Node, установка всех инструментов Mason, компиляция Treesitter, Go completion, YAML schema diagnostics, Blink, Kanagawa, валидатор Ghostty | OK |
| Ubuntu 26.04 arm64, Docker | Тот же набор проверок, Ghostty из APT, регистрация terminal alternative | OK |
| Ubuntu 24.04 amd64, Docker/эмуляция | `--only neovim`, запуск установленных бинарников, shell-тесты | OK |

На Ubuntu проверены Neovim 0.12.6, Node.js 26.13.0 / npm 11.20.0,
Go 1.27.3, Helm 4.3.1 и Tree-sitter CLI 0.27.1.
На текущем Mac Node обновлена с 26.0.0 до 26.13.0 через `--only node`.

Интеграционный тест реально проверяет наличие всех 18 языковых команд,
загружает парсеры Go/YAML/Helm/Dockerfile/Bash, запрашивает `fmt.Prin` у gopls
и ожидает `Print`, `Printf`, `Println`. YAML-сервер должен выдать диагностику
для строки вместо целого числа по локальной схеме.

В ходе проверки исправлены: неподходящая версия Neovim из APT/unstable PPA,
недостающие инструменты на Ubuntu, старая Node, отсутствие резервного загрузчика
Mason, 24-часовая задержка повторной попытки Mason, проверка Ghostty.app на Mac,
алиас 7-Zip на Ubuntu 26.04 и регистрация Ghostty в alternatives.

## Повторить

Быстрые проверки без системных установок:

```bash
bash tests/run.sh
make -C config/nvim check
```

Полная изолированная проверка с Docker, интернетом и установкой пакетов:

```bash
bash tests/ubuntu-container.sh 24.04
bash tests/ubuntu-container.sh 26.04

# Для полной amd64-проверки на Apple Silicon потребуется эмуляция Docker:
BOOTSTRAP_TEST_PLATFORM=linux/amd64 bash tests/ubuntu-container.sh 24.04
```

Контейнер получает репозиторий только для чтения; домашняя папка и настройки
хоста не подключаются. Контейнер удаляется после завершения. Проверка скачивает
пакеты, плагины и языковые инструменты, поэтому требует нескольких минут.

## Границы проверки

Контейнеры не проверяют реальный GPU/Wayland/X11, desktop clipboard, глобальные
сочетания клавиш Ubuntu и диалог смены login shell. Для финальной проверки GUI
нужно открыть Ghostty на целевой машине. Чистая установка macOS и Intel Mac
не эмулировались. Другие дистрибутивы и версии Ubuntu этим прогоном не покрыты.


## После объединения Neovim из temp/nvim

Повторно прошли расширенные изолированные проверки на macOS: очередь Mason,
Python/Go lint roots, сохранение cwd, сессии, фильтры NeoCodeium, DevOps и
выделение стрелками. Проверены закреплённые версии плагинов из объединённого lockfile.

На Ubuntu 24.04 arm64 заново выполнены полная установка, обновление конфигов,
проверка Ghostty и интеграционный тест всех 18 языковых команд. Результат:
`INTEGRATION_OK: all Mason tools, Treesitter, Go completion, YAML validation, Blink, Kanagawa`.
Добавлена регрессия для отсутствующего в первом runtimepath каталога новых парсеров.

Проверка `tests/standalone.sh` подтверждает отсутствие зависимостей от личных
репозиториев исходного автора и отсутствие удалённой Python-автоматизации.
`temp/` игнорируется Git и не входит в установку. Подробности: [MERGE](../config/nvim/doc/MERGE.md).
