local h = dofile("tests/helpers.lua")
local embed = require("obsidian-bases.embed")

print("embed_spec")

h.test("detects single embed on a line", function()
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "![[People.base]]" })

  local result = embed.get_base_at_line(1, bufnr)
  h.assert_eq(result, "People.base")

  vim.api.nvim_buf_delete(bufnr, { force = true })
end)

h.test("returns nil for non-embed line", function()
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "# Just a heading" })

  local result = embed.get_base_at_line(1, bufnr)
  h.assert_nil(result)

  vim.api.nvim_buf_delete(bufnr, { force = true })
end)

h.test("returns nil for non-base embed", function()
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "![[SomeNote]]" })

  local result = embed.get_base_at_line(1, bufnr)
  h.assert_nil(result)

  vim.api.nvim_buf_delete(bufnr, { force = true })
end)

h.test("detects embed with path prefix", function()
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "![[Templates/Bases/Journal.base]]" })

  local result = embed.get_base_at_line(1, bufnr)
  h.assert_eq(result, "Templates/Bases/Journal.base")

  vim.api.nvim_buf_delete(bufnr, { force = true })
end)

h.test("get_all_embeds finds multiple embeds across lines", function()
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
    "# My Note",
    "![[People.base]]",
    "Some text",
    "![[Journal.base]]",
  })

  local embeds = embed.get_all_embeds(bufnr)
  h.assert_eq(#embeds, 2)
  h.assert_eq(embeds[1].line, 2)
  h.assert_eq(embeds[1].path, "People.base")
  h.assert_eq(embeds[2].line, 4)
  h.assert_eq(embeds[2].path, "Journal.base")

  vim.api.nvim_buf_delete(bufnr, { force = true })
end)

h.test("get_all_embeds finds multiple embeds on same line", function()
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
    "![[A.base]] ![[B.base]]",
  })

  local embeds = embed.get_all_embeds(bufnr)
  h.assert_eq(#embeds, 2)
  h.assert_eq(embeds[1].path, "A.base")
  h.assert_eq(embeds[2].path, "B.base")

  vim.api.nvim_buf_delete(bufnr, { force = true })
end)

h.test("get_all_embeds returns empty for no embeds", function()
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "# Nothing here" })

  local embeds = embed.get_all_embeds(bufnr)
  h.assert_eq(#embeds, 0)

  vim.api.nvim_buf_delete(bufnr, { force = true })
end)

os.exit(h.summary())
