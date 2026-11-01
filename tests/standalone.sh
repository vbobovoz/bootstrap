#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

# Imported material is intentionally excluded; no active installer/config may
# depend on the original author's personal repositories.
if rg -n --hidden --glob '!.git/**' --glob '!**/temp/**' \
    '(gitlab[.]com|github[.]com)[:/]ukondoby/' "$ROOT"; then
    printf 'FAIL: found an original-author repository dependency\n' >&2
    exit 1
fi

[[ -f "${ROOT}/config/nvim/init.lua" && -f "${ROOT}/config/nvim/nvim-pack-lock.json" ]]
if rg -n 'python_env|prepare_python_env|PythonEnvRefresh|venv_activation_command|poetry' "${ROOT}/config/nvim/lua"; then
    printf 'FAIL: removed Python environment automation returned\n' >&2
    exit 1
fi
printf 'Standalone repository checks passed\n'
