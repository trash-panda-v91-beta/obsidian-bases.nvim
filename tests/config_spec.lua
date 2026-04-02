local h = dofile("tests/helpers.lua")
local config = require("obsidian-bases.config")

print("config_spec")

h.test("get returns defaults before setup", function()
  config.options = nil
  local cfg = config.get()
  h.assert_eq(cfg.auto_render, true)
  h.assert_eq(cfg.render_delay, 100)
  h.assert_eq(cfg.picker, "auto")
  h.assert_eq(cfg.render.max_col_width, 40)
end)

h.test("setup merges user opts over defaults", function()
  config.setup({ render_delay = 200, picker = "snacks" })
  local cfg = config.get()
  h.assert_eq(cfg.render_delay, 200)
  h.assert_eq(cfg.picker, "snacks")
  h.assert_eq(cfg.auto_render, true) -- untouched default
end)

h.test("setup migrates keymap to keys.render", function()
  config.setup({ keymap = "<leader>x" })
  local cfg = config.get()
  h.assert_eq(cfg.keys.render, "<leader>x")
end)

h.test("setup migrates open_keymap to keys.open", function()
  config.setup({ open_keymap = "<leader>y" })
  local cfg = config.get()
  h.assert_eq(cfg.keys.open, "<leader>y")
end)

h.test("setup handles keys = false", function()
  config.setup({ keys = false })
  local cfg = config.get()
  h.assert_eq(cfg.keys, false)
end)

h.test("setup migrates single vault_path to vaults list", function()
  config.setup({ vault_path = "/tmp/vault", vault_name = "test" })
  local cfg = config.get()
  h.assert_eq(#cfg.vaults, 1)
  h.assert_eq(cfg.vaults[1].name, "test")
  h.assert_eq(cfg.vaults[1].path, "/tmp/vault")
end)

h.test("setup validates vault entries", function()
  config.setup({ vaults = { { name = "ok", path = "/tmp" }, { path = "" } } })
  local cfg = config.get()
  h.assert_eq(#cfg.vaults, 1) -- second vault rejected (empty path)
end)

h.test("setup validates vault.name type", function()
  config.setup({ vaults = { { name = 123, path = "/tmp" } } })
  local cfg = config.get()
  h.assert_eq(#cfg.vaults, 0) -- rejected: name is not a string
end)

h.test("setup defaults obsidian_bin to 'obsidian'", function()
  config.setup({})
  local cfg = config.get()
  h.assert_eq(cfg.obsidian_bin, "obsidian")
end)

h.test("current_vault returns nil with no vaults", function()
  config.setup({ vaults = {} })
  h.assert_nil(config.current_vault())
end)

os.exit(h.summary())
