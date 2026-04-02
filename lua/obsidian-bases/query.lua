local M = {}

local resolve_cache = {}

function M.clear_cache()
  resolve_cache = {}
end

---@return string|nil
function M.get_bin()
  local config = require("obsidian-bases.config")
  local bin = config.get().obsidian_bin
  if bin and bin ~= "" then
    return bin
  end
  return nil
end

---@param base_path string
---@param vault_path string
---@return string
local function resolve_path(base_path, vault_path)
  if base_path:match("/") then
    return base_path
  end

  local cache_key = vault_path .. ":" .. base_path
  if resolve_cache[cache_key] then
    return resolve_cache[cache_key]
  end

  local expanded = vim.fn.expand(vault_path)
  local found = vim.fn.globpath(expanded, "**/" .. base_path, false, true)
  local result = base_path
  if found and #found > 0 then
    result = found[1]:sub(#expanded + 2)
  end

  resolve_cache[cache_key] = result
  return result
end

---@param base_path string
---@param view? string
---@return string[]|nil cmd, string|nil error
local function build_cmd(base_path, view)
  if not base_path or base_path == "" then
    return nil, "base_path is required"
  end

  local bin = M.get_bin()
  if not bin then
    return nil, "Obsidian binary not found. Set obsidian_bin in setup()."
  end

  local config = require("obsidian-bases.config")
  local vault = config.current_vault()
  if not vault then
    return nil, "No vault configured. Add vaults = {{ name = '...', path = '...' }} to setup()."
  end
  base_path = resolve_path(base_path, vault.path)

  local vault_name = vault.name
  local cmd
  if vault_name and vault_name ~= "" then
    cmd = { bin, "vault=" .. vault_name, "base:query", "path=" .. base_path, "format=json" }
  else
    cmd = { bin, "base:query", "path=" .. base_path, "format=json" }
  end
  if view then
    table.insert(cmd, "view=" .. view)
  end

  return cmd, nil
end

---@param stdout string
---@param exit_code number
---@param base_path string
---@return table|nil results, string|nil error
local function parse_output(stdout, exit_code, base_path)
  if exit_code ~= 0 then
    local msg = vim.trim(stdout or "")
    if msg == "" then
      msg = "(no output)"
    end
    return nil, "Obsidian CLI failed (exit " .. exit_code .. "): " .. msg
  end

  local trimmed = vim.trim(stdout or "")
  if trimmed == "" then
    return nil, "Obsidian CLI returned empty output for: " .. base_path
  end

  if trimmed:match("^Error:") or trimmed:match("^Unable to") then
    return nil, "Obsidian CLI error: " .. trimmed
  end

  local ok, parsed = pcall(vim.fn.json_decode, trimmed)
  if not ok then
    return nil, "Failed to parse JSON from Obsidian CLI: " .. trimmed
  end
  if type(parsed) ~= "table" then
    return nil, "Unexpected response type from Obsidian CLI: " .. type(parsed)
  end

  return parsed, nil
end

---@param base_path string
---@param view? string
---@return table|nil results, string|nil error
function M.query(base_path, view)
  local cmd, cmd_err = build_cmd(base_path, view)
  if cmd_err then
    return nil, cmd_err
  end

  local result = vim.fn.system(cmd)
  return parse_output(result, vim.v.shell_error, base_path)
end

---@param base_path string
---@param view? string
---@param callback fun(results: table|nil, error: string|nil)
function M.query_async(base_path, view, callback)
  local cmd, cmd_err = build_cmd(base_path, view)
  if cmd_err then
    vim.schedule(function()
      callback(nil, cmd_err)
    end)
    return
  end

  vim.system(cmd, { text = true }, function(obj)
    vim.schedule(function()
      local stdout = obj.stdout or ""
      local results, err = parse_output(stdout, obj.code, base_path)
      callback(results, err)
    end)
  end)
end

return M
