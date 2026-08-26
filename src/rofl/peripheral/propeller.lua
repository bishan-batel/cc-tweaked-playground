---@class rofl.Propeller Wrapper for a propellar variable
---@field private speedController cctweaked.peripheral.RotationSpeedController
---@field enabled boolean When false the propellar will snap to 0 RPM
---@field baseRpm number Base rpm before delta RPM is applied
---@field deltaRpm rofl.Propeller.Offsets Offset from base rpm
---@field inverse boolean Inverts both tilt and the RPM of this propellar
---@field relativePosition ccTweaked.Vector Position of this propellar within the sublevel
---@field lastSentRpm number
---@field name string
---@field direction Vector?
local Propeller = {}
Propeller.__index = Propeller

---@alias rofl.Propeller.Offsets { [string] : number }

---@param name string
---@param speedControl cctweaked.peripheral.RotationSpeedController|string
---@param relativePosition ccTweaked.Vector
---@param direction Vector? Direction this is facing, default is straight up
---@param inverse boolean?
function Propeller.new(
  name,
  speedControl,
  relativePosition,
  direction,
  inverse
)
  local self = setmetatable({}, Propeller)

  if type(speedControl) == "string" then
    speedControl = peripheral.wrap(speedControl) --[[@as cctweaked.peripheral.RotationSpeedController]]
  end

  assert(speedControl, "Speed Control must not be nil for Propeller" .. name)

  self.speedController = speedControl
  self.enabled = true
  self.baseRpm = 10
  self.deltaRpm = {}
  self.relativePosition = relativePosition
  self.inverse = not not inverse
  self.name = name
  self.direction = direction or vector.new(0, 1, 0)

  self.lastSentRpm = 0

  return self
end

function Propeller:sendAll()
  self:sendRpm()
end

---@param baseRpm number?
function Propeller:resetRpm(baseRpm)
  self.baseRpm = baseRpm or self.baseRpm
  self.deltaRpm = {}
end

---@param name string
---@param delta number
function Propeller:addRpm(name, delta)
  self.deltaRpm[name] = delta
end

--- Sends the RPM into the controller, note that this is considerably laggy
function Propeller:sendRpm()
  local rpm = self:calculateRpm()

  -- rpm = math.min(rpm, 220)

  self.speedController.setTargetSpeed(rpm)

  if self.inverse then rpm = -rpm end
  self.lastSentRpm = rpm
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
  local radYaw             = math.rad(yaw)
  local radRoll            = math.rad(roll)
  local radPitch           = math.rad(pitch)

  local sinYaw, cosYaw     = math.sin(radYaw), math.cos(radYaw)
  local sinPitch, cosPitch = math.sin(radPitch), math.cos(radPitch)
  local sinRoll, cosRoll   = math.sin(radRoll), math.cos(radRoll)

  local x                  = self.direction.x
  local y                  = self.direction.y
  local z                  = self.direction.z

  local m11                = cosYaw * cosPitch
  local m12                = cosYaw * sinPitch * sinRoll - sinYaw * cosRoll
  local m13                = cosYaw * sinPitch * cosRoll + sinYaw * sinRoll

  local m21                = sinYaw * cosPitch
  local m22                = sinYaw * sinPitch * sinRoll + cosYaw * cosRoll
  local m23                = sinYaw * sinPitch * cosRoll - cosYaw * sinRoll

  local m31                = -sinPitch
  local m32                = cosPitch * sinRoll
  local m33                = cosPitch * cosRoll

  local rx                 = m11 * x + m12 * y + m13 * z
  local ry                 = m21 * x + m22 * y + m23 * z
  local rz                 = m31 * x + m32 * y + m33 * z

  return vector.new(rx, ry, rz)
end

return Propeller
