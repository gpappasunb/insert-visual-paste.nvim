-- lua/insert_visual_paste/init.lua

local M = {}

----------------------------------------------------------------------------
-- Default options
----------------------------------------------------------------------------

M.defaults = {
  -- Insert-mode mapping.
  -- Set to false or "" to disable the default mapping.
  mapping = "<LocalLeader>v",

  -- Modes where the mapping should be created.
  modes = { "i" },

  -- Register used for the temporary paste.
  register = "z",

  -- If true, pressing the mapping leaves insert mode and immediately
  -- enters visual mode.
  start_visual = false,

  -- If true, after pasting, enter insert mode after the pasted text.
  enter_insert = true,

  -- Create user commands:
  --
  --   :InsertVisualPasteCancel
  --   :InsertVisualPasteStart
  --   :InsertVisualPasteFromAbove
  --   :InsertVisualPasteFromBelow
  create_commands = true,

  -- Make the mapping silent.
  silent = true,

  -- If true, create a buffer-local mapping.
  -- If false, create a global mapping.
  buffer = false,

  desc = "Leave insert mode; next visual yank is pasted at original cursor position",
}

M.opts = vim.deepcopy(M.defaults)
M._setup_called = false

----------------------------------------------------------------------------
-- Internal state
----------------------------------------------------------------------------

local state = {
  active = false,
  original_pos = nil,
  mapped = {},
}

local group_name = "InsertVisualPaste"

----------------------------------------------------------------------------
-- Helpers
----------------------------------------------------------------------------

local function clear_group()
  vim.api.nvim_create_augroup(group_name, { clear = true })
end

local function feedkeys(keys)
  keys = vim.api.nvim_replace_termcodes(keys, true, false, true)
  vim.api.nvim_feedkeys(keys, "n", false)
end

local function is_true(value)
  return value == true
    or value == 1
    or value == vim.v["true"]
end

local function get_yank_event(args)
  -- Newer Neovim versions usually provide the payload as args.data.
  if args and type(args.data) == "table" and not vim.tbl_isempty(args.data) then
    return args.data
  end

  -- Fallback to v:event.
  if type(vim.v.event) == "table" and not vim.tbl_isempty(vim.v.event) then
    return vim.v.event
  end

  return nil
end

----------------------------------------------------------------------------
-- Core behavior: visual yank, return to original position, paste
----------------------------------------------------------------------------

function M.cancel()
  state.active = false
  state.original_pos = nil
  clear_group()
end

local function paste_and_enter(pos)
  -- Clear temporary autocom
