local Display = require("display.init")
local class = require "..class"

---@class rofl.CaptainDisplayNav : rofl.Display
local CaptainDisplayNav = {}

class.derived(CaptainDisplayNav, Display)

---@param monitor string
function CaptainDisplayNav.new(monitor)
  local self = Display.new(monitor)
  self = setmetatable(self, CaptainDisplayNav)
  return self
end

function CaptainDisplayNav:_draw(kernel)
  local propSystem = kernel:getSystem("rofl.PropellerControlSystem")

  local pitch = propSystem.lastPitchCorrection
  local roll = propSystem.lastRollCorrection

  term.clear()
  term.setCursorPos(1, 5)
  print(string.format("Pitch %.2f", pitch))
  print(string.format("Roll %.2f", roll))
end

return CaptainDisplayNav
