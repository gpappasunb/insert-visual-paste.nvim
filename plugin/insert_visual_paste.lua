if vim.g.loaded_insert_visual_paste == 1 then
  return
end

vim.g.loaded_insert_visual_paste = 1

local ok, insert_visual_paste = pcall(require, "insert_visual_paste")

if not ok then
  return
end

-- If you want to disable automatic zero-config setup, set:
--
--   vim.g.insert_visual_paste_no_auto_setup = 1
--
-- before the plugin loads, then call require("insert_visual_paste").setup()
-- yourself.
if vim.g.insert_visual_paste_no_auto_setup == 1 then
  return
end

-- Zero-config default setup.
-- If you call setup() yourself, that will override these defaults.
if not insert_visual_paste._setup_called then
  insert_visual_paste.setup()
end
