---@class rofl.Propeller Wrapper for a propellar variable
---@field private speedController cctweaked.peripheral.RotationSpeedController
---@field private tiltAdapter cctweaked.peripheral.TiltAdapter|nil
---@field enabled boolean When false the propellar will snap to 0 RPM and 0 Tilt
---@field baseRpm number Base rpm before delta RPM is applied
---@field deltaRpm rofl.Propeller.Offsets Offset from base rpm
---@field basePitch number Base tilt / pitch of the propellar
---@field deltaPitch rofl.Propeller.Offsets Offset tilt from base
---@field inverse boolean Inverts both tilt and the RPM of this propellar
---@field relativePosition ccTweaked.Vector Position of this propellar within the sublevel
---@field lastSentRpm number
---@field lastSentTilt number
---@field name? string
local Propeller = {}
Propeller.__index = Propeller

---@alias rofl.Propeller.Offsets { [string] : number }

---@param speedControl cctweaked.peripheral.RotationSpeedController
---@param tiltAdapter cctweaked.peripheral.TiltAdapter|nil
---@param inverse boolean
---@param relativePosition ccTweaked.Vector
---@param name? string
function Propeller.new(speedControl, tiltAdapter, inverse, relativePosition, name)
  assert(speedControl, "Speed Control must not be nil for Propeller" .. name)
  assert(tiltAdapter, "Tilt Adapter must not be nil for Propeller" .. name)
  local self = setmetatable({}, Propeller)
  self.speedController = speedControl
  self.tiltAdapter = tiltAdapter
  self.enabled = true
  self.baseRpm = 10
  self.deltaRpm = {}
  self.basePitch = 0
  self.deltaPitch = {}
  self.relativePosition = relativePosition
  self.inverse = not not inverse
  self.name = name

  self.lastSentRpm = 0
  self.lastSentTilt = 0

  return self
end

function Propeller:sendAll()
  self:sendRpm()
  self:sendTilt()
end

---@param baseRpm number?
function Propeller:resetRpm(baseRpm)
  self.baseRpm = baseRpm or self.baseRpm
  self.deltaRpm = {}
end

---@param baseTilt number?
function Propeller:resetTilt(baseTilt)
  self.deltaPitch = {}
  self.basePitch = baseTilt or self.basePitch
end

---@param name string
---@param delta number
function Propeller:addRpm(name, delta)
  self.deltaRpm[name] = delta
end

---@param name string
---@param delta number
function Propeller:addTilt(name, delta)
  self.deltaPitch[name] = delta
end

--- Sends the RPM into the controller, note that this is considerably laggy
function Propeller:sendRpm()
  local rpm = self:calculateRpm()

  -- rpm = math.min(rpm, 220)

  self.speedController.setTargetSpeed(rpm)

  if self.inverse then rpm = -rpm end
  self.lastSentRpm = rpm
end

--- Sends the Tilt into the controller, note that this is considerably laggy
function Propeller:sendTilt()
  if not self.tiltAdapter then return end
  local tilt = self:calculateTilt()
  self.tiltAdapter.setTargetAngle(tilt)

  -- if not self.inverse then tilt = -tilt end
  self.lastSentTilt = tilt
end

--- Gets the total tilt sent to the controller
function Propeller:calculateTilt()
  if not self.enabled then return 0 end

  local tilt = self.basePitch

  for _, delta in pairs(self.deltaPitch) do
    tilt = tilt + delta
  end

  if self.inverse then return tilt end
  -- return -tilt
  return tilt
end

--- Gets the total rpm sent to the controller
function Propeller:calculateRpm()
  if not self.enabled then
    return 0
  end

  local rpm = self.baseRpm

  for _, delta in pairs(self.deltaRpm) do
    rpm = rpm + delta
  end

  if self.inverse then
    return -rpm
  end

  return rpm
end

---@param yaw number The yaw of the ship in degrees
---@param roll number The roll of the ship in degrees
---@param pitch number The pitch of the ship
function Propeller:calculateDir(yaw, roll, pitch)
  local combinedPitch = pitch + (self.lastSentTilt or 0)


  local radYaw             = math.rad(yaw)
  local radRoll            = math.rad(roll)
  local radPitch           = math.rad(combinedPitch)

  local sinYaw, cosYaw     = math.sin(radYaw), math.cos(radYaw)
  local sinPitch, cosPitch = math.sin(radPitch), math.cos(radPitch)
  local sinRoll, cosRoll   = math.sin(radRoll), math.cos(radRoll)

  local dirX               = cosYaw * sinPitch * sinRoll + sinYaw * cosRoll
  local dirY               = sinYaw * sinPitch * sinRoll - cosYaw * cosRoll
  local dirZ               = cosPitch * sinRoll

  return vector.new(dirX, dirY, dirZ):mul(-1)
end

return Propeller
