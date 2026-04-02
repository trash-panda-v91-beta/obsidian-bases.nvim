---@param items { text: string, file: string }[]
---@param title string
---@return boolean
local function pick(items, title)
  vim.ui.select(items, {
    prompt = title .. " > ",
    format_item = function(item)
      return item.text
    end,
  }, function(choice)
    if choice then
      vim.cmd("edit " .. vim.fn.fnameescape(choice.file))
    end
  end)
  return true
end

return pick
