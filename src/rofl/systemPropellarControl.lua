local System = require("system")
local Propellar = require("propellar")

---@class rofl.PropellarControlSystem : rofl.System
---@field private propellars [rofl.Propellar]
local PropellarControlSystem = {}

PropellarControlSystem.__index = PropellarControlSystem

---@param rofl rofl.Roflcopter
function PropellarControlSystem.new(rofl)
  local instance = System.new("rofl.PropellarControlSystem", rofl)
  setmetatable(instance, PropellarControlSystem)

  return instance
end

function PropellarControlSystem:_init()
  self.propellars = {
    self:makePropellar("Create_RotationSpeedController_7", "tilt_adapter_4", true),
    self:makePropellar("Create_RotationSpeedController_5", "tilt_adapter_5",
      false),
    self:makePropellar("Create_RotationSpeedController_4", "tilt_adapter_6",
      false),
    self:makePropellar("Create_RotationSpeedController_6", "tilt_adapter_7",
      true),
  }
end

---@private
---@param speed string
---@param tilt string
---@param inverse? boolean
function PropellarControlSystem:makePropellar(speed, tilt, inverse)
  return Propellar.new(
    peripheral.wrap(speed) --[[@as cctweaked.peripheral.RotationSpeedController]],
    peripheral.wrap(tilt) --[[@as cctweaked.peripheral.TiltAdapter]],
    inverse
  )
end

function PropellarControlSystem:_update(dt)
  local pitch = self.rofl.sensors.front.gimbal:getAngles()

  for _, propellar in ipairs(self.propellars) do
    propellar.baseRpm = 105
    propellar:pushRpm()
    propellar:setTilt(-pitch[1])
  end
end

return PropellarControlSystem
