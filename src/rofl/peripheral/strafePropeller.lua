---@class rofl.StrafePropeller
---@field speedController cctweaked.peripheral.RotationSpeedController
---@field relativePosition ccTweaked.Vector
---@field name string
---@field private rpm number
local StrafePropeller = {}
StrafePropeller.__index = StrafePropeller

---@param controller cctweaked.peripheral.RotationSpeedController
function StrafePropeller.new(controller, relativePosition, name)
  local self = setmetatable({}, StrafePropeller)

  assert(controller, "StrafePropeller is non-functional without a controller")

  self.speedController = controller
  self.relativePosition = relativePosition
  self.name = name

  return self
end

function StrafePropeller.resetRpm()
  self.rpm = 0
end

function StrafePropeller:setRpm()
  self.rpm = 0
end

function StrafePropeller:getRpm()
  return self.rpm
end

function StrafePropeller:sendRpm()
  self.speedController.setTargetSpeed(self.rpm)
end

return StrafePropeller
