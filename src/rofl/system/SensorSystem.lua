local System = require("system.init")
local Matrix = require("..matrix")

local ANCHOR_SETTING = "anchorPosition"
local SENSORS_CONFIG_PATH = "anchor_config"

local ANCHOR_CHANNEL = 6969

---@class rofl.ShipState
---@field mass number
---@field centerOfMass Vector
---@field position Vector
---@field velocity Vector
---@field angularVelocity Vector
---@field angularAcceleration Vector
---@field airPressure number
---@field anchorPosition Vector
---@field orientation Quaternion
---@field orientationEuler EulerAngles
---@field pressureFunc async fun(y: number): number
---@field intertiaTensor Matrix

---@class rofl.SensorSystem : rofl.System
---@field centerOfMass ccTweaked.Vector Center of mass of the sublevel
---@field mass number Mass of the sublevel
---@field gravity ccTweaked.Vector Gravity applied to the sublkevel
---@field velocity ccTweaked.Vector Velocity of the sublevel
---@field angularVelocity ccTweaked.Vector Angular Velocity of the sublevel
---@field airPressure number Air pressure of the sublevel
---@field altitudeFront number
---@field altitudeBack number
---@field altitude number
---@field anchorPosition ccTweaked.Vector
---@field pitch number Pitch of the ship
---@field yaw number Yaw of the ship
---@field roll number Roll of the ship
---@field shipAngles EulerAngles Pitch,Yaw, & Roll of the Ship
---@field intertiaTensor Matrix
local SensorSystem = {
  SEA_LEVEL = 90,
}

SensorSystem.__index = SensorSystem

---@param kernel rofl.Kernel
function SensorSystem.new(kernel)
  local instance = System.new("rofl.SensorSystem", kernel)
  setmetatable(instance, SensorSystem)

  ---@diagnostic disable-next-line: undefined-global
  instance.gravity = aero.getGravity()

  instance.backgroundRoutines = {
    function()
      while true do
        instance:refresh()
        os.sleep(0.5)
      end
    end,
    function()
      instance:backgroundRoutineAnchorPosition()
    end,
  }

  return instance
end

---@return rofl.ShipState
function SensorSystem:getShipState()
  ---@type rofl.ShipState
  return {
    mass = self.mass,
    centerOfMass = self.centerOfMass,
    position = self.anchorPosition,
    orientation = self.orientation,
    orientationEuler = self.shipAngles,
    airPressure = self.airPressure,
    anchorPosition = self.anchorPosition,
    velocity = self.velocity,
    angularVelocity = self.angularVelocity,
    angularAcceleration = self.angularAcceleration,
    pressureFunc = self.pressureFunc,
    intertiaTensor = self.intertiaTensor,
  }
end

function SensorSystem:backgroundRoutineAnchorPosition()
  ---@type ccTweaked.peripheral.Modem
  local modem = peripheral.find("modem", function(_, t)
    return t.isWireless()
  end) or error("No modem attached, unable to locate anchor")

  assert(modem.isWireless())

  modem.open(ANCHOR_CHANNEL)

  while true do
    local _, _, _, _, message, _ = os.pullEvent("modem_message")

    if type(message) == "table" then
      self.anchorPosition = vector.new(message.x, message.y, message.z)
      -- self.anchorPosition = self.anchorPosition:add(vector.new(0.5, 0.5, 0.5))
      settings.set(ANCHOR_SETTING, self.anchorPosition)
      settings.save(SENSORS_CONFIG_PATH)
    end
  end
end

---@private
function SensorSystem:recomputeAverageAltitude()
  --- prevent null values
  self.altitudeBack = self.altitudeBack or self.SEA_LEVEL
  self.altitudeFront = self.altitudeFront or self.altitudeBack

  --- compute average
  self.altitude = (self.altitudeBack + self.altitudeFront) / 2
end

function SensorSystem:refresh()
  local sensors = self.kernel.sensors

  parallel.waitForAll(table.unpack({
    -- Center of Mass
    function()
      self.centerOfMass = sublevel.getCenterOfMass()
    end,

    -- Mass
    function()
      self.mass = sublevel.getMass()
    end,

    -- Air Pressure (Front)
    function()
      self.airPressure = sensors.front.altitude:getAirPressure()
    end,

    -- Velocity
    function()
      self.velocity = sublevel.getVelocity()
    end,

    -- Altitude (back)
    function()
      self.altitudeBack = sensors.back.altitude:getHeight()
      self:recomputeAverageAltitude()
    end,

    -- Altitude (front)
    function()
      self.altitudeFront = sensors.front.altitude:getHeight()
      self:recomputeAverageAltitude()
    end,

    -- Position & Orientation
    function()
      local pose = sublevel.getLogicalPose()
      self.orientation = pose.orientation
      self.pitch, self.yaw, self.roll = pose.orientation:toEuler()

      self.rotationPoint = pose.rotationPoint

      self.shipAngles = {
        yaw = self.yaw,
        pitch = self.pitch,
        roll = self.roll,
      }
      self.shipPosition = pose.position
    end,

    -- Angular Velocity
    function()
      local old = self.angularVelocity or vector.new(0, 0, 0)

      self.angularVelocity = sublevel.getAngularVelocity()

      local now = os.epoch("utc") / 1000

      if self.angularVelocityLastUpdated then
        local dt = now - (self.angularVelocityLastUpdated or now)

        self.angularAcceleration = self.angularVelocity:sub(old):div(dt)
        self.angularVelocityLastUpdated = now
      else
        self.angularAcceleration = vector.new(0, 0, 0)
        self.angularVelocityLastUpdated = now
      end
    end,

    -- Pressure Function
    function()
      local raw = aero.getRaw()
      local pressure = raw.pressureFunction

      ---@param y number
      ---@return number
      self.pressureFunc = function(y)
        return pressure.evaluateFunction(y)
      end
    end,

    -- Intertia Tensor
    function()
      --- TODO: replace with sublevel.getIntertiaTensor
      self.intertiaTensor = Matrix.identity(3)
    end,
  }))
end

function SensorSystem:_init()
  settings.load(SENSORS_CONFIG_PATH)

  local anchor = settings.get(ANCHOR_SETTING, vector.new(0, 0, 0))
  self.anchorPosition = vector.new(anchor.x, anchor.y, anchor.z)
  self:refresh()
end

function SensorSystem:_update(dt) end

return SensorSystem
