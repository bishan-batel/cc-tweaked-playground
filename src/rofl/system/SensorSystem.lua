local System = require "system.init"

local ANCHOR_SETTING = "anchorPosition"
local SENSORS_CONFIG_PATH = "anchor_config"

local ANCHOR_CHANNEL = 6969

---@class rofl.SensorSystem : rofl.System
---@field centerOfMass ccTweaked.Vector Center of mass of the sublevel
---@field mass number Mass of the sublevel
---@field gravity ccTweaked.Vector Gravity applied to the sublkevel
---@field velocity ccTweaked.Vector Velocity of the sublevel
---@field angularVelocity ccTweaked.Vector Angular Velocity of the sublevel
---@field airPressure number Air pressure of the sublevel
---@field rootPropellerPosition ccTweaked.Vector Position of the root propellar
---@field altitudeFront number
---@field altitudeBack number
---@field altitude number
---@field anchorPosition ccTweaked.Vector
---@field pitch number Pitch of the ship
---@field yaw number Yaw of the ship
---@field roll number Roll of the ship
---@field shipAngles EulerAngles Pitch,Yaw, & Roll of the Ship
local SensorSystem = {
  SEA_LEVEL = 90
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
    function() instance:backgroundRoutineAnchorPosition() end
  }

  return instance
end

function SensorSystem:backgroundRoutineAnchorPosition()
  ---@type ccTweaked.peripheral.Modem
  local modem = peripheral.find(
    "modem",
    function(_, t) return t.isWireless() end
  ) or error("No modem attached")

  assert(modem.isWireless())

  modem.open(ANCHOR_CHANNEL)

  while true do
    local _, _, _, _, message, _ =
      os.pullEvent "modem_message"

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

  parallel.waitForAll(table.unpack {
    function() self.centerOfMass = sublevel.getCenterOfMass() end,
    function() self.mass = sublevel.getMass() end,
    function() self.airPressure = sensors.front.altitude:getAirPressure() end,
    function() self.velocity = sublevel.getVelocity() end,
    function() self.angularVelocity = sublevel.getAngularVelocity() end,
    function()
      self.altitudeBack = sensors.back.altitude:getHeight()
      self:recomputeAverageAltitude();
    end,
    function()
      self.altitudeFront = sensors.front.altitude:getHeight()
      self:recomputeAverageAltitude()
    end,
    function()
      local pose = sublevel.getLogicalPose()
      self.orientation = pose.orientation
      self.pitch, self.yaw, self.roll = pose.orientation:toEuler()

      self.rotationPoint = pose.rotationPoint

      self.shipAngles = {
        yaw = self.yaw,
        pitch = self.pitch,
        roll = self.roll
      }
      self.shipPosition = pose.position
    end,
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
    function()
      local raw = aero.getRaw()
      local pressure = raw.pressureFunction

      ---@param y number
      ---@return number
      self.pressureFunc = function(y)
        return pressure.evaluateFunction(y)
      end
    end
  })
end

function SensorSystem:_init()
  settings.load(SENSORS_CONFIG_PATH)

  local anchor = settings.get(ANCHOR_SETTING, vector.new(0, 0, 0))
  self.anchorPosition = vector.new(anchor.x, anchor.y, anchor.z)
  self:refresh()
end

function SensorSystem:_update(dt)
end

return SensorSystem
