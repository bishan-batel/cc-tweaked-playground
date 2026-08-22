---@class rofl.Propellar
---@field private speedController cctweaked.peripheral.RotationSpeedController
---@field private tiltAdapter cctweaked.peripheral.TiltAdapter
---@field enabled boolean
---@field baseRpm number
---@field deltaRpm number
---@field baseTilt number
---@field deltaTilt number
---@field inverse boolean
---@field sublevelPosition ccTweaked.Vector
local Propellar = {}
Propellar.__index = Propellar

---@param speedControl cctweaked.peripheral.RotationSpeedController
---@param tiltAdapter cctweaked.peripheral.TiltAdapter
---@param inverse boolean
---@param sublevelPosition ccTweaked.Vector
function Propellar.new(speedControl, tiltAdapter, inverse, sublevelPosition)
  local self = setmetatable({}, Propellar)
  self.speedController = speedControl
  self.tiltAdapter = tiltAdapter
  self.enabled = true
  self.baseRpm = 10
  self.deltaRpm = 0
  self.baseTilt = 0
  self.deltaTilt = 0
  self.sublevelPosition = sublevelPosition
  self.inverse = not not inverse
  return self
end

function Propellar:sendAll()
  self:sendRpm()
  self:sendTilt()
end

function Propellar:sendRpm()
  self.speedController.setTargetSpeed(self:calculateRpm())
end

function Propellar:sendTilt()
  self.tiltAdapter.setTargetAngle(self:calculateTilt())
end

function Propellar:calculateTilt()
  if not self.enabled then return 0 end

  local tilt = self.baseTilt
  tilt = tilt + self.deltaTilt

  if self.inverse then return tilt end
  -- return -tilt
  return 0
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
