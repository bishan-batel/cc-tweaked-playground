---@class rofl.Display
---@field monitor ccTweaked.peripheral.Monitor
---@field refreshRate number
---@field lastDrawTime number
local Display = {}
Display.__index = Display

---@param monitor ccTweaked.peripheral.Monitor
function Display:new(monitor)
  local instance = {
    monitor = monitor,
    refreshRate = 60,
    lastDrawTime = 0,
  }
  setmetatable(instance, self)
  return instance
end

---@param kernel rofl.Kernel
function Display:display(kernel)
  self.lastDrawTime = self.lastDrawTime + kernel.dt

  if self.lastDrawTime > 1.0 / self.refreshRate then
    self.lastDrawTime = 0

    local native = term.native()
    term.redirect(self.monitor)
    self:_draw(kernel)
    term.redirect(native)
  end
end

---@param kernel rofl.Kernel
function Display:_draw(kernel) end

return Display
