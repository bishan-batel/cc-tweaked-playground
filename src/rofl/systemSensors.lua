local System = require("system")

---@class rofl.SensorSystem : rofl.System
---@field centerOfMass ccTweaked.Vector
---@field mass number
---@field gravity ccTweaked.Vector
---@field airPressure number
local SensorSystem = {}
SensorSystem.__index = SensorSystem

---@param rofl rofl.Roflcopter
function SensorSystem.new(rofl)
  local instance = System.new("rofl.SensorSystem", rofl)
  setmetatable(instance, SensorSystem)

  instance.gravity = aero.getGravity() --[[@as ccTweaked.Vector]]

  instance.backgroundRoutines = {
    function()
      while true do
        instance:refresh()
        os.sleep(0.5)
      end
    end
  }

  return instance
end

function SensorSystem:refresh()
  parallel.waitForAll(
    function()
      self.centerOfMass = sublevel.getCenterOfMass()
    end,
    function()
      self.mass = sublevel.getMass()
    end,
    function()
      self.airPressure = self.rofl.sensors.front.altitude:getAirPressure()
    end
  )
end

function SensorSystem:_init() self:refresh() end

function SensorSystem:_update(_) end

return SensorSystem
