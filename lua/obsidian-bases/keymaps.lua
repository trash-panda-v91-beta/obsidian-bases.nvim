local M = {}

M.actions = {}

local function safe(name, fn)
  return function()
    local ok, err = pcall(fn)
    if not ok then
      vim.notify(
        "obsidian-bases action '" .. name .. "' failed: " .. tostring(err),
        vim.log.levels.ERROR
      )
    end
  end
end

M.actions.render = safe("render", function()
  local embed = require("obsidian-bases.embed")
  local query = require("obsidian-bases.query")
  local render = require("obsidian-bases.render")

  local cursor = vim.api.nvim_win_get_cursor(0)
  local path = embed.get_base_at_line(cursor[1])

  if not path then
    vim.notify("No .base embed found on current line", vim.log.levels.WARN)
    return
  end

  local results, err = query.query(path)
  if err or not results then
    vim.notify("obsidian-bases: " .. (err or "no results"), vim.log.levels.ERROR)
    return
  end

  render.show(path, results, cursor[1])
end)

M.actions.open = safe("open", function()
  local embed = require("obsidian-bases.embed")
  local query = require("obsidian-bases.query")
  local picker = require("obsidian-bases.picker")

  local cursor = vim.api.nvim_win_get_cursor(0)
  local path = embed.get_base_at_line(cursor[1])

  if not path then
    vim.notify("No .base embed found on current line", vim.log.levels.WARN)
    return
  end

  local results, err = query.query(path)
  if err or not results then
    vim.notify("obsidian-bases: " .. (err or "no results"), vim.log.levels.ERROR)
    return
  end

  if #results == 0 then
    vim.notify("No results from: " .. path, vim.log.levels.INFO)
    return
  end

  picker.pick(results, path)
end)

M.actions.clear = safe("clear", function()
  require("obsidian-bases.render").clear_all()
end)

local action_desc = {
  render = "Toggle Obsidian base table",
  open = "Open file from base embed",
  clear = "Clear all base tables",
}

---@param keys table<string, string|false>
local function set_buf_keymaps(keys)
  local bufnr = vim.api.nvim_get_current_buf()
  if vim.b[bufnr].obsidian_bases_keymaps then
    return
  end
  vim.b[bufnr].obsidian_bases_keymaps = true

  for action, lhs in pairs(keys) do
    if lhs and lhs ~= false and M.actions[action] then
      vim.keymap.set("n", lhs, M.actions[action], {
        buffer = bufnr,
        noremap = true,
        silent = true,
        desc = action_desc[action] or ("obsidian-bases: " .. action),
      })
    end
  end
end

function M.setup()
  local cfg = require("obsidian-bases.config").get()
  local keys = cfg.keys

  if keys == false then
    return
  end
  if type(keys) ~= "table" then
    return
  end

  local has_any = false
  for _, lhs in pairs(keys) do
    if lhs and lhs ~= false then
      has_any = true
      break
    end
  end
  if not has_any then
    return
  end

  local aug = vim.api.nvim_create_augroup("obsidian_bases_keymaps", { clear = true })

  vim.api.nvim_create_autocmd({ "FileType" }, {
    group = aug,
    pattern = "markdown",
    callback = function()
      set_buf_keymaps(keys)
    end,
  })

  vim.api.nvim_create_autocmd({ "BufEnter" }, {
    group = aug,
    pattern = "*.md",
    callback = function()
      set_buf_keymaps(keys)
    end,
  })

  if vim.bo.filetype == "markdown" or (vim.fn.expand("%:e") == "md") then
    set_buf_keymaps(keys)
  end
end

return M
