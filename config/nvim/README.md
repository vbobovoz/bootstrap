# Neovim

Исходник конфига — `config/nvim` в bootstrap. Установка на новый компьютер,
обновление и отдельные модули описаны в [основном README](../../README.md).
Только применить конфиг из корня bootstrap:

```bash
bash install.sh --config nvim
```

Текущий каталог Neovim будет сохранён в бэкап и заменён копией из репозитория.
Правки установленной копии автоматически в bootstrap не переносятся.

## Требования и первый запуск

Нужны Neovim **0.12+**, Git, C-компилятор, make, Tree-sitter CLI, Node.js/npm,
curl/unzip, rg и fd. Для Go — Go toolchain, для линтинга Helm — `helm`.
Wget установлен как резервный загрузчик Mason на случай сбоев curl.
`bash install.sh --only neovim` обеспечивает эти зависимости на macOS/Ubuntu.
Для иконок выбрать Nerd Font; отдельная установка: `--only fonts`.

Первый запуск скачивает плагины через `vim.pack` и парсеры Treesitter.
После открытия поддерживаемого файла устанавливаются инструменты именно его
языка. Запросы разных языков выполняются последовательно; `:Mason` показывает
состояние установок. Дождаться завершения и при необходимости переоткрыть файл.
Если скачивание прервалось, повторить установку через `:MasonToolsInstall`.
Проверки: `:checkhealth custom`, `:checkhealth vim.lsp`, `:Mason`.

## Языки и инструменты

| Язык | Инструменты |
|---|---|
| Go | gopls, goimports, gofumpt, golangci-lint |
| Python | Pyright, Ruff |
| Lua | lua-language-server, StyLua |
| JSON | jsonls |
| YAML / GitLab CI / Compose | yamlls, SchemaStore, yamllint, Prettier |
| Kubernetes | YAML-схемы ресурсов |
| Helm | helm-ls, gotmpl/YAML Treesitter |
| Dockerfile | dockerls, Hadolint |
| Bash | bashls, ShellCheck, shfmt |

Mason устанавливает языковые инструменты в каталог данных Neovim. Ошибки
скачивания допускают повторную попытку при следующем открытии типа файла.
Go/Python/Lua форматируются при сохранении. `Space F` форматирует вручную;
YAML и Bash не форматируются автоматически, Helm-шаблоны не форматируются.
Линтеры запускаются при открытии поддерживаемых файлов и после сохранения.
Быстрые последовательные сохранения объединяются; каждый файл проверяется
в своём проекте, без изменения рабочей папки вкладки.

Python-окружение этот конфиг не выбирает и в терминале не активирует.
Настройки Python-проекта можно задать явно в `pyrightconfig.json` / `pyproject.toml`.

Kubernetes-схемы применяются к `k8s/`, `kubernetes/`, `*.k8s.yaml` и `*.k8s.yml`.
Для другого пути или CRD указать схему комментарием в файле:

```yaml
# yaml-language-server: $schema=https://example.org/my-resource-schema.json
```

`NVIM_KUBERNETES_SCHEMA` перед запуском Neovim задаёт URL или абсолютный путь
к нужной версии схемы для манифестов и Helm. Для chart dependencies при необходимости
выполнить `helm dependency build` в проекте. Шаблоны внутри chart `templates/`
и `values*.yaml/yml` обслуживает Helm; обычный yamlls к ним второй раз не подключается.
GitLab CI поддерживает `!reference`.

## Поведение и интерфейс

- Kanagawa Wave с тёмным фоном, цветные скобки, подсветка парной скобки.
- Логотип NVIM, последние файлы и сессии на стартовой странице.
- Полный путь относительно Git/проекта справа внизу, без сокращения каталогов.
- Первый файл проекта задаёт рабочую папку вкладки; другой проект в той же
  вкладке её не меняет. Для переключения использовать новую вкладку, projects picker или `:tcd`.
- Текущий изменённый файл автоматически сохраняется при потере фокуса.
- Встроенный терминал не выполняет команды активации venv/Poetry.
- Сессии сохраняются автоматически только после создания/подключения именованной сессии;
  сохраняются рабочие папки отдельных вкладок.
- NeoCodeium даёт inline AI-подсказки при настроенной авторизации. Sidekick работает
  с отдельно установленными CLI-агентами. Обычное LSP-дополнение от AI не зависит.
- Neotest запускает Go/Python-тесты; pytest устанавливается в окружение проекта отдельно.

## Основные клавиши

`Space` — leader. Сочетания нажимаются последовательно из Normal mode (`Esc`).

| Клавиши | Действие |
|---|---|
| `Space f g` | Поиск текста по проекту |
| `Space f f` | Поиск файла |
| `Space f w` | Поиск слова под курсором / выделения |
| `Space o` / `\` | Yazi / дерево файлов Snacks |
| `gd` / `gr` | Определение / использования |
| `Space Space` | LazyGit, если установлен |
| `Ctrl+Space` | Меню дополнения |
| `Ctrl+n/p`, Enter | Выбрать / принять дополнение |
| `Shift+стрелки` | Выделить текст, в том числе из Insert mode |
| `Ctrl+←/→` | Переход по словам |
| `Ctrl+Shift+←/→` | Выделение по словам |
| `y` | Скопировать выделение в системный clipboard |
| `Space F` | Форматировать |
| `Ctrl+\` | Встроенный терминал |
| `Space t n/f/l` | Ближайший тест / файл / повторить запуск |

Выделение заканчивается перед курсором. Обычная стрелка или Escape снимает его.
После копирования для продолжения ввода нажать `i`.
Ghostty переключает свои панели через `Cmd+Ctrl+стрелки` (на Linux — `Super+Ctrl`).
Полная таблица: [doc/SHORTCUTS.md](doc/SHORTCUTS.md).

## Обновление и диагностика

`:lua vim.pack.update()` обновляет плагины. После намеренного обновления вернуть
установленный `nvim-pack-lock.json` в bootstrap и закоммитить.

Если не работает LSP: проверить `:Mason`, `:checkhealth vim.lsp`, `go version` /
`node --version` и порядок команд в `PATH`. Для clipboard на Linux нужны рабочая
X11/Wayland-сессия и `xclip`/`wl-clipboard`; в SSH условия отличаются.

Из каталога конфигурации `make check` проверяет Lua, StyLua, запуск, определение
проектов/типов файлов и выделение стрелками. Нужны скачанные плагины и StyLua.

Основа — [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim), MIT.
См. [LICENSE.md](LICENSE.md).


## Дополнения из объединённого конфига

- `Space l` — переименование, code actions, implementations, типы, символы и документация LSP.
- `Space u a/f/d/r/c/n` — переключатели autosave, format-on-save, диагностики,
  относительных номеров, Treesitter-контекста и AI в текущем буфере.
- `Space g a/r/h` — stage, reset и preview Git hunk; `Space g f` / `Space g L` — история файла/строки.
- mini.move и mini.jump дополняют сохранённые Flash, mini.ai и mini.surround;
  автопары остаются на nvim-autopairs, панели — bufferline/lualine.

Настройка машины: [SETUP](doc/SETUP.md). Поведение: [WORKFLOWS](doc/WORKFLOWS.md).
Сопровождение: [MAINTENANCE](doc/MAINTENANCE.md). Решения объединения: [MERGE](doc/MERGE.md).
