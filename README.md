# insert-visual-paste.nvim

`insert-visual-paste.nvim` is a small Neovim plugin for copying a visually selected piece of text and pasting it back at the cursor position where you originally stopped editing.

The main workflow is:

1. You are in insert mode
2. You press a key (default <LocalLeader>v) to leave insert mode
3. You move elsewhere and visually select some text
4. You yank it with `y`
5. The plugin jumps back to your original cursor position
6. It pastes the yanked text
7. It enters insert mode again

This is useful when you are typing something and realize you want to reuse a word, phrase, or small piece of text from somewhere else in the buffer.

---

## Features

- Leaves insert mode and remembers your original cursor position
- Waits for the next visual-mode yank
- Copies the yanked text into a configurable register, default `z`
- Jumps back to the original position
- Pastes the selected text there
- Returns to insert mode automatically
- Optional mode to enter visual mode immediately
- Configurable mapping and register
- Small and dependency-free

---

## Requirements

- Neovim 0.8 or newer.

---

## How it works

Starting in insert mode:

```text
The quick brown fox jumps over the lazy |dog.
```

Press the plugin mapping, for example:

```text
<LocalLeader>v
```

Neovim leaves insert mode and remembers that cursor position.

Then move elsewhere, visually select some text:

```text
fox
```

Press:

```text
y
```

The plugin will paste `fox` back at the original cursor position and re-enter insert mode.

---

## Installation

### lazy.nvim

Using your GitHub repository:

```lua
{
  "gpappasunb/insert-visual-paste.nvim",
  config = function()
    require("insert_visual_paste").setup({
      mapping = "<LocalLeader>v",
      register = "z",
      start_visual = false,
      enter_insert = true,
    })
  end,
}
```

---

## Suggested key mappings

Add these lines to your lua configuration file:

```lua
vim.keymap.set({ 'n', 'i' }, '<LocalLeader>yj', '<cmd>InsertVisualPasteFromBelow<CR>', {
  silent = true,
  desc = 'Paste rest of line below at cursor',
})

vim.keymap.set({ 'n', 'i' }, '<LocalLeader>yk', '<cmd>InsertVisualPasteFromAbove<CR>', {
  silent = true,
  desc = 'Paste rest of line above at cursor',
})
```


### Note about `<LocalLeader>`

The default mapping uses `<LocalLeader>`.

If you have not configured `maplocalleader`, Neovim often uses `\` as the default.

You may want to set it explicitly near the top of your `init.lua`, before loading plugins:

```lua
vim.g.maplocalleader = ","
```

Then the default plugin mapping becomes:

```text
,v
```

---

## Setup

```lua
require("insert_visual_paste").setup()
```

This uses the default configuration.

For custom behavior, pass a table:

```lua
require("insert_visual_paste").setup({
  mapping = "<LocalLeader>v",
  modes = { "i" },
  register = "z",
  start_visual = false,
  enter_insert = true,
  create_commands = true,
  silent = true,
  buffer = false,
  desc = "Leave insert mode; next visual yank is pasted at original cursor position",
})
```

---

## Configuration options

### `mapping`

Type: `string | false`

Default:

```lua
mapping = "<LocalLeader>v"
```

The key used to start the plugin.

Example:

```lua
require("insert_visual_paste").setup({
  mapping = "<LocalLeader>p",
})
```

Disable the default mapping:

```lua
require("insert_visual_paste").setup({
  mapping = false,
})
```

---

### `modes`

Type: `string[]`

Default:

```lua
modes = { "i" }
```

Modes where the mapping should be created.

Usually you only need insert mode:

```lua
modes = { "i" }
```

---

### `register`

Type: `string`

Default:

```lua
register = "z"
```

The register used to temporarily store the visually yanked text.

Example:

```lua
require("insert_visual_paste").setup({
  register = "q",
})
```

Note: this plugin copies the visually yanked text into this register. The normal yank operation still happens, so the unnamed register may also be affected depending on your Neovim configuration.

---

### `start_visual`

Type: `boolean`

Default:

```lua
start_visual = false
```

If `false`, pressing the mapping leaves insert mode and puts you in normal mode.

If `true`, pressing the mapping leaves insert mode and immediately enters visual mode.

Example:

```lua
require("insert_visual_paste").setup({
  start_visual = true,
})
```

---

### `enter_insert`

Type: `boolean`

Default:

```lua
enter_insert = true
```

If `true`, Neovim enters insert mode after pasting.

If `false`, Neovim stays in normal mode after pasting.

Example:

```lua
require("insert_visual_paste").setup({
  enter_insert = false,
})
```

---

### `create_commands`

Type: `boolean`

Default:

```lua
create_commands = true
```

Creates user commands:

```vim
:InsertVisualPasteStart
:InsertVisualPasteCancel
```

To disable them:

```lua
require("insert_visual_paste").setup({
  create_commands = false,
})
```

---

### `silent`

Type: `boolean`

Default:

```lua
silent = true
```

Whether the created mapping should be silent.

Example:

```lua
require("insert_visual_paste").setup({
  silent = false,
})
```

---

### `buffer`

Type: `boolean`

Default:

```lua
buffer = false
```

If `true`, the mapping is created for the current buffer only.

Example:

```lua
require("insert_visual_paste").setup({
  buffer = true,
})
```

Usually you want the global mapping, so leave this as `false`.

---

### `desc`

Type: `string`

Default:

```lua
desc = "Leave insert mode; next visual yank is pasted at original cursor position"
```

The description shown by plugins like `which-key.nvim`.

Example:

```lua
require("insert_visual_paste").setup({
  desc = "Paste next visual yank at previous insert position",
})
```

---

## Usage

### Start from insert mode

In insert mode, press your configured mapping:

```text
<LocalLeader>v
```

Then:

1. Move to the text you want to copy.
2. Visually select it using `v`, `V`, or `Ctrl-v`.
3. Yank it with `y`.

The plugin will:

1. Copy the yanked text into the configured register.
2. Jump back to the original cursor position.
3. Paste the text.
4. Enter insert mode.

---

### Start manually from normal mode

You can also start the behavior manually:

```vim
:InsertVisualPasteStart
```

If you run this from normal mode, the plugin saves the current cursor position as the target position.

Then visually select some text and yank it.

---

## Commands

If `create_commands` is enabled, the following commands are available.

### `:InsertVisualPasteStart`

Starts the plugin manually.

Useful if you disabled the mapping or want to trigger the behavior from normal mode.

```vim
:InsertVisualPasteStart
```

### `:InsertVisualPasteCancel`

Cancels the current waiting state.

```vim
:InsertVisualPasteCancel
```

You can also cancel by entering insert mode again before yanking.

---

## Example configurations

### Minimal setup

```lua
require("insert_visual_paste").setup()
```

### Enter visual mode immediately

```lua
require("insert_visual_paste").setup({
  start_visual = true,
})
```

### Stay in normal mode after pasting

```lua
require("insert_visual_paste").setup({
  enter_insert = false,
})
```

### Use a different register

```lua
require("insert_visual_paste").setup({
  register = "q",
})
```

### Disable the mapping and use commands only

```lua
require("insert_visual_paste").setup({
  mapping = false,
})
```

Then use:

```vim
:InsertVisualPasteStart
```

---

## Troubleshooting

### The mapping does nothing

Check that `maplocalleader` is set if you are using `<LocalLeader>`:

```lua
vim.g.maplocalleader = ","
```

Make sure this line runs before the plugin is configured.

You can also use a normal mapping instead:

```lua
require("insert_visual_paste").setup({
  mapping = "<leader>vp",
})
```

---

### The text is not pasted

Make sure you are yanking the visual selection with:

```text
y
```

This plugin reacts to a visual-mode yank. It does not trigger on visual-mode delete or change.

---

### The plugin pastes from the wrong register

Check the configured register:

```lua
require("insert_visual_paste").setup({
  register = "z",
})
```

Make sure you are not overriding register `z` elsewhere.

---

## License

MIT
