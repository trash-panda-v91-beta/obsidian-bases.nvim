---@param items { text: string, file: string }[]
---@param title string
---@return boolean
local function pick(items, title)
  local ok, mini_pick = pcall(require, "mini.pick")
  if not ok then
    return false
  end

  local labels = {}
  for _, item in ipairs(items) do
    table.insert(labels, item.text)
  end

  mini_pick.start({
    source = {
      name = title,
      items = labels,
      choose = function(idx)
        if idx then
          local item = items[idx]
          vim.cmd("edit " .. vim.fn.fnameescape(item.file))
        end
      end,
    },
  })
  return true
end

return pick
