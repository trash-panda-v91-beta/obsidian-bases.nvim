local M = {}

---@param line_nr number 1-indexed
---@param bufnr? number
---@return string|nil
function M.get_base_at_line(line_nr, bufnr)
  bufnr = bufnr or 0
  local line = vim.api.nvim_buf_get_lines(bufnr, line_nr - 1, line_nr, false)[1]
  if not line then
    return nil
  end
  local path = line:match("!%[%[(.-)%.base%]%]")
  if path then
    return path .. ".base"
  end
  return nil
end

---@param bufnr? number
---@return { line: number, path: string }[]
function M.get_all_embeds(bufnr)
  bufnr = bufnr or 0
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local embeds = {}
  for i, line in ipairs(lines) do
    for path in line:gmatch("!%[%[(.-)%.base%]%]") do
      table.insert(embeds, { line = i, path = path .. ".base" })
    end
  end
  return embeds
end

return M
