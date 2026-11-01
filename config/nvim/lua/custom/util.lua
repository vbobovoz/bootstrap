-- Small helpers shared across configuration modules.
-- Required by modules that install GitHub-hosted plugins.

local M = {}

local project = require 'custom.project'
M.project_markers = project.project_markers

--- GitHub URL for `vim.pack.add`.
---@param repo string owner/repo
---@return string
function M.gh(repo) return 'https://github.com/' .. repo end

---@param path? string
---@return string|nil
function M.project_root(path) return project.project_root(path) end

return M
