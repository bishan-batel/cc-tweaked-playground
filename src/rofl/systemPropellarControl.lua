local System = require("system")
local Propellar = require("propellar")

--- base level of force that propellars apply (ignoring air pressure)
local PROPELLAR_BASE_FORCE = 780

---@alias rofl.PropellarControlSystem.Set {
--- left: rofl.Propellar,
--- right: rofl.Propellar,
--- }

---@alias rofl.PidConfig { P : number, I : number, D : number }

---@class rofl.PropellarControlSystem : rofl.System
---@field private propellars [rofl.Propellar]
---@field private back rofl.PropellarControlSystem.Set
---@field private front rofl.PropellarControlSystem.Set
---@field private pitchState rofl.PropellarControlSystem.AxisState
---@field private rollState rofl.PropellarControlSystem.AxisState
---@field forcePerPropellar number
local PropellarControlSystem = {}

---@class rofl.PropellarControlSystem.AxisState
---@field integral number
---@field lastError number

PropellarControlSystem.__index = PropellarControlSystem


---@param rofl rofl.Roflcopter
function PropellarControlSystem.new(rofl)
  local instance = System.new("rofl.PropellarControlSystem", rofl)
  setmetatable(instance, PropellarControlSystem)

  instance.backgroundRoutines = {
    function()
      instance:sendAllRoutine()
    end
  }

  return instance
end

function PropellarControlSystem:_init()
  self.propellars = {
    self:wrapPropellar(
      "Create_RotationSpeedController_7",
      "tilt_adapter_4",
      true,
      vector.new(20481013, 134, 20507642)
    ),
    self:wrapPropellar(
      "Create_RotationSpeedController_5",
      "tilt_adapter_5",
      false,
      vector.new(20481073, 134, 20507642)
    ),
    self:wrapPropellar(
      "Create_RotationSpeedController_6",
      "tilt_adapter_7",
      true,
      vector.new(20481013, 134, 20507562)
    ),
    self:wrapPropellar(
      "Create_RotationSpeedController_4",
      "tilt_adapter_6",
      false,
      vector.new(20481073, 134, 20507562)
    ),
  }

  self.back = {
    left = self.propellars[1],
    right = self.propellars[2],
  }

  self.front = {
    left = self.propellars[3],
    right = self.propellars[4],
  }

  self.rollState = { integral = 0, lastError = 0 }
  self.pitchState = { integral = 0, lastError = 0 }

  self.pidConfig = {
    P = 1.5,  -- Aggressiveness of correction
    I = 0.5,  -- Fixes persistent unbalance over time
    D = 10.5, -- Damping
  }
end

---@private
---@param speed string
---@param tilt string
---@param inverse boolean
---@param sublevelPosition ccTweaked.Vector
function PropellarControlSystem:wrapPropellar(
  speed,
  tilt,
  inverse,
  sublevelPosition
)
  return Propellar.new(
    peripheral.wrap(speed) --[[@as cctweaked.peripheral.RotationSpeedController]],
    peripheral.wrap(tilt) --[[@as cctweaked.peripheral.TiltAdapter]],
    inverse,
    sublevelPosition
  )
end

function PropellarControlSystem:_update(dt)
  local sensors = self.rofl:getSystem("rofl.SensorSystem")

  local centerOfMass = sensors.centerOfMass
  local mass = sensors.mass
  local gravity = sensors.gravity
  local airPressure = sensors.airPressure

  dt = math.max(dt, 0.05)

  local pitch, roll = table.unpack(self.rofl.sensors.front.gimbal:getAngles())

  local baseRpm = self:getBaseRpm(airPressure, gravity, mass)



  local pitchCorrection, rollCorrection = self:getCorrections(
    pitch,
    roll,
    dt
  )


  for _, propellar in ipairs(self.propellars) do
    propellar.baseRpm = baseRpm
    propellar.baseTilt = -pitch

    local position = propellar.sublevelPosition:sub(centerOfMass)

    local pitchMod = -position.z * pitchCorrection
    local rollMod = -position.x * rollCorrection

    propellar.deltaRpm = pitchMod + rollMod
  end

  -- self.back.left.deltaTilt = 30
  -- self.back.right.deltaTilt = 0
end

function PropellarControlSystem:sendAllRoutine()
  while true do
    self:sendAll()
    sleep(1.0 / 20.0)
  end
end

function PropellarControlSystem:sendAll()
  local actions = {}
  for _, propellar in ipairs(self.propellars) do
    table.insert(
      actions,
      function() propellar:sendRpm() end
    )
    table.insert(
      actions,
      function() propellar:sendTilt() end
    )
  end

  parallel.waitForAll(table.unpack(actions))
end

---@param pitch number
---@param roll number
---@param dt number
---@return number, number
function PropellarControlSystem:getCorrections(pitch, roll, dt)
  local targetPitch = 0
  local targetRoll = 0

  local pitchError = targetPitch - pitch

  self.pitchState.integral = self.pitchState.integral + (pitchError * dt)
  self.pitchState.integral = math.max(-15, math.min(15, self.pitchState.integral))

  local pitchDerivative = (pitchError - self.pitchState.lastError) / dt

  self.pitchState.lastError = pitchError

  local pitchCorrection = (self.pidConfig.P * pitchError) +
    (self.pidConfig.I * self.pitchState.integral) +
    (self.pidConfig.D * pitchDerivative)

  local rollError = targetRoll - roll

  self.rollState.integral = self.rollState.integral + (rollError * dt)
  self.rollState.integral = math.max(-15, math.min(15, self.rollState.integral))

  local rollDerivative = (rollError - self.rollState.lastError) / dt

  self.rollState.lastError = rollError

  local rollCorrection = (self.pidConfig.P * rollError) +
    (self.pidConfig.I * self.rollState.integral) +
    (self.pidConfig.D * rollDerivative)

  local scale = 0.01

  return scale * pitchCorrection, scale * rollCorrection
end

---@param airPressure number
---@param gravity ccTweaked.Vector
---@param mass number
---@return number
function PropellarControlSystem:getBaseRpm(airPressure, gravity, mass)
  return gravity:length() * mass /
    (#self.propellars * airPressure * PROPELLAR_BASE_FORCE)
end

return PropellarControlSystem
