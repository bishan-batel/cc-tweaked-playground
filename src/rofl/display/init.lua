---@class rofl.Display
---@field monitor ccTweaked.peripheral.Monitor
---@field refreshRate number
---@field lastDrawTime number
local Display = {}
Display.__index = Display

---@param monitor ccTweaked.peripheral.Monitor|string
---@return rofl.Display
function Display.new(monitor)
  if type(monitor) == "string" then
    monitor = peripheral.wrap(monitor) --[[@as ccTweaked.peripheral.Monitor]]
    assert(monitor)
  end

  local instance = {
    monitor = monitor,
    refreshRate = 1,
    lastDrawTime = math.random(),
  }
  setmetatable(instance, Display)
  return instance
end

---@param kernel rofl.Kernel
function Display:display(kernel)
  self.lastDrawTime = self.lastDrawTime + kernel.dt
  local renderDelay = (1.0 / (self.refreshRate + 1))

  -- print(self.refreshRate)

  if self.lastDrawTime > renderDelay then
    self.lastDrawTime = 0

    local old = term.redirect(self.monitor)
    self:_draw(kernel)
    term.redirect(old)
  end
end

---@param kernel rofl.Kernel
function Display:init(kernel) _ = kernel end

---@param kernel rofl.Kernel
function Display:_draw(kernel) _ = kernel end

return Display
