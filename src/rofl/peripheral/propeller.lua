local class = require("..class")
local PeripheralWrapper = require("peripheral.wrapper")
local Matrix = require "..matrix"

local MAX_RPM = 256

--- world dependent config, these are just set to the Create defaultse

---@class rofl.Propeller Wrapper for a propellar variable
---@field private speedController cctweaked.peripheral.RotationSpeedController
---@field enabled boolean When false the propellar will snap to 0 RPM
---@field baseRpm number Base rpm before delta RPM is applied
---@field deltaRpm rofl.Propeller.Offsets Offset from base rpm
---@field inverse boolean Inverts both tilt and the RPM of this propellar
---@field position ccTweaked.Vector Position of this propellar within the sublevel
---@field lastSentRpm number
---@field name string
---@field direction Vector
---@field numSails integer
---@field dual boolean?
local Propeller = {
  AIRFLOW_CONFIG = 0.05000000074505806,
  THRUST_CONFIG = 0.20000000298023224
}

class.derived(Propeller, PeripheralWrapper)


---@alias rofl.Propeller.Offsets { [string] : number }

---@class Propeller.Config
---@field name string
---@field speedControl cctweaked.peripheral.RotationSpeedController|string
---@field position Vector
---@field direction Vector
---@field numSails integer
---@field inverse boolean?
---@field dual boolean?

---@param config Propeller.Config
function Propeller.new(config)
  local self = setmetatable(PeripheralWrapper.new("propeller"), Propeller)

  local speedControl = config.speedControl

  if type(speedControl) == "string" then
    speedControl = peripheral.wrap(speedControl) --[[@as cctweaked.peripheral.RotationSpeedController]]
  end

  assert(speedControl,
    "Speed Control must not be nil for Propeller" .. config.name)

  self.speedController = speedControl
  self.enabled = true
  self.baseRpm = 10
  self.deltaRpm = {}
  self.position = config.position
  self.inverse = config.inverse or false
  self.name = config.name
  self.direction = config.direction
  self.numSails = config.numSails
  self.lastSentRpm = 0
  self.dualBearing = config.dual

  return self
end

---@async
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
---@async
function Propeller:sendRpm()
  local rpm = self:calculateRpm()

  -- rpm = math.min(rpm, 220)

  self.speedController.setTargetSpeed(math.round(rpm))

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

---@param angles EulerAngles
---@return Vector
function Propeller:calculateDir(angles)
  local direction = Matrix.fromVector(self.direction)
  local rotation = Matrix.fromEuler(angles)
  return (rotation * direction):toVector()
end

--- Computes the required RPM for a single propeller bearing
--- @param thrust number Required Thrust
--- @param airPressure number Air Presure of the bearing
--- @param numSails integer Number of sails on the bearing
--- @param normal Vector Direction the propeller is facing
--- @param velocity Vector? shipVelocity
function Propeller.computeRequiredRpm(
  thrust,
  airPressure,
  numSails,
  normal,
  velocity
)
  velocity = velocity or vector.new(0, 0, 0)

  local propellerVelocity = velocity:dot(normal) * -1

  local CT = Propeller.THRUST_CONFIG
  local CA = Propeller.AIRFLOW_CONFIG
  local nSails = numSails

  local thrustTerm = thrust / (math.pow(nSails, 1.5) * CT * airPressure)
  local velocityTerm = propellerVelocity / (math.sqrt(nSails) * CA)

  return thrustTerm - velocityTerm
end

--- Computes the requried RPM sent to 2 propeller bearings relatively on top of
--- each other
---@param thrust number Required Thrust
---@param numSails integer Number of sails on the bearing
---@param velocity Vector shipVelocity
---@param airPressure1 number Air Presure of the first bearing
---@param normal1 Vector Direction the propeller is facing
---@param airPressure2 number Air Presure of the second bearing
---@param normal2 Vector Direction the propeller is facing
---@return number
function Propeller.computeRequiredRpmForDoubleBearing(
  thrust,
  numSails,
  velocity,
  airPressure1,
  normal1,
  airPressure2,
  normal2
)
  local CT = Propeller.THRUST_CONFIG
  local CA = Propeller.AIRFLOW_CONFIG
  local N = numSails

  local u = normal1:dot(velocity)
  local v = normal2:dot(velocity)

  local mainDenom = (N ^ 1.5) * CT * (airPressure1 + airPressure2)
  local secondDenom = CA * math.sqrt(N) * (airPressure1 + airPressure2)

  local sumUv = u * airPressure1 + v * airPressure2

  return thrust / mainDenom + sumUv / secondDenom
end

---@param rpm number
---@param numSails integer
---@param pressure number
---@param velocity Vector
---@param normal Vector
function Propeller.computeThrust(
  rpm,
  numSails,
  pressure,
  velocity,
  normal
)
  local N = numSails

  local v = normal:dot(velocity)

  local velTerm = 1 - (v / Propeller.computeAirflow(rpm, numSails))
  local mainTerm = (N ^ 1.5) * Propeller.THRUST_CONFIG * rpm

  return mainTerm * velTerm * pressure
end

---@param rpm number
---@param numSails integer
function Propeller.computeAirflow(rpm, numSails)
  return rpm * Propeller.AIRFLOW_CONFIG * math.sqrt(numSails)
end

---@param shipAngles EulerAngles
---@param pressure number Air Pressure
---@param velocity Vector Velocity
function Propeller:getMaxThrust(shipAngles, pressure, velocity)
  return Propeller.computeThrust(
    MAX_RPM,
    self.numSails,
    pressure,
    velocity,
    self:calculateDir(shipAngles)
  )
end

---@param rpm number? RPM of the engine
function Propeller:getSuUsage(rpm)
  rpm = rpm or self.lastSentRpm

  local su = 2 * rpm * self.numSails

  if self.dual then
    su = su * 2
  end

  return su
end

return Propeller
