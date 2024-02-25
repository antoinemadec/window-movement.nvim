# window-movement.nvim

Move your windows around with ease.

### Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'antoinemadec/window-movement.nvim',
  lazy = true,
}
```

## Usage

Example of mapping where:
- `Alt + hjkl/arrows` jump in windows
- `Alt + Shift + hjkl/arrows` moves windows arround
- `Alt + q` cycles through the 4 quadrants of the screen
- `Ctrl + Alt + hl/arrows` jump in tabs
- `Ctrl + Alt + Shift + hl/arrows` moves windows arround tabs

```lua
local function remap_arrow_hjkl(mode, lhs, rhs, opt)
  local arrow_hjkl_table = {
    ['<Left>'] = 'h', ['<Down>'] = 'j', ['<Up>'] = 'k', ['<Right>'] = 'l',
    Left = 'h', Down = 'j', Up = 'k', Right = 'l'
  }
  -- arrow mapping
  vim.keymap.set(mode, lhs, rhs, opt)
  -- hjkl mapping
  for arrow, hjkl in pairs(arrow_hjkl_table) do
    if string.find(lhs, arrow) then
      vim.keymap.set(mode, string.gsub(lhs, arrow, hjkl), rhs, opt)
      return
    end
  end
end

for _, mode in pairs({ 'n', 'i', 't' }) do
  local esc_chars = (mode == 'i' or mode == 't') and '<C-\\><C-n>' or ''
  -- window movement
  remap_arrow_hjkl(mode, '<A-Left>', esc_chars .. '<C-w>h', default_opts)
  remap_arrow_hjkl(mode, '<A-Down>', esc_chars .. '<C-w>j', default_opts)
  remap_arrow_hjkl(mode, '<A-Up>', esc_chars .. '<C-w>k', default_opts)
  remap_arrow_hjkl(mode, '<A-Right>', esc_chars .. '<C-w>l', default_opts)
  remap_arrow_hjkl(mode, '<A-S-Left>', function() require('window-movement').move_win_to_direction("left") end, default_opts)
  remap_arrow_hjkl(mode, '<A-S-Down>', function() require('window-movement').move_win_to_direction("down") end, default_opts)
  remap_arrow_hjkl(mode, '<A-S-Up>', function() require('window-movement').move_win_to_direction("up") end, default_opts)
  remap_arrow_hjkl(mode, '<A-S-Right>', function() require('window-movement').move_win_to_direction("right") end, default_opts)
  remap_arrow_hjkl(mode, '<A-q>', function () require('window-movement').quad_win_cycle() end, default_opts)
  -- tab movement
  remap_arrow_hjkl(mode, '<C-A-Left>', esc_chars .. 'gT', default_opts)
  remap_arrow_hjkl(mode, '<C-A-Right>', esc_chars .. 'gt', default_opts)
  remap_arrow_hjkl(mode, '<C-A-S-Left>', function() require('window-movement').move_win_to_tab("prev") end, default_opts)
  remap_arrow_hjkl(mode, '<C-A-S-Right>', function() require('window-movement').move_win_to_tab("next") end, default_opts)
end
```

## Related Projects
