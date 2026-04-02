---@param items { text: string, file: string }[]
---@param title string
---@return boolean
local function pick(items, title)
  local ok, picker = pcall(require, "snacks.picker")
  if not ok then
    return false
  end

  picker.pick({
    title = title,
    items = items,
    format = function(item)
      return { { item.text, "Normal" } }
    end,
    confirm = function(p, item)
      p:close()
      if item then
        vim.cmd("edit " .. vim.fn.fnameescape(item.file))
      end
    end,
  })
  return true
end

return pick
