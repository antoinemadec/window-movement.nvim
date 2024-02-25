local Window = {
  win_handle = 0,
  x0 = 0,
  x1 = 0,
  y0 = 0,
  y1 = 0,
}

function Window:new(win_handle)
  local obj = {}
  setmetatable(obj, self)
  self.__index = self
  obj.win_handle = win_handle
  obj.x0 = vim.api.nvim_win_get_position(win_handle)[1]
  obj.x1 = obj.x0 + vim.api.nvim_win_get_height(win_handle)
  obj.y0 = vim.api.nvim_win_get_position(win_handle)[2]
  obj.y1 = obj.y0 + vim.api.nvim_win_get_width(win_handle)
  return obj
end

-- return the list of the neighbors of the window
function Window:get_neighbors()
  local neighbors = {}
  for _, win_handle in ipairs(require("window-movement").get_normal_windows()) do
    local window = Window:new(win_handle)
    if self.x0 - 1 == window.x1 then
      neighbors.up = self:get_closer_window(neighbors.up, window)
    elseif self.x1 + 1 == window.x0 then
      neighbors.down = self:get_closer_window(neighbors.down, window)
    elseif self.y0 - 1 == window.y1 then
      neighbors.left = self:get_closer_window(neighbors.left, window)
    elseif self.y1 + 1 == window.y0 then
      neighbors.right = self:get_closer_window(neighbors.right, window)
    end
  end
  return neighbors
end

-- return the closest window between w0 and w1
function Window:get_closer_window(w0, w1)
  if w0 == nil then
    return w1
  end
  if w1 == nil then
    return w0
  end
  local d0 = math.abs(w0.x0 - self.x0) + math.abs(w0.y0 - self.y0)
  local d1 = math.abs(w1.x0 - self.x0) + math.abs(w1.y0 - self.y0)
  if d0 < d1 then
    return w0
  else
    return w1
  end
end

return Window
