-- golangci-lint >= 2.1: no synchronous process probes during initialization.
-- Keep package/file targeting dynamic so buffers from different modules can coexist.
local severities = {
  error = vim.diagnostic.severity.ERROR,
  warning = vim.diagnostic.severity.WARN,
  refactor = vim.diagnostic.severity.INFO,
  convention = vim.diagnostic.severity.HINT,
}

local function canonical(path) return vim.fs.normalize(vim.uv.fs_realpath(path) or path) end

return {
  cmd = 'golangci-lint',
  append_fname = false,
  args = {
    'run',
    '--allow-serial-runners',
    '--output.json.path=stdout',
    '--output.text.path=',
    '--output.tab.path=',
    '--output.html.path=',
    '--output.checkstyle.path=',
    '--output.code-climate.path=',
    '--output.junit-xml.path=',
    '--output.teamcity.path=',
    '--output.sarif.path=',
    '--issues-exit-code=0',
    '--show-stats=false',
    '--path-mode=abs',
    function()
      local path = vim.api.nvim_buf_get_name(0)
      return vim.fs.root(path, 'go.mod') and vim.fs.dirname(path) or path
    end,
  },
  stream = 'stdout',
  parser = function(output, bufnr, cwd)
    if output == '' then return {} end
    local decoded = vim.json.decode(output)
    local issues = decoded.Issues
    if issues == nil or issues == vim.NIL then return {} end

    local current = canonical(vim.api.nvim_buf_get_name(bufnr))
    local diagnostics = {}
    for _, issue in ipairs(issues) do
      local path = issue.Pos.Filename
      if vim.fn.isabsolutepath(path) == 0 then path = vim.fs.joinpath(cwd, path) end
      if canonical(path) == current then
        local line = math.max(0, issue.Pos.Line - 1)
        local col = math.max(0, issue.Pos.Column - 1)
        diagnostics[#diagnostics + 1] = {
          lnum = line,
          end_lnum = line,
          col = col,
          end_col = col,
          severity = severities[issue.Severity] or vim.diagnostic.severity.WARN,
          source = issue.FromLinter,
          message = issue.Text,
        }
      end
    end
    return diagnostics
  end,
}
