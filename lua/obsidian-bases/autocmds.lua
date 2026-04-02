local M = {}

---@param bufnr number
local function render_all_embeds(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  local embed = require("obsidian-bases.embed")
  local query = require("obsidian-bases.query")
  local render = require("obsidian-bases.render")

  render.clear_extmarks(bufnr)

  local embeds = embed.get_all_embeds(bufnr)
  for _, e in ipairs(embeds) do
    local anchor = e.line - 1
    if not render.is_suppressed(bufnr, anchor) then
      query.query_async(e.path, nil, function(results, err)
        if not vim.api.nvim_buf_is_valid(bufnr) then
          return
        end
        if not err and results then
          render.show(e.path, results, e.line, bufnr)
        end
      end)
    end
  end
end

function M.setup()
  local cfg = require("obsidian-bases.config").get()
  local delay = cfg.render_delay or 100

  local aug = vim.api.nvim_create_augroup("obsidian_bases_auto_render", { clear = true })

  vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
    group = aug,
    pattern = "*.md",
    callback = function(ev)
      local bufnr = ev.buf
      vim.defer_fn(function()
        render_all_embeds(bufnr)
      end, delay)
    end,
  })
end

return M
