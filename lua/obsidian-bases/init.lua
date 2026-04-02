local M = {}

function M.setup(opts)
  local config = require("obsidian-bases.config")
  config.setup(opts)
  require("obsidian-bases.keymaps").setup()
  if config.get().auto_render then
    require("obsidian-bases.autocmds").setup()
  end
end

M.actions = setmetatable({}, {
  __index = function(_, key)
    return require("obsidian-bases.keymaps").actions[key]
  end,
})

function M.clear()
  require("obsidian-bases.render").clear_all()
end

function M.clear_cache()
  require("obsidian-bases.query").clear_cache()
end

return M
