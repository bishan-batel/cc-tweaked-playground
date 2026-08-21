---@class rofl.Propellar
---@field private speedController cctweaked.peripheral.RotationSpeedController
---@field private tiltAdapter cctweaked.peripheral.TiltAdapter
---@field enabled boolean
---@field baseRpm number
---@field deltaRpm number
---@field inverse boolean
local Propellar = {}
Propellar.__index = Propellar

---@param speedControl cctweaked.peripheral.RotationSpeedController
---@param tiltAdapter cctweaked.peripheral.TiltAdapter
---@param inverse? boolean
function Propellar.new(speedControl, tiltAdapter, inverse)
  local self = setmetatable({}, Propellar)
  self.speedController = speedControl
  self.tiltAdapter = tiltAdapter
  self.enabled = true
  self.baseRpm = 10
  self.deltaRpm = 0
  self.inverse = not not inverse
  return self
end

---@param angle number
function Propellar:setTilt(angle)
  self.tiltAdapter.setTargetAngle(angle)
end

function Propellar:pushRpm()
  self.speedController.setTargetSpeed(self:calculateRpm())
end

function Propellar:calculateRpm()
  if not self.enabled then
    return 0
  end

  local speed = self.baseRpm
  speed = speed + self.deltaRpm

  if self.inverse then
    return -speed
  end

  return speed
end

return Propellar
