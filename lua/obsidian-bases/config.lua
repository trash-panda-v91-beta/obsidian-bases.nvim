local M = {}

---@class ObsidianBasesConfig
---@field obsidian_bin string|nil
---@field vaults { name: string, path: string }[]
---@field vault_path string|nil
---@field vault_name string|nil
---@field keys table<string, string|false>|false
---@field auto_render boolean
---@field render { max_col_width: number, table_highlight: string, conceal_embed: boolean }
---@field picker "auto"|"snacks"|"mini"|"vim_ui"
---@field render_delay number

M.defaults = {
  obsidian_bin = nil,
  vaults = {},
  vault_path = nil,
  vault_name = nil,
  keys = {},
  auto_render = true,
  render = {
    max_col_width = 40,
    table_highlight = "Comment",
    conceal_embed = true,
  },
  picker = "auto",
  render_delay = 100,
}

---@type ObsidianBasesConfig|nil
M.options = nil

---@param vault table
---@param idx number
---@return boolean
local function validate_vault(vault, idx)
  if type(vault) ~= "table" then
    vim.notify(
      string.format("obsidian-bases: vaults[%d] must be a table, got %s", idx, type(vault)),
      vim.log.levels.ERROR
    )
    return false
  end
  if not vault.path or vault.path == "" then
    vim.notify(
      string.format("obsidian-bases: vaults[%d].path is required", idx),
      vim.log.levels.ERROR
    )
    return false
  end
  if vault.name ~= nil and type(vault.name) ~= "string" then
    vim.notify(
      string.format(
        "obsidian-bases: vaults[%d].name must be a string, got %s",
        idx,
        type(vault.name)
      ),
      vim.log.levels.ERROR
    )
    return false
  end
  return true
end

function M.setup(opts)
  opts = opts or {}

  if opts.keymap ~= nil or opts.open_keymap ~= nil then
    if not opts.keys then
      opts.keys = {}
    end
    if opts.keymap ~= nil then
      opts.keys.render = opts.keymap
      opts.keymap = nil
    end
    if opts.open_keymap ~= nil then
      opts.keys.open = opts.open_keymap
      opts.open_keymap = nil
    end
  end

  local keys_override = nil
  if opts.keys == false then
    keys_override = false
    opts.keys = nil
  end

  M.options = vim.tbl_deep_extend("force", {}, M.defaults, opts)

  if keys_override == false then
    M.options.keys = false
  end

  if #M.options.vaults == 0 and M.options.vault_path and M.options.vault_path ~= "" then
    M.options.vaults = {
      { name = M.options.vault_name or "", path = M.options.vault_path },
    }
  end

  local valid_vaults = {}
  for i, vault in ipairs(M.options.vaults) do
    if validate_vault(vault, i) then
      table.insert(valid_vaults, vault)
    end
  end
  M.options.vaults = valid_vaults

  if not M.options.obsidian_bin or M.options.obsidian_bin == "" then
    M.options.obsidian_bin = "obsidian"
  end
end

---@return ObsidianBasesConfig
function M.get()
  if not M.options then
    return M.defaults
  end
  return M.options
end

---@return { name: string, path: string }|nil
function M.current_vault()
  local opts = M.get()
  if not opts.vaults or #opts.vaults == 0 then
    return nil
  end

  local bufpath = vim.fn.expand("%:p")
  for _, vault in ipairs(opts.vaults) do
    local expanded = vim.fn.expand(vault.path)
    if expanded:sub(-1) ~= "/" then
      expanded = expanded .. "/"
    end
    if bufpath:sub(1, #expanded) == expanded then
      return vault
    end
  end

  vim.notify(
    "obsidian-bases: current buffer is not inside any configured vault, using '"
      .. opts.vaults[1].path
      .. "'",
    vim.log.levels.WARN
  )
  return opts.vaults[1]
end

return M
