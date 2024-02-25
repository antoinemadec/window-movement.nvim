local M = {}
local a = vim.api
local Window = require("window-movement.window")

-- save window options of win
---@param win integer: window handle
function M.save_win_opts(win)
  local win_opts = {}
  for opt_name, dict in pairs(a.nvim_get_all_options_info()) do
    if dict['scope'] == 'win' then
      win_opts[opt_name] = a.nvim_get_option_value(opt_name, { win = win })
    end
  end
  return win_opts
end

-- restore window options win_opts inside win
---@param win integer: window handle
---@param win_opts table: options returned by save_win_opts
function M.restore_win_opts(win, win_opts)
  for opt_name, val in pairs(win_opts) do
    pcall(a.nvim_set_option_value, opt_name, val, { win = win })
  end
end

-- copy src_win to dst_win, close src_win, jump in dst_win
---@param src_win integer: window handle
---@param dst_win integer: window handle
function M.move_win(src_win, dst_win)
  local src_win_cursor = a.nvim_win_get_cursor(src_win)
  local src_win_opts = M.save_win_opts(src_win)
  local src_buf = a.nvim_win_get_buf(src_win)

  M.restore_win_opts(dst_win, src_win_opts)
  a.nvim_win_set_buf(dst_win, src_buf) -- opening a buffer messes up the window opts
  M.restore_win_opts(dst_win, src_win_opts)
  a.nvim_win_set_cursor(dst_win, src_win_cursor)

  a.nvim_win_close(src_win, true)
end

-- swap win_1 and win_2
---@param win_1 integer: window handle
---@param win_2 integer: window handle
function M.swap_win(win_1, win_2)
  local win_cursor_1 = a.nvim_win_get_cursor(win_1)
  local win_cursor_2 = a.nvim_win_get_cursor(win_2)
  local win_opts_1 = M.save_win_opts(win_1)
  local win_opts_2 = M.save_win_opts(win_2)
  local buf_1 = a.nvim_win_get_buf(win_1)
  local buf_2 = a.nvim_win_get_buf(win_2)
  -- src -> dst
  M.restore_win_opts(win_2, win_opts_1)
  a.nvim_win_set_buf(win_2, buf_1) -- opening a buffer messes up the window opts
  M.restore_win_opts(win_2, win_opts_1)
  a.nvim_win_set_cursor(win_2, win_cursor_1)
  -- dst -> src
  M.restore_win_opts(win_1, win_opts_2)
  a.nvim_win_set_buf(win_1, buf_2) -- opening a buffer messes up the window opts
  M.restore_win_opts(win_1, win_opts_2)
  a.nvim_win_set_cursor(win_1, win_cursor_2)
end

-- swap current window and jump in its neighbor
---@param direction string #String "up" "down" "left" or "right"
function M.move_win_to_direction(direction)
  local current_window = Window:new(0)
  local current_neighbors = current_window:get_neighbors()
  local destination_window = current_neighbors[direction]
  if destination_window ~= nil then
    M.swap_win(current_window.win_handle, destination_window.win_handle)
    a.nvim_set_current_win(destination_window.win_handle)
  else
    local letter = {
      up = "K",
      down = "J",
      left = "H",
      right = "L",
    }
    vim.cmd([[execut "normal \<C-w>]] .. letter[direction] .. '"')
  end
end

-- move current window into next or previous tab
---@param dest string #String "next" or "prev"
function M.move_win_to_tab(dest)
  local is_next = dest == "next"
  local tabs = a.nvim_list_tabpages()
  local wins = a.nvim_tabpage_list_wins(0)
  local src_tab = a.nvim_tabpage_get_number(0)
  local src_win = a.nvim_get_current_win()
  local first_last_cond = src_tab == (is_next and #tabs or 1)
  local go_tab_cmd = is_next and "tabnext" or "tabprev"
  local new_tab_cmd = is_next and "tab split" or "0tab split"

  if #wins == 1 and first_last_cond then
    return
  end

  local vim_cmds = {}
  if first_last_cond then
    table.insert(vim_cmds, new_tab_cmd)
  else
    table.insert(vim_cmds, go_tab_cmd)
    table.insert(vim_cmds, "sp")
  end
  vim.cmd(table.concat(vim_cmds, " | "))

  M.move_win(src_win, 0)
end

-- get non floating/relative windows
function M.get_normal_windows()
  local normal_windows = {}
  for _, window in ipairs(a.nvim_tabpage_list_wins(0)) do
    local config = a.nvim_win_get_config(window)
    if config.relative == "" then
      table.insert(normal_windows, window)
    end
  end
  return normal_windows
end

-- cycle 4 windows
--    a | b | c | d
-- into
--    a | b
--    c | d
-- into
--    a | c
--    b | d
function M.quad_win_cycle()
  local windows = M.get_normal_windows()
  if #windows ~= 4 then
    vim.notify("windows number is different from 4")
    return
  end

  if not vim.t.quad_win_cycle_idx or vim.t.quad_win_cycle_idx > 2 then
    vim.t.quad_win_cycle_idx = 0
  end

  local cur_win = a.nvim_get_current_win()

  if vim.t.quad_win_cycle_idx == 0 then
    for _, win in ipairs(windows) do
      a.nvim_set_current_win(win)
      vim.cmd("wincmd J")
    end
    for _, i in ipairs({ 1, 3 }) do
      a.nvim_set_current_win(windows[i + 1])
      vim.cmd("vsplit")
      M.move_win(windows[i], 0)
      if windows[i] == cur_win then
        cur_win = a.nvim_get_current_win()
      end
    end
  end

  if vim.t.quad_win_cycle_idx >= 1 then
    M.swap_win(windows[2], windows[3])
  end

  if vim.t.quad_win_cycle_idx == 2 then
    windows = M.get_normal_windows()
    for _, win in ipairs(windows) do
      a.nvim_set_current_win(win)
      vim.cmd("wincmd L")
    end
  end

  a.nvim_set_current_win(cur_win)
  vim.t.quad_win_cycle_idx = vim.t.quad_win_cycle_idx + 1
end

-- toggle side bar: open and populate or close it
---@param win_name string: window name
---@param create_win_func function: function called to populate the side bar
function M.toggle_side_bar(win_name, create_win_func)
  if vim.t[win_name] then
    vim.api.nvim_win_close(vim.t[win_name], true)
    vim.t[win_name] = nil
  else
    create_win_func()
    vim.cmd("wincmd L")
    vim.cmd("vertical resize 40")
    vim.wo.winfixwidth = true
    vim.wo.number = false
    vim.wo.relativenumber = false
    vim.t[win_name] = vim.api.nvim_get_current_win()
    vim.cmd("wincmd p")
  end
end

return M
