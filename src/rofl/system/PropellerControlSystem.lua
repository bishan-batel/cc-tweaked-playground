local System = require("system")
local Propeller = require("peripheral.propeller")
local pid = require("..pid")
local Matrix = require("..matrix")

local PROP_CALIBRATION = {
  ["BL"] = 0.92,
  ["ML"] = 0.930,
}

local PITCH_AXIS = vector.new(-1, 0, 0)
local YAW_AXIS = vector.new(0, 1, 0)
local ROLL_AXIS = vector.new(0, 0, 1)


--- smallest possible delta time to prevent division by zero
--- world dependent config, these are just set to the Create defaultse
local PROP_AIRFLOW_CONFIG = 0.05000000074505806
local PROP_THRUST_CONFIG = 0.20000000298023224

local PROP_VEL_RPM_FACTOR = 1

local PROPELLER_CENTER_OF_MASS_OFFSET = vector.new(
  0 * 0.4475369341671467,
  0.0,
  0.0
)
local PROPELLER_BREADTH = 29.5
local PROPELLER_Y = -3

--- number of sails per each propeller *bearing*
local SAILS_PER_BEARING = 40 * 4
local BEARINGS_PER_PROPELLER = 2



local TARGET_PITCH = 0
local TARGET_ROLL = 0

local BALANCE_FACTOR = 1.0
local EULER_MAX_ACCEL = 5

---@type pid.Config
local PID_ANGULAR_CONFIG = {
  proportion = 5.5, -- Aggressiveness of correction
  integral = 10.5,  -- Fixes persistent unbalance over time
  derivative = 5.0, -- Damping,
  integralMax = 2,
  filterTime = 0.15
}

local ALTITUDE_FACTOR = 0.00
local ALTITUDE_CORRECTION_MAX = 0.1
local ALTITUDE_CORRECTION_MIN = -0.1

---@type pid.Config
local PID_ALTITUDE_CONFIG = {
  proportion = 1.0, -- Aggressiveness of correction
  integral = 0.5,   -- Fixes persistent unbalance over time
  derivative = 0.1, -- Damping,
  integralMax = 15,
  filterTime = 0.15
}

---@class rofl.PropellerControlSystem.RequiredState
---@field pitchAcc number
---@field rollAcc number
---@field yawAcc number
---@field lift number


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
    function() instance:sendAllRoutine() end
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


  self.propellers = {
    self:wrapPropeller(
      "BR",
      "Create_RotationSpeedController_17",
      "tilt_adapter_5",
      false,
      vector.new(PROPELLER_BREADTH, PROPELLER_Y, 37)
    ),
    self:wrapPropeller(
      "BL",
      "Create_RotationSpeedController_18",
      "tilt_adapter_4",
      false,
      vector.new(-PROPELLER_BREADTH, PROPELLER_Y, 37)
    ),
    self:wrapPropeller(
      "MR",
      "Create_RotationSpeedController_16",
      "tilt_adapter_16",
      false,
      vector.new(PROPELLER_BREADTH, PROPELLER_Y, -1)
    ),
    self:wrapPropeller(
      "ML",
      "Create_RotationSpeedController_19",
      "tilt_adapter_15",
      false,
      vector.new(-PROPELLER_BREADTH, PROPELLER_Y, -1)
    ),
    self:wrapPropeller(
      "FR",
      "Create_RotationSpeedController_15",
      "tilt_adapter_6",
      false,
      vector.new(PROPELLER_BREADTH, PROPELLER_Y, -42.5)
    ),
    self:wrapPropeller(
      "FL",
      "Create_RotationSpeedController_20",
      "tilt_adapter_7",
      false,
      vector.new(-PROPELLER_BREADTH, PROPELLER_Y, -42.5)
    ),
  }

  self.pidPitch = pid.Number.new(PID_ANGULAR_CONFIG)
  self.pidRoll = pid.Number.new(PID_ANGULAR_CONFIG)
  self.pidAltitude = pid.Number.new(PID_ALTITUDE_CONFIG)

  self.pidConfig = PID_ANGULAR_CONFIG
  self.targetAltitude = 90
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
  local engine = self.rofl.engine
  local sensors = self.rofl:getSystem("rofl.SensorSystem")

  if not engine:isRunning() then
    self:resetPropellers()
    return
  end

  self:resetAllToBase(sensors)
end

---@param sensors rofl.SensorSystem
---@return rofl.PropellerControlSystem.RequiredState
function PropellerControlSystem:getRequirements(sensors)
  local dt = self.rofl.dt

  local angularAcc = sensors.angularAcceleration
  local gravity = sensors.gravity
  local altitude = sensors.altitude

  local pitchAcc, rollAcc = self:updatePitchRollCorrections(
    dt,
    sensors.pitch,
    sensors.roll
  )

  local altitudeAcc = gravity:length()

  altitudeAcc = altitudeAcc +
    math.clamp(
      self:updateAltitudeCorrection(dt, altitude) * ALTITUDE_FACTOR,
      -ALTITUDE_CORRECTION_MIN, ALTITUDE_CORRECTION_MAX
    )

  rollAcc = math.clamp(
    rollAcc * BALANCE_FACTOR,
    -EULER_MAX_ACCEL,
    EULER_MAX_ACCEL
  )

  pitchAcc = math.clamp(
    pitchAcc * BALANCE_FACTOR,
    -EULER_MAX_ACCEL,
    EULER_MAX_ACCEL
  )

  return {
    pitchAcc = pitchAcc,
    rollAcc = rollAcc,
    yawAcc = 0,
    lift = altitudeAcc,
  }
end

---@param sensors rofl.SensorSystem
function PropellerControlSystem:resetAllToBase(sensors)
  local gravity = sensors.gravity
  local airPressure = sensors.airPressure
  local velocity = sensors.velocity

  local shipAngles = {
    yaw = sensors.yaw,
    roll = sensors.roll,
    pitch = sensors.pitch
  }
  local anchorPosition = sensors.anchorPosition

  local centerOfMass, mass = self:computeShipCenterOfMass(
    sensors.centerOfMass,
    sensors.mass,
    sensors.anchorPosition
  )

  print("COM=", centerOfMass)

  --- create the desired solution for forces
  local requirements = self:getRequirements(sensors)

  local thrustAllocations = self:solveThrustLeastSquared(
    centerOfMass,
    anchorPosition,
    requirements,
    gravity,
    mass,
    shipAngles
  )

  for _, propeller in ipairs(self.propellers) do
    local requiredThrust = thrustAllocations[propeller.name] or 0

    local propBaseRpm = self:computeBaseRpmForPropeller(
      propeller,
      shipAngles,
      velocity,
      airPressure,
      requiredThrust
    )

    propeller:resetRpm(propBaseRpm)

    local tilt = -shipAngles.pitch * 0

    if PROP_CALIBRATION[propeller.name] then
      tilt = tilt + PROP_CALIBRATION[propeller.name]
    end
    propeller:resetTilt(tilt)
    -- propeller:resetTilt(0)
  end
end

--- Calculates exactly how much thrust each propeller needs based on distance from CoM
---@param centerOfMass ccTweaked.Vector
---@param anchorPosition ccTweaked.Vector
---@param requirements rofl.PropellerControlSystem.RequiredState
---@param gravity ccTweaked.Vector
---@param mass number
---@param shipAngles GimbalAngles
---@return { string: number } propellerThrustRatios
function PropellerControlSystem:solveThrustLeastSquared(
  centerOfMass,
  anchorPosition,
  requirements,
  gravity,
  mass,
  shipAngles
)
  local allocations = {}

  --- construct the table for 'A'
  local rowPitch = {}
  local rowRoll = {}
  local rowYaw = {}
  local rowLift = {}

  local upDir = gravity:mul(-1):normalize()

  for i, propeller in ipairs(self.propellers) do
    local pos = propeller.relativePosition:add(anchorPosition):sub(centerOfMass)

    local propellerDir = propeller:calculateDir(
      shipAngles.yaw,
      shipAngles.roll,
      shipAngles.pitch
    )


    -- print(string.format("%.2f, %.2f, %.2f | %.2f", propellerDir.x, propellerDir
    --   .y,
    --   propellerDir.z, propellerDir:length()))

    --- All propellers fully contribute to lift

    local forceVector = propellerDir

    local torqueVector = pos:cross(forceVector)

    --- Z offset contributes to pitch
    rowPitch[i] = PITCH_AXIS:dot(torqueVector)
    -- print(torqueVector)
    rowRoll[i] = ROLL_AXIS:dot(torqueVector)
    rowYaw[i] = YAW_AXIS:dot(torqueVector)
    rowLift[i] = propellerDir:dot(upDir)
  end

  local A = Matrix.fromTable {
    rowRoll,
    rowPitch,
    rowLift,
  }

  local AT = A:transpose()
  local ATA = A:multiply(AT)
  local inverse, inverseError = ATA:inverse()

  if not inverse then
    print("Failed to find sufficient inverse for solution ", inverseError)
    local equalDistribution = requirements.lift / #self.propellers
    for _, propeller in ipairs(self.propellers) do
      allocations[propeller.name] = equalDistribution * 0
    end
    return allocations
  end


  local requiredV = Matrix.fromTable {
    { requirements.rollAcc },
    { requirements.pitchAcc },
    -- { requirements.yawAcc },
    { requirements.lift, }
  }

  local solutionV = AT:multiply(inverse:multiply(requiredV))

  -- print(solutionV.rows, solutionV.cols)

  for i, propeller in ipairs(self.propellers) do
    local thrustValue = solutionV.data[i][1]
    allocations[propeller.name] = thrustValue * mass
  end


  return allocations
end

---@param propeller rofl.Propeller
---@param shipAngles GimbalAngles
---@param airPressure number
---@param velocity ccTweaked.Vector
---@param requiredThrust number
---@return number
---@private
function PropellerControlSystem:computeBaseRpmForPropeller(
  propeller,
  shipAngles,
  velocity,
  airPressure,
  requiredThrust
)
  requiredThrust = requiredThrust / BEARINGS_PER_PROPELLER
  -- requiredThrust = requiredThrust / 1.01793445653

  local propellerDir = propeller:calculateDir(
    shipAngles.yaw,
    shipAngles.roll,
    shipAngles.pitch
  )


  local propellerVelocity = velocity:dot(propellerDir) * PROP_VEL_RPM_FACTOR

  local CT = PROP_THRUST_CONFIG
  local CA = PROP_AIRFLOW_CONFIG
  local nSails = SAILS_PER_BEARING

  local thrustTerm = requiredThrust / (math.pow(nSails, 1.5) * CT * airPressure)
  local velocityTerm = propellerVelocity / (math.sqrt(nSails) * CA)

  return math.max(0, thrustTerm - velocityTerm)
end

---@param dt number
---@param pitch number
---@param roll number
---@return number pitchCorrection, number rollCorection
function PropellerControlSystem:updatePitchRollCorrections(
  dt,
  pitch,
  roll
)
  local errPitch, errRoll = TARGET_PITCH - pitch, TARGET_ROLL - roll

  -- calculate required pitch and roll correction
  local pitchCorrection = self.pidPitch:update(errPitch, dt)
  local rollCorrection = self.pidRoll:update(errRoll, dt)

  self.lastPitchCorrection = pitchCorrection
  self.lastRollCorrection = rollCorrection

  return pitchCorrection, rollCorrection
end

---@param dt number
---@param altitude number
---@return number altitudeCorrection
function PropellerControlSystem:updateAltitudeCorrection(
  dt,
  altitude
)
  local error = self.targetAltitude - altitude

  -- calculate required pitch and roll correction
  local altitudeCorrection = self.pidAltitude:update(error, dt)

  self.lastAltitudeCorrection = altitudeCorrection

  return altitudeCorrection
end

function PropellerControlSystem:getNumBearings()
  return #self.propellers * BEARINGS_PER_PROPELLER
end

---@param mainBodyCenter ccTweaked.Vector Main body center of mass (sublevel.getCenterOfMass())
---@param mainBodyMass number Mass of the main ship body (sublevel.getMass())
---@param anchorPosition ccTweaked.Vector Anchor for referencing propellers
function PropellerControlSystem:computeShipCenterOfMass(
  mainBodyCenter,
  mainBodyMass,
  anchorPosition
)
  ---@type [{position: ccTweaked.Vector, mass: number }]
  local objects = {
    { position = mainBodyCenter:sub(anchorPosition), mass = mainBodyMass }
  }


  for _, propeller in ipairs(self.propellers) do
    local propellerMass, offset = self:getMassPerPropeller(propeller)
    local globalPos = propeller.relativePosition

    table.insert(objects, {
      position = globalPos:add(offset),
      mass = propellerMass
    })
  end

  local mainCenter, mass = PropellerControlSystem.computeCenterOfMass(objects)

  return mainCenter:add(anchorPosition), mass
end

---@param objects [{position: ccTweaked.Vector, mass: number }]
---@return ccTweaked.Vector centerOfMass, number mass
function PropellerControlSystem.computeCenterOfMass(objects)
  local massTotal = 0
  local sumWeightedPosition = vector.new(0, 0, 0)

  for _, obj in ipairs(objects) do
    massTotal = massTotal + obj.mass
    sumWeightedPosition = sumWeightedPosition:add(obj.position:mul(obj.mass))
  end

  return sumWeightedPosition:div(massTotal), massTotal
end

---@param rpm number
---@param name string
function PropellerControlSystem:addToAllPropellers(rpm, name)
  for _, prop in ipairs(self.propellers) do
    prop:addRpm(name, rpm)
  end
end

---@param propeller rofl.Propeller
---@return number, Vector
function PropellerControlSystem:getMassPerPropeller(propeller)
  local offset = PROPELLER_CENTER_OF_MASS_OFFSET

  if propeller.name:find("L") then
    offset.x = -offset.x
    offset.z = -offset.z
  end

  return 506.5, offset
end

function PropellerControlSystem:resetPropellers()
  for _, propeller in ipairs(self.propellers) do
    propeller:resetRpm(0)
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

return PropellerControlSystem
