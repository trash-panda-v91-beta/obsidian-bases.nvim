# obsidian-bases.nvim

Render [Obsidian Bases](https://obsidian.md/blog/bases/) query results as virtual text tables inside Neovim.

When a markdown file contains `![[Something.base]]`, this plugin queries the Obsidian CLI and displays results as a Unicode box-drawing table below the embed line.

## Requirements

- Neovim >= 0.10
- [Obsidian CLI](https://obsidian.md) (`obsidian` on PATH, or set `obsidian_bin`)
- Obsidian desktop app must be running

## Install

```lua
-- lazy.nvim
{
  "trash-panda-v91-beta/obsidian-bases.nvim",
  ft = "markdown",
  opts = {
    vaults = {
      { name = "my-vault", path = "~/vaults/my-vault" },
    },
    -- obsidian_bin = "/path/to/obsidian", -- if not on PATH
  },
}
```

## Keymaps

No keymaps are set by default. Available actions:

| Action | Description |
|--------|-------------|
| `render` | Toggle base table under cursor |
| `open` | Open file picker from base embed |
| `clear` | Clear all rendered tables |

Configure them via `keys`:

```lua
opts = {
  keys = {
    render = "<leader>ob", -- toggle base table under cursor
    open = "<leader>nb",   -- open file picker from base embed
    clear = "<leader>oc",  -- clear all rendered tables
  },
}
```

Or map actions directly:

```lua
vim.keymap.set("n", "<leader>ob", require("obsidian-bases").actions.render)
vim.keymap.set("n", "<leader>nb", require("obsidian-bases").actions.open)
vim.keymap.set("n", "<leader>oc", require("obsidian-bases").actions.clear)
```

## Options

```lua
{
  vaults = {},                    -- { { name = "...", path = "~/..." }, ... }
  obsidian_bin = nil,             -- defaults to "obsidian" on PATH
  keys = {},                      -- no default keymaps
  auto_render = true,             -- render on file open/save
  render_delay = 100,             -- debounce (ms)
  picker = "auto",                -- "auto" | "snacks" | "mini" | "vim_ui"
  render = {
    max_col_width = 40,           -- truncate columns beyond this width
    table_highlight = "Comment",  -- highlight group for the table
    conceal_embed = true,         -- hide ![[*.base]] line when table is shown
  },
}
```

## License

MIT
