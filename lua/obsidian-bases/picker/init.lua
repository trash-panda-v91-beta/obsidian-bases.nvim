local M = {}

local backends = { "snacks", "mini", "vim_ui" }

---@param results table[]
---@param vault_path string
---@return { text: string, file: string }[]
local function build_items(results, vault_path)
  local items = {}
  for _, row in ipairs(results) do
    local label = row.title or row.name or row.Name or row["file name"] or row.path
    local file = vim.fn.expand(vault_path) .. "/" .. row.path
    table.insert(items, { text = label, file = file })
  end
  return items
end

---@param results table[]
---@param base_path string
function M.pick(results, base_path)
  local config = require("obsidian-bases.config")
  local cfg = config.get()
  local vault = (config.current_vault() or {}).path or ""
  local backend = cfg.picker or "auto"

  local items = build_items(results, vault)
  local title = base_path:match("([^/]+)%.base$") or base_path

  if backend ~= "auto" then
    local pick = require("obsidian-bases.picker." .. backend)
    if not pick(items, title) then
      vim.notify(
        "obsidian-bases: picker '" .. backend .. "' is not available",
        vim.log.levels.ERROR
      )
    end
    return
  end

  for _, name in ipairs(backends) do
    local pick = require("obsidian-bases.picker." .. name)
    if pick(items, title) then
      return
    end
  end
end

return M
