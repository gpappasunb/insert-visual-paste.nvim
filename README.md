# insert-visual-paste.nvim

Leave insert mode, visually yank some text, and paste it back at the original cursor position.

## Setup

```lua
require("insert_visual_paste").setup({
  mapping = "<LocalLeader>v",
  register = "z",
  start_visual = false,
  enter_insert = true,
})

```

## Usage

In insert mode, press `<LocalLeader>v`, visually select some text, then yank it with `y`.
The yanked text will be pasted at the original cursor position, and Neovim will return to insert mode. Also, the last yanked text is placed in register `z`
