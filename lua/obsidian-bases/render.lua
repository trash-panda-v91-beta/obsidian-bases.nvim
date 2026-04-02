local M = {}

local ns_id = vim.api.nvim_create_namespace("obsidian_bases")

local aug = nil
local conceal_attached = {}
local suppressed = {}

local function ensure_augroup()
  if not aug then
    aug = vim.api.nvim_create_augroup("obsidian_bases_conceal", { clear = true })
  end
  return aug
end

---@return table
local function render_opts()
  local cfg = require("obsidian-bases.config").get()
  return cfg.render or {}
end

---@param results table[]
---@return string[]
local function get_columns(results)
  if not results or #results == 0 then
    return {}
  end
  local seen = {}
  local cols = {}
  for _, row in ipairs(results) do
    for k, _ in pairs(row) do
      if k ~= "path" and not seen[k] then
        seen[k] = true
        table.insert(cols, k)
      end
    end
  end
  table.sort(cols)
  return cols
end

---@param val any
---@return string
local function to_str(val)
  if val == nil or val == vim.NIL then
    return ""
  end
  if type(val) == "table" then
    return table.concat(val, ", ")
  end
  return tostring(val)
end

---@param s string
---@return number
local function display_width(s)
  return vim.api.nvim_strwidth(s)
end

---@param s string
---@param max_width number
---@return string
local function truncate(s, max_width)
  if display_width(s) <= max_width then
    return s
  end
  local target = max_width - 3
  if target <= 0 then
    return ("..."):sub(1, max_width)
  end
  local nchars = vim.fn.strchars(s)
  local lo, hi = 1, nchars
  while lo < hi do
    local mid = math.ceil((lo + hi) / 2)
    local part = vim.fn.strcharpart(s, 0, mid)
    if display_width(part) <= target then
      lo = mid
    else
      hi = mid - 1
    end
  end
  return vim.fn.strcharpart(s, 0, lo) .. "..."
end

---@param s string
---@param width number
---@return string
local function pad_to_width(s, width)
  local w = display_width(s)
  if w >= width then
    return s
  end
  return s .. string.rep(" ", width - w)
end

---@param cols string[]
---@param results table[]
---@param max_width number
---@return table<string, number>
local function calc_widths(cols, results, max_width)
  local widths = {}
  for _, col in ipairs(cols) do
    widths[col] = display_width(col)
  end
  for _, row in ipairs(results) do
    for _, col in ipairs(cols) do
      local s = to_str(row[col])
      widths[col] = math.max(widths[col], display_width(s))
    end
  end
  for _, col in ipairs(cols) do
    widths[col] = math.min(widths[col], max_width)
  end
  return widths
end

---@param cols string[]
---@param widths table<string, number>
---@param row table
---@param max_width number
---@return string
local function render_row(cols, widths, row, max_width)
  local cells = {}
  for _, col in ipairs(cols) do
    local s = to_str(row[col])
    s = truncate(s, max_width)
    table.insert(cells, pad_to_width(s, widths[col]))
  end
  return "\226\148\130 " .. table.concat(cells, " \226\148\130 ") .. " \226\148\130"
end

---@param cols string[]
---@param widths table<string, number>
---@param left string
---@param mid string
---@param right string
---@return string
local function render_sep(cols, widths, left, mid, right)
  local parts = {}
  for _, col in ipairs(cols) do
    table.insert(parts, string.rep("\226\148\128", widths[col] + 2))
  end
  return left .. table.concat(parts, mid) .. right
end

---@param cols string[]
---@param widths table<string, number>
---@param results table[]
---@param max_width number
---@return string[]
local function build_lines(cols, widths, results, max_width)
  local lines = {}
  table.insert(lines, render_sep(cols, widths, "\226\148\140", "\226\148\172", "\226\148\144"))
  local header = {}
  for _, col in ipairs(cols) do
    header[col] = col
  end
  table.insert(lines, render_row(cols, widths, header, max_width))
  table.insert(lines, render_sep(cols, widths, "\226\148\156", "\226\148\188", "\226\148\164"))
  for _, row in ipairs(results) do
    table.insert(lines, render_row(cols, widths, row, max_width))
  end
  table.insert(lines, render_sep(cols, widths, "\226\148\148", "\226\148\180", "\226\148\152"))
  return lines
end

---@param bufnr number
local function attach_conceal_handler(bufnr)
  if conceal_attached[bufnr] then
    return
  end
  conceal_attached[bufnr] = true

  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    group = ensure_augroup(),
    buffer = bufnr,
    callback = function()
      if not vim.api.nvim_buf_is_valid(bufnr) then
        conceal_attached[bufnr] = nil
        return true
      end

      local cursor_row = vim.api.nvim_win_get_cursor(0)[1] - 1
      local marks = vim.api.nvim_buf_get_extmarks(bufnr, ns_id, 0, -1, { details = true })
      for _, mark in ipairs(marks) do
        local mark_id = mark[1]
        local mark_row = mark[2]
        local details = mark[4]
        if details.virt_lines then
          if cursor_row == mark_row then
            vim.api.nvim_buf_set_extmark(bufnr, ns_id, mark_row, 0, {
              id = mark_id,
              virt_lines = details.virt_lines,
              virt_lines_above = false,
            })
          else
            local buf_line = vim.api.nvim_buf_get_lines(bufnr, mark_row, mark_row + 1, false)[1]
              or ""
            vim.api.nvim_buf_set_extmark(bufnr, ns_id, mark_row, 0, {
              id = mark_id,
              virt_lines = details.virt_lines,
              virt_lines_above = false,
              conceal = "",
              end_row = mark_row,
              end_col = #buf_line,
            })
          end
        end
      end
    end,
  })
end

---@param bufnr number
---@param line_nr? number 0-indexed
function M.clear(bufnr, line_nr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if line_nr then
    local marks = vim.api.nvim_buf_get_extmarks(bufnr, ns_id, { line_nr, 0 }, { line_nr, -1 }, {})
    for _, mark in ipairs(marks) do
      vim.api.nvim_buf_del_extmark(bufnr, ns_id, mark[1])
    end
  else
    vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
  end
end

---@param bufnr? number
function M.clear_extmarks(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
  if conceal_attached[bufnr] then
    vim.api.nvim_clear_autocmds({ group = ensure_augroup(), buffer = bufnr })
    conceal_attached[bufnr] = nil
  end
end

---@param bufnr? number
function M.clear_all(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  M.clear_extmarks(bufnr)
  suppressed[bufnr] = nil
end

---@param bufnr number
---@param anchor number 0-indexed
---@return boolean
function M.is_suppressed(bufnr, anchor)
  return suppressed[bufnr] and suppressed[bufnr][anchor] or false
end

---@param bufnr number
---@param anchor number 0-indexed
local function suppress(bufnr, anchor)
  if not suppressed[bufnr] then
    suppressed[bufnr] = {}
  end
  suppressed[bufnr][anchor] = true
end

---@param bufnr number
---@param anchor number 0-indexed
local function unsuppress(bufnr, anchor)
  if suppressed[bufnr] then
    suppressed[bufnr][anchor] = nil
  end
end

---@param base_path string
---@param results table[]
---@param line_nr? number 1-indexed
---@param bufnr? number
function M.show(base_path, results, line_nr, bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local ropts = render_opts()
  local max_width = ropts.max_col_width or 40
  local hl = ropts.table_highlight or "Comment"
  local do_conceal = ropts.conceal_embed
  if do_conceal == nil then
    do_conceal = true
  end

  if not results or #results == 0 then
    vim.notify("No results from: " .. base_path, vim.log.levels.INFO)
    return
  end

  local cols = get_columns(results)
  local widths = calc_widths(cols, results, max_width)
  local lines = build_lines(cols, widths, results, max_width)

  local anchor = (line_nr or vim.api.nvim_win_get_cursor(0)[1]) - 1

  local existing = vim.api.nvim_buf_get_extmarks(bufnr, ns_id, { anchor, 0 }, { anchor, -1 }, {})
  if #existing > 0 then
    M.clear(bufnr, anchor)
    suppress(bufnr, anchor)
    return
  end

  unsuppress(bufnr, anchor)

  local virt_lines = {}
  for _, line in ipairs(lines) do
    table.insert(virt_lines, { { line, hl } })
  end

  local extmark_opts = {
    virt_lines = virt_lines,
    virt_lines_above = false,
  }

  if do_conceal then
    extmark_opts.conceal = ""
    extmark_opts.end_row = anchor
    extmark_opts.end_col = #(vim.api.nvim_buf_get_lines(bufnr, anchor, anchor + 1, false)[1] or "")

    if vim.wo.conceallevel == 0 then
      vim.wo.conceallevel = 2
    end
  end

  vim.api.nvim_buf_set_extmark(bufnr, ns_id, anchor, 0, extmark_opts)

  if do_conceal then
    attach_conceal_handler(bufnr)
  end
end

return M
