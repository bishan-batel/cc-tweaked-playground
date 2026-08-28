require "..mathutils"

local System = require "system"
local Propeller = require "peripheral.propeller"

local pid = require "..pid"
local Matrix = require "..matrix"


--- Axis Constants
local PITCH_AXIS = vector.new(-1, 0, 0)
local YAW_AXIS = vector.new(0, 1, 0)
local ROLL_AXIS = vector.new(0, 0, -1)

--- Directions
local DOWN = vector.new(0, -1, 0)
local RIGHT = vector.new(1, 0, 0)
local LEFT = RIGHT:mul(-1)
local FORWARD = vector.new(0, 0, -1)
local BACK = FORWARD:mul(-1)

local X_AXIS = vector.new(1, 0, 0)
local Y_AXIS = vector.new(0, 1, 0)
local Z_AXIS = vector.new(0, 0, 1)

local LATERAL_SCALE = 10.0

local NUM_SAILS_LIFT = 180
local NUM_SAILS_STRAFE = 8

---@type pid.Config
local PID_ANGULAR_CONFIG = {
  proportion = 1.5, -- Aggressiveness of correction
  integral = 1.0,   -- Fixes persistent unbalance over time
  derivative = 2.0, -- Damping,
  integralMax = 15,
  filterTime = 0.15,
  scale = 10.0,
  bounds = 1
}

---@type pid.Config
local PID_ALTITUDE_CONFIG = {
  proportion = 1.0, -- Aggressiveness of correction
  integral = 0.5,   -- Fixes persistent unbalance over time
  derivative = 5.5, -- Damping,
  integralMax = 15,
  filterTime = 0.15,
  scale = 1,
  bounds = {
    min = -0.5,
    max = 0.5
  }
}

---@type pid.Config
local PID_LATERAL_CONFIG = {
  proportion = 1.0, -- Aggressiveness of correction
  integral = 0.5,   -- Fixes persistent unbalance over time
  derivative = 5.5, -- Damping,
  integralMax = 15,
  filterTime = 0.15,
  scale = 10.0,
}


---@class rofl.PropellerControlSystem.RequiredState
---@field pitchAcc number
---@field rollAcc number
---@field lift number


---System for control propellers
---@class rofl.PropellerControlSystem : rofl.System
---@field liftPropellers [rofl.Propeller] All tilt propellers attached
---@field strafePropellers [rofl.Propeller]
---@field pidPitch pid.Number
---@field pidRoll pid.Number
local PropellerControlSystem = {
  --- Wait for how long in between sending RPM and Tilt data
  SEND_ALL_ROUTINE_WAIT = 0.05
}

PropellerControlSystem.__index = PropellerControlSystem

---@param kernel rofl.Kernel
function PropellerControlSystem.new(kernel)
  local instance = System.new("rofl.PropellerControlSystem", kernel)
  setmetatable(instance, PropellerControlSystem)

  instance.backgroundRoutines = {
    function() instance:sendAllRoutine() end
  }

  return instance
end

function PropellerControlSystem:_init()
  self:findPropellers()
  self:initializePids()
end

---@private
function PropellerControlSystem:findPropellers()
  print("Finding Propellers")
  local OFF_R = 30 + 0.5
  local OFF_L = -30 + 0.5
  local OFF_Y = -3 + 0.5
  local OFFZ = 0.5

  self.strafePropellers = {
    Propeller.new {
      name = "SBR",
      speedControl = "Create_RotationSpeedController_22",
      position = vector.new(13 + 0.5, -2.5, 18.5),
      direction = RIGHT,
      inverse = true,
      numSails = NUM_SAILS_STRAFE
    },
    Propeller.new {
      name = "SFR",
      speedControl = "Create_RotationSpeedController_21",
      position = vector.new(13 + 0.5, -2.5, -22 + 0.5),
      direction = RIGHT,
      inverse = true,
      numSails = NUM_SAILS_STRAFE

    },
    Propeller.new {
      name = "SBL",
      speedControl = "Create_RotationSpeedController_23",
      position = vector.new(-13 + 0.5, -2.5, 18.5),
      direction = LEFT,
      numSails = NUM_SAILS_STRAFE
    },
    Propeller.new {
      name = "SFL",
      speedControl = "Create_RotationSpeedController_24",
      position = vector.new(-13 + 0.5, -2.5, -22 + 0.5),
      direction = LEFT,
      numSails = NUM_SAILS_STRAFE
    },
  }


  self.liftPropellers = {
    Propeller.new {
      name = "BR",
      speedControl = "Create_RotationSpeedController_17",
      position = vector.new(OFF_R, OFF_Y, 38 + OFFZ),
      direction = DOWN,
      numSails = NUM_SAILS_LIFT
    },
    Propeller.new {
      name = "BL",
      speedControl = "Create_RotationSpeedController_18",
      position = vector.new(OFF_L, OFF_Y, 38 + OFFZ),
      direction = DOWN,
      numSails = NUM_SAILS_LIFT
    },
    Propeller.new {
      name = "MR",
      speedControl = "Create_RotationSpeedController_16",
      position = vector.new(OFF_R, OFF_Y, -1 + OFFZ),
      direction = DOWN,
      numSails = NUM_SAILS_LIFT
    },
    Propeller.new {
      name = "ML",
      speedControl = "Create_RotationSpeedController_19",
      position = vector.new(OFF_L, OFF_Y, -1 + OFFZ),
      direction = DOWN,
      numSails = NUM_SAILS_LIFT
    },
    Propeller.new {
      name = "FR",
      speedControl = "Create_RotationSpeedController_15",
      position = vector.new(OFF_R, OFF_Y, -42 + 0),
      direction = DOWN,
      numSails = NUM_SAILS_LIFT
    },
    Propeller.new {
      name = "FL",
      speedControl = "Create_RotationSpeedController_20",
      position = vector.new(OFF_L, OFF_Y, -42 + 0),
      direction = DOWN,
      numSails = NUM_SAILS_LIFT
    },
  }

  self.allPropellers = {
    table.unpack(self.liftPropellers),
    table.unpack(self.strafePropellers)
  }
end

---@private
function PropellerControlSystem:initializePids()
  self.pidPitch = pid.Number.new(PID_ANGULAR_CONFIG)
  self.pidRoll = pid.Number.new(PID_ANGULAR_CONFIG)
  self.pidAltitude = pid.Number.new(PID_ALTITUDE_CONFIG)
  self.pidLateralX = pid.Number.new(PID_LATERAL_CONFIG)
  self.pidLateralZ = pid.Number.new(PID_LATERAL_CONFIG)
  self.targetAltitude = 120
end

---@private
function PropellerControlSystem:_update(_)
  local engine = self.kernel.engine
  local sensors = self.kernel:getSystem("rofl.SensorSystem")

  if not engine:isRunning() then
    self:resetPropellers()
    return
  end


  self:recomputePropellerRpm(sensors)
end

function PropellerControlSystem:resetPropellers()
  for _, propeller in ipairs(self.allPropellers) do
    propeller:resetRpm(0)
  end
end

---@private
function PropellerControlSystem:sendAllRoutine()
  while true do
    self:sendAll()
    sleep(self.SEND_ALL_ROUTINE_WAIT)
  end
end

---@private
function PropellerControlSystem:sendAll()
  local actions = {}

  for _, propeller in ipairs(self.liftPropellers) do
    table.insert(actions, function() propeller:sendAll() end)
  end

  for _, propeller in ipairs(self.strafePropellers) do
    table.insert(actions, function() propeller:sendAll() end)
  end

  parallel.waitForAll(table.unpack(actions))
end

---@param sensors rofl.SensorSystem
function PropellerControlSystem:getRequirements(sensors)
  local dt = self.kernel.dt

  local gravity = sensors.gravity
  local altitude = sensors.shipPosition.y

  local pitchAcc, rollAcc = self:updatePitchRollCorrections(
    dt,
    sensors.pitch,
    sensors.roll
  )

  local altitudeAcc = gravity:length()

  altitudeAcc = altitudeAcc + self:updateAltitudeCorrection(dt, altitude)

  local velocity = sensors.velocity

  local targetVel = vector.new(
    0,
    0,
    0
  )

  local lateralX = self.pidLateralX:update(targetVel.x - velocity.x, dt)
  local lateralZ = self.pidLateralZ:update(targetVel.z - velocity.z, dt)

  for _, propeller in ipairs(self.strafePropellers) do
    local dir = propeller:calculateDir(sensors.shipAngles)

    local thrust = lateralX * X_AXIS:dot(dir) - lateralZ * Z_AXIS:dot(dir)

    thrust = thrust * sensors.mass

    local rpm = self:getRequiredRpmForStrafePropeller(
      propeller,
      sensors.shipAngles,
      sensors.shipPosition,
      sensors.anchorPosition,
      sensors.centerOfMass,
      sensors.velocity,
      thrust
    )

    propeller:resetRpm(rpm)
  end

  ---@type rofl.PropellerControlSystem.RequiredState
  return {
    pitchAcc = pitchAcc,
    rollAcc = rollAcc,
    yawAcc = 0,
    lift = altitudeAcc,
    lateralAcc = {
      x = lateralX,
      z = lateralZ
    }
  }
end

---Triggers recomputing the thrust / required thrust for each propeller to match
---requirements
---@param sensors rofl.SensorSystem
function PropellerControlSystem:recomputePropellerRpm(sensors)
  local gravity = sensors.gravity
  local velocity = sensors.velocity

  --- ship position relative to anchor
  local shipPosition = sensors.shipPosition

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

  self:applyThrustAllocations(
    thrustAllocations,
    shipAngles,
    shipPosition,
    anchorPosition,
    centerOfMass,
    velocity
  )
end

---@param thrustAllocations { [string]: number }
---@param shipAngles EulerAngles
---@param shipPosition Vector
---@param anchorPosition Vector
---@param centerOfMass Vector
---@param velocity Vector
function PropellerControlSystem:applyThrustAllocations(
  thrustAllocations,
  shipAngles,
  shipPosition,
  anchorPosition,
  centerOfMass,
  velocity
)
  self.lastThrustAllocation = thrustAllocations

  local funcs = {}

  for _, propeller in ipairs(self.liftPropellers) do
    local requiredThrust = thrustAllocations[propeller.name] or 0

    table.insert(funcs, function()
      propeller:resetRpm(
        self:getRequiredRpmForPropeller(
          propeller,
          shipAngles,
          shipPosition,
          anchorPosition,
          centerOfMass,
          velocity,
          requiredThrust
        )
      )
    end)
  end

  parallel.waitForAll(table.unpack(funcs))
end

--- Calculates exactly how much thrust each propeller needs based on distance from CoM
---@param centerOfMass ccTweaked.Vector
---@param anchorPosition ccTweaked.Vector
---@param requirements rofl.PropellerControlSystem.RequiredState
---@param gravity ccTweaked.Vector
---@param mass number
---@param shipAngles EulerAngles
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
  local rowLift = {}

  local upDir = gravity:normalize()

  --- Lift propellers
  for _, propeller in ipairs(self.liftPropellers) do
    local pos = propeller.position:add(anchorPosition):sub(centerOfMass)

    local propellerDir = propeller:calculateDir(shipAngles)

    local forceVector = propellerDir

    local torqueVector = pos:cross(forceVector)

    table.insert(rowPitch, PITCH_AXIS:dot(torqueVector))
    table.insert(rowRoll, ROLL_AXIS:dot(torqueVector))
    table.insert(rowLift, propellerDir:dot(upDir))
  end

  local A = Matrix.fromTable {
    rowRoll,
    rowPitch,
    rowLift
  }

  local AT = A:transpose()
  local ATA = A * AT
  local inverse, inverseError = ATA:inverse()

  if not inverse then
    print("INVERR:", inverseError)
    local equalDistribution = requirements.lift / #self.liftPropellers
    for _, propeller in ipairs(self.liftPropellers) do
      allocations[propeller.name] = equalDistribution * 0
    end
    return allocations
  end


  local requiredV = Matrix.fromTable { {
    requirements.rollAcc,
    requirements.pitchAcc,
    requirements.lift,
  } }:transpose()

  local solutionV = AT * inverse * requiredV

  for i, propeller in ipairs(self.liftPropellers) do
    local thrustValue = solutionV.data[i][1]
    allocations[propeller.name] = thrustValue * mass
  end

  return allocations
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
  local errPitch, errRoll = -pitch, -roll

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

---@param mainBodyCenter ccTweaked.Vector Main body center of mass (sublevel.getCenterOfMass())
---@param mainBodyMass number Mass of the main ship body (sublevel.getMass())
---@param anchorPosition ccTweaked.Vector Anchor for referencing propellers
function PropellerControlSystem:computeShipCenterOfMass(
  mainBodyCenter,
  mainBodyMass,
  anchorPosition
)
  _ = anchorPosition
  return mainBodyCenter, mainBodyMass
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

---@param propeller rofl.Propeller
---@param shipAngles EulerAngles
---@param shipPosition Vector
---@param anchorPosition Vector
---@param centerOfMass Vector
---@param velocity ccTweaked.Vector
---@param requiredThrust number
---@return number
---@private
function PropellerControlSystem:getRequiredRpmForPropeller(
  propeller,
  shipAngles,
  shipPosition,
  anchorPosition,
  centerOfMass,
  velocity,
  requiredThrust
)
  -- requiredThrust = requiredThrust / NUM_BEARINGS
  -- requiredThrust = requiredThrust / 1.012777
  -- requiredThrust = requiredThrust / 1.01793445653

  local numSails = propeller.numSails

  local propellerDir = propeller:calculateDir(shipAngles)

  local relPosCenter =
    propeller.position:add(anchorPosition):sub(centerOfMass)

  local relPos1 = relPosCenter:add(vector.new(0, -1, 0))
  local relPos2 = relPosCenter:add(vector.new(0, 1, 0))

  local rotation = Matrix.fromEuler(shipAngles)

  local dir1 = propellerDir
  local dir2 = propellerDir:mul(-1)
  -- dir1, dir2 = dir2, dir1

  local pos1 = ((rotation * Matrix.fromVector(relPos1)):toVector():add(
    shipPosition))
  local pos2 = ((rotation * Matrix.fromVector(relPos2)):toVector():add(
    shipPosition))


  local sensors = self.kernel:getSystem("rofl.SensorSystem")

  --- Very Laggy :(
  local pressure1 = sensors.pressureFunc(pos1.y)
  local pressure2 = sensors.pressureFunc(pos2.y)

  local rpm = Propeller.computeRequiredRpmForDoubleBearing(
    requiredThrust,
    numSails,
    velocity,
    pressure1,
    dir1,
    pressure2,
    dir2
  )

  local bestRpm = 0
  local bestThrustErr = math.abs(requiredThrust)

  --- Janky search / sampling for RPM-.5,RPM,RPM+.5 for which would satisify the
  --- required thrust best
  for i = -1, 1, 1 do
    local testRpm = math.round(rpm + i)

    local thrust = Propeller.computeThrust(
      testRpm,
      numSails,
      pressure1,
      velocity,
      dir1
    )

    thrust = thrust + Propeller.computeThrust(
      testRpm,
      numSails,
      pressure2,
      velocity,
      dir2
    )

    local thrustErr = math.abs(requiredThrust - thrust)
    if thrustErr < bestThrustErr then
      bestRpm = testRpm
      bestThrustErr = thrustErr
    end
  end


  return bestRpm
end

---@param propeller rofl.Propeller
---@param shipAngles EulerAngles
---@param shipPosition Vector
---@param anchorPosition Vector
---@param centerOfMass Vector
---@param velocity ccTweaked.Vector
---@param requiredThrust number
---@return number
---@private
function PropellerControlSystem:getRequiredRpmForStrafePropeller(
  propeller,
  shipAngles,
  shipPosition,
  anchorPosition,
  centerOfMass,
  velocity,
  requiredThrust
)
  --- number of sails per each propeller *bearing*

  -- requiredThrust = requiredThrust / NUM_BEARINGS
  -- requiredThrust = requiredThrust / 1.012777
  -- requiredThrust = requiredThrust / 1.01793445653
  local numSails = propeller.numSails

  local propellerDir = propeller:calculateDir(shipAngles)

  local relPos = propeller.position:add(anchorPosition):sub(centerOfMass)

  local rotation = Matrix.fromEuler(shipAngles)

  local normal = propellerDir

  local pos = ((rotation * Matrix.fromVector(relPos)):toVector():add(
    shipPosition))


  local sensors = self.kernel:getSystem("rofl.SensorSystem")

  --- Very Laggy :(
  local pressure = sensors.pressureFunc(pos.y)

  local rpm = Propeller.computeRequiredRpm(
    requiredThrust,
    pressure,
    numSails,
    normal,
    velocity
  )

  local bestRpm = 0
  local bestThrustErr = math.abs(requiredThrust)

  --- Janky search / sampling for RPM-.5,RPM,RPM+.5 for which would satisify the
  --- required thrust best
  for i = -1, 1, 1 do
    local testRpm = math.round(rpm + i)

    local thrust = Propeller.computeThrust(
      testRpm,
      numSails,
      pressure,
      velocity,
      normal
    )

    local thrustErr = math.abs(requiredThrust - thrust)
    if thrustErr < bestThrustErr then
      bestRpm = testRpm
      bestThrustErr = thrustErr
    end
  end


  return bestRpm
end

return PropellerControlSystem
