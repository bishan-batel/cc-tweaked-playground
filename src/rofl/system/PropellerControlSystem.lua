local System = require("system")
local Propeller = require("peripheral.propeller")
local pid = require("..pid")


--- smallest possible delta time to prevent division by zero
local MINIMUM_DT = 0.01

local EXTRA_REQUIRED_FORCE = 100

--- world dependent config, these are just set to the Create defaultse
local PROP_AIRFLOW_CONFIG = 0.05
local PROP_THRUST_CONFIG = 0.2

--- number of sails per each propeller *bearing*
local SAILS_PER_BEARING = 40 * 4

local TILT_CORRECTION_SCALE = 1.0

local TARGET_PITCH = 0
local TARGET_ROLL = 0

---@type pid.Config
local PID_CONFIG = {
  proportion = 200, -- Aggressiveness of correction
  integral = 50,    -- Fixes persistent unbalance over time
  derivative = 100, -- Damping,
  integralMax = 15,
  filterTime = 0.15
}


---System for control propellers
---@class rofl.PropellerControlSystem : rofl.System
---@field propellers [rofl.Propeller] All propellers attached
---@field pidPitch pid.Number
---@field pidRoll pid.Number
local PropellerControlSystem = {}


PropellerControlSystem.__index = PropellerControlSystem


---@param rofl rofl.Roflcopter
function PropellerControlSystem.new(rofl)
  local instance = System.new("rofl.PropellerControlSystem", rofl)
  setmetatable(instance, PropellerControlSystem)

  instance.backgroundRoutines = {
    function()
      instance:sendAllRoutine()
    end
  }

  return instance
end

function PropellerControlSystem:_init()
  local strafePropellers = {
    "Create_RotationSpeedController_22", -- BR
    "Create_RotationSpeedController_21", -- FR
    "Create_RotationSpeedController_23", -- BL
    "Create_RotationSpeedController_24", -- FL
  }

  for _, name in ipairs(strafePropellers) do
    local p = peripheral.wrap(name) --[[@as cctweaked.peripheral.RotationSpeedController]]

    if p then
      print("Turning off ", name)
      p.setTargetSpeed(0)
    end
  end


  self.propellers = {
    self:wrapPropeller(
      "BR",
      "Create_RotationSpeedController_17",
      "tilt_adapter_5",
      false,
      vector.new(30, -1, 38)
    ),
    self:wrapPropeller(
      "BL",
      "Create_RotationSpeedController_18",
      "tilt_adapter_4",
      true,
      vector.new(-30, -1, 38)
    ),
    self:wrapPropeller(
      "MR",
      "Create_RotationSpeedController_16",
      "tilt_adapter_16",
      false,
      vector.new(30, -1, -1)
    ),
    self:wrapPropeller(
      "ML",
      "Create_RotationSpeedController_19",
      "tilt_adapter_15",
      true,
      vector.new(-30, -1, -1)
    ),
    self:wrapPropeller(
      "FR",
      "Create_RotationSpeedController_15",
      "tilt_adapter_6",
      false,
      vector.new(30, -1, -42)
    ),
    self:wrapPropeller(
      "FL",
      "Create_RotationSpeedController_20",
      "tilt_adapter_7",
      true,
      vector.new(-30, -1, -42)
    ),
  }

  self.pidPitch = pid.Number.new(PID_CONFIG)
  self.pidRoll = pid.Number.new(PID_CONFIG)

  self.pidConfig = PID_CONFIG
end

---@private
---@param name string
---@param speed string
---@param tilt string
---@param inverse boolean
---@param relativePosition ccTweaked.Vector
function PropellerControlSystem:wrapPropeller(
  name,
  speed,
  tilt,
  inverse,
  relativePosition
)
  return Propeller.new(
    peripheral.wrap(speed) --[[@as cctweaked.peripheral.RotationSpeedController]],
    peripheral.wrap(tilt) --[[@as cctweaked.peripheral.TiltAdapter]],
    inverse,
    relativePosition,
    name
  )
end

---@private
function PropellerControlSystem:_update(dt)
  local sensors = self.rofl:getSystem("rofl.SensorSystem")

  local centerOfMass = sensors.centerOfMass
  local mass = sensors.mass
  local gravity = sensors.gravity
  local airPressure = sensors.airPressure
  local velocity = sensors.velocity
  local anchorPosition = sensors.anchorPosition

  local pitch, roll = table.unpack(self.rofl.sensors.front.gimbal:getAngles())

  self:resetAllToBase(velocity, airPressure, gravity, mass, pitch)

  self:updatePitchRollCorrections(
    dt,
    anchorPosition,
    mass,
    centerOfMass,
    pitch,
    roll
  )

  local altitude = sensors.altitude

  local rpm = math.min(10, (120 - altitude) * 5)
  if rpm > 0 then
    self:addToAllPropellers(rpm)
  end
end

---@param dt number
---@param anchorPosition ccTweaked.Vector
---@param mass number
---@param centerOfMass ccTweaked.Vector
---@param pitch number
---@param roll number
function PropellerControlSystem:updatePitchRollCorrections(
  dt,
  anchorPosition,
  mass,
  centerOfMass,
  pitch,
  roll
)
  local errPitch, errRoll = self:getError(pitch, roll)

  -- calculate required pitch and roll correction
  local pitchCorrection = self.pidPitch:update(errPitch, dt)
  local rollCorrection = self.pidRoll:update(errRoll, dt)

  local scale = TILT_CORRECTION_SCALE / mass
  pitchCorrection = pitchCorrection * scale
  rollCorrection = rollCorrection * scale

  -- use the corrections to send to each propeller based on their relative
  -- position to the center of mass
  for _, propeller in ipairs(self.propellers) do
    -- position relative to center of mass
    local position =
      propeller.relativePosition:add(anchorPosition):sub(centerOfMass)

    propeller:addRpm("pitch", -position.z * pitchCorrection)
    propeller:addRpm("roll", -position.x * rollCorrection)
  end

  self.lastPitchCorrection = pitchCorrection
  self.lastRollCorrection = rollCorrection
end

---@param velocity ccTweaked.Vector
---@param airPressure number
---@param gravity ccTweaked.Vector
---@param mass number
---@param pitch number
function PropellerControlSystem:resetAllToBase(
  velocity,
  airPressure,
  gravity,
  mass,
  pitch
)
  self.baseRpm = self:computeBaseRpm(
    velocity,
    airPressure,
    gravity,
    mass
  )

  -- reset RPM and Tilt for all propellers
  for i, propeller in ipairs(self.propellers) do
    propeller:resetRpm(self.baseRpm)
    propeller:resetTilt(-pitch)
  end
end

function PropellerControlSystem:addToAllPropellers(rpm)
  for _, prop in ipairs(self.propellers) do
    prop:addRpm("alt", rpm)
  end
end

---@private
function PropellerControlSystem:sendAllRoutine()
  while true do
    self:sendAll()
    sleep(1.0 / 20.0)
  end
end

---@private
function PropellerControlSystem:sendAll()
  local actions = {}

  for _, propeller in ipairs(self.propellers) do
    table.insert(
      actions,
      function() propeller:sendRpm() end
    )
    table.insert(
      actions,
      function() propeller:sendTilt() end
    )
  end

  parallel.waitForAll(table.unpack(actions))
end

---@param pitch number
---@param roll  number
---@return number errPitch, number errRoll
function PropellerControlSystem:getError(pitch, roll)
  return TARGET_PITCH - pitch, TARGET_ROLL - roll
end

---@param airPressure number
---@param velocity ccTweaked.Vector
---@param gravity ccTweaked.Vector
---@param mass number
---@return number
function PropellerControlSystem:computeBaseRpm(
  velocity,
  airPressure,
  gravity,
  mass
)
  -- Force needed per propeller to counteract gravity
  local totalBearings = #self.propellers * 2
  local totalWeight = gravity:length() * mass / totalBearings

  totalWeight = totalWeight + EXTRA_REQUIRED_FORCE

  local propellerDir = vector.new(0, -1, 0)

  local propellerVelocity = velocity:dot(propellerDir) * 0

  local CT = PROP_THRUST_CONFIG
  local CA = PROP_AIRFLOW_CONFIG
  local nSails = SAILS_PER_BEARING

  local thrustTerm = totalWeight / ((nSails ^ 1.5) * CT * airPressure)
  local velocityTerm = propellerVelocity / (math.sqrt(nSails) * CA)

  local finalBaseRpm = math.max(0, thrustTerm - velocityTerm)

  return finalBaseRpm
end

return PropellerControlSystem
