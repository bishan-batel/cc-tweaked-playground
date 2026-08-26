local Matrix = require "..matrix"

--- world dependent config, these are just set to the Create defaultse

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
local Propeller = {
  AIRFLOW_CONFIG = 0.05000000074505806,
  THRUST_CONFIG = 0.20000000298023224
}
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
---@return Vector
function Propeller:calculateDir(yaw, roll, pitch)
  local direction = Matrix.fromVector(self.direction)
  local rotation = Matrix.fromEuler(roll, pitch, yaw)
  return (rotation * direction):toVector()
end

--- Computes the required RPM for a single propeller bearing
--- @param thrust number Required Thrust
--- @param airPressure number Air Presure of the bearing
--- @param numSails integer Number of sails on the bearing
--- @param direction Vector Direction the propeller is facing
--- @param velocity Vector?
function Propeller.computeRequiredRpm(
  thrust,
  airPressure,
  numSails,
  direction,
  velocity
)
  velocity = velocity or vector.new(0, 0, 0)

  local propellerVelocity = velocity:dot(direction)

  local CT = Propeller.THRUST_CONFIG
  local CA = Propeller.AIRFLOW_CONFIG
  local nSails = numSails

  local thrustTerm = thrust / (math.pow(nSails, 1.5) * CT * airPressure)
  local velocityTerm = propellerVelocity / (math.sqrt(nSails) * CA)

  return thrustTerm - velocityTerm
end

return Propeller
