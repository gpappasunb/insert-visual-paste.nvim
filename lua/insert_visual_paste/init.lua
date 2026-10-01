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
  --   :InsertVisualPasteCancel
  --   :InsertVisualPasteStart
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
-- Core behavior
----------------------------------------------------------------------------

function M.cancel()
  state.active = false
  state.original_pos = nil
  clear_group()
end

local function paste_and_enter(pos)
  -- Clear temporary autocommands before entering insert mode again.
  M.cancel()

  if not pos or pos[2] == 0 then
    return
  end

  -- If the original position was in another buffer, try to switch back.
  if pos[1] and pos[1] ~= 0 and vim.api.nvim_get_current_buf() ~= pos[1] then
    pcall(vim.api.nvim_set_current_buf, pos[1])
  end

  -- Jump back to the saved cursor position.
  vim.fn.setpos(".", pos)

  local reg = M.opts.register or "z"

  local keys
  if M.opts.enter_insert then
    -- Paste register, jump to end of pasted text, append.
    keys = string.format('"%sp`]a', reg)
  else
    -- Paste register, jump to end of pasted text, stay in normal mode.
    keys = string.format('"%sp`]', reg)
  end

  feedkeys(keys)
end

function M.start()
  state.active = true
  state.original_pos = nil
  clear_group()

  local mode = vim.api.nvim_get_mode().mode
  local in_insert_mode = mode:match("^i") ~= nil

  -- If the user enters insert mode before yanking, cancel the operation.
  vim.api.nvim_create_autocmd("InsertEnter", {
    group = group_name,
    once = true,
    callback = function()
      if state.active then
        M.cancel()
      end
    end,
  })

  if in_insert_mode then
    -- Save the position when leaving insert mode.
    vim.api.nvim_create_autocmd("InsertLeave", {
      group = group_name,
      once = true,
      callback = function()
        if state.active then
          state.original_pos = vim.fn.getpos(".")
        end
      end,
    })
  else
    -- If started from normal mode, save current position immediately.
    state.original_pos = vim.fn.getpos(".")
  end

  -- Wait for a visual-mode yank.
  vim.api.nvim_create_autocmd("TextYankPost", {
    group = group_name,
    callback = function(args)
      if not state.active then
        return
      end

      local ev = get_yank_event(args)
      if not ev then
        return
      end

      local is_yank = ev.operator == "y"
      local is_visual = is_true(ev.visual)

      if not is_yank or not is_visual then
        return
      end

      if ev.regcontents == nil then
        return
      end

      -- Copy the yanked text into the configured register.
      vim.fn.setreg(M.opts.register or "z", ev.regcontents, ev.regtype)

      local pos = state.original_pos
      state.active = false

      vim.schedule(function()
        paste_and_enter(pos)
      end)
    end,
  })

  if in_insert_mode then
    if M.opts.start_visual then
      feedkeys("<Esc>v")
    else
      feedkeys("<Esc>")
    end
  else
    if M.opts.start_visual then
      feedkeys("v")
    end
  end
end

----------------------------------------------------------------------------
-- Setup
----------------------------------------------------------------------------

function M.setup(opts)
  M.opts = vim.tbl_extend("force", M.defaults, opts or {})
  M._setup_called = true

  -- Remove mappings created by a previous setup() call.
  for _, map in ipairs(state.mapped) do
    pcall(vim.keymap.del, map.mode, map.lhs, { buffer = map.buffer })
  end
  state.mapped = {}

  -- Create user commands.
  if M.opts.create_commands then
    vim.api.nvim_create_user_command("InsertVisualPasteCancel", function()
      M.cancel()
    end, { force = true })

    vim.api.nvim_create_user_command("InsertVisualPasteStart", function()
      M.start()
    end, { force = true })
  end

  -- Create mapping.
  if M.opts.mapping and M.opts.mapping ~= "" then
    local modes = M.opts.modes or { "i" }
    if type(modes) == "string" then
      modes = { modes }
    end

    local buffer = M.opts.buffer or false
    if buffer == true then
      buffer = vim.api.nvim_get_current_buf()
    end

    for _, map_mode in ipairs(modes) do
      vim.keymap.set(map_mode, M.opts.mapping, function()
        M.start()
      end, {
        silent = M.opts.silent ~= false,
        noremap = true,
        buffer = buffer,
        desc = M.opts.desc,
      })

      table.insert(state.mapped, {
        mode = map_mode,
        lhs = M.opts.mapping,
        buffer = buffer,
      })
    end
  end
end

return M
