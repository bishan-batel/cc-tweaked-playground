local System = require "system.init"

local ANCHOR_SETTING = "anchorPosition"
local SENSORS_CONFIG_PATH = "anchor_config"

local CHANNEL = 6969

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
---@field pitch number
---@field roll number
local SensorSystem = {}
SensorSystem.__index = SensorSystem

---@param rofl rofl.Roflcopter
function SensorSystem.new(rofl)
  local instance = System.new("rofl.SensorSystem", rofl)
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
  local modem =
    peripheral.wrap "modem_2" --[[@as ccTweaked.peripheral.Modem]]
    or error("No modem attached")

  assert(modem.isWireless())

  modem.open(CHANNEL)
  while true do
    local event, side, channel, replyChannel, message, distance =
      os.pullEvent "modem_message"

    if type(message) == "table" then
      self.anchorPosition = vector.new(message.x, message.y, message.z)
      settings.set(ANCHOR_SETTING, self.anchorPosition)
      settings.save(SENSORS_CONFIG_PATH)
    end
  end
end

function SensorSystem:refresh()
  local sensors = self.rofl.sensors

  parallel.waitForAll(table.unpack {
    function() self.centerOfMass = sublevel.getCenterOfMass() end,
    function() self.mass = sublevel.getMass() end,
    function() self.airPressure = sensors.front.altitude:getAirPressure() end,
    function() self.velocity = sublevel.getVelocity() end,
    function() self.angularVelocity = sublevel.getAngularVelocity() end,
    function()
      self.altitudeBack = sensors.back.altitude:getHeight()
      self.altitudeFront = self.altitudeFront or self.altitudeBack
      self.altitude = (self.altitudeBack + self.altitudeFront) / 2
    end,
    function()
      self.altitudeFront = sensors.front.altitude:getHeight()
      self.altitudeBack = self.altitudeBack or self.altitudeFront
      self.altitude = (self.altitudeBack + self.altitudeFront) / 2
    end,
    function()
      local angles = sensors.front.gimbal:getAngles()
      self.pitch = angles[1]
      self.roll = angles[2]
    end
  })
end

function SensorSystem:_init()
  settings.load(SENSORS_CONFIG_PATH)

  local anchor = settings.get(ANCHOR_SETTING, vector.new(0, 0, 0))
  self.anchorPosition = vector.new(anchor.x, anchor.y, anchor.z)
  self:refresh()
end

function SensorSystem:_update(_) end

return SensorSystem
