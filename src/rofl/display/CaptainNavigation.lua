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
  print(math.random())
end

return CaptainDisplayNav
