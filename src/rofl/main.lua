local Engine = require("engine")

---@class rofl.Roflcopter
local Roflcopter = {

  ---@type {[string]: rofl.System}
  systems = {},

  animatronic = peripheral.wrap("top") --[[@as ccTweaked.peripheral.Animatronic]],

  dt = 0,
  uptime = 0.0,

  displayBootscreen = false,

  relays = {
    peripheral.wrap("redstone_relay_1") --[[@as ccTweaked.peripheral.RedstoneRelay]],
    peripheral.wrap("redstone_relay_2") --[[@as ccTweaked.peripheral.RedstoneRelay]],
  },

  sensors = {
    navigation_table =
      peripheral.wrap("navigation_table_1") --[[@as cctweaked.peripheral.NavigationTable ]],
    front = {
      velocityForward =
        peripheral.wrap("velocity_sensor_3") --[[@as cctweaked.peripheral.VelocitySensor]],
      velocityRight =
        peripheral.wrap("velocity_sensor_4") --[[@as cctweaked.peripheral.VelocitySensor]],
      altitude =
        peripheral.wrap("altitude_sensor_1") --[[@as cctweaked.peripheral.AltitudeSensor]],
      gimbal =
        peripheral.wrap("gimbal_sensor_1") --[[@as cctweaked.peripheral.GimbalSensor ]],
    },
    back = {
      velocityForward =
        peripheral.wrap("velocity_sensor_1") --[[@as cctweaked.peripheral.VelocitySensor]],
      velocityRight =
        peripheral.wrap("velocity_sensor_2") --[[@as cctweaked.peripheral.VelocitySensor]],
      altitude =
        peripheral.wrap("altitude_sensor_0") --[[@as cctweaked.peripheral.AltitudeSensor]],
      gimbal =
        peripheral.wrap("gimbal_sensor_2") --[[@as cctweaked.peripheral.GimbalSensor ]]
    },

    landing = {
      front = {
        left =
          peripheral.wrap("optical_sensor_2") --[[@as cctweaked.peripheral.OpticalSensor]],
        right =
          peripheral.wrap("optical_sensor_3") --[[@as cctweaked.peripheral.OpticalSensor]],
      },
      back = {
        left =
          peripheral.wrap("optical_sensor_0") --[[@as cctweaked.peripheral.OpticalSensor]],
        right =
          peripheral.wrap("optical_sensor_1") --[[@as cctweaked.peripheral.OpticalSensor]],
      }

    },
  },

  ---@type rofl.Engine
  engine = nil
}

function Roflcopter:_init()
  self.engine = Engine.new(Roflcopter)

  self:addSystem(require("displaySystem").new(self))
  self:addSystem(require("systemPropellarControl").new(self))

  term.clear()
  term.setCursorPos(1, 1)

  -- startup all systems
  for _, system in pairs(self.systems) do
    local success, err = pcall(system._init, system)
    if not success then
      print("ERROR ON INIT:", system.name, " ", err)
    end
  end
end

---@param system rofl.System
function Roflcopter:addSystem(system)
  self.systems[system.name] = system
end

---@param dt number
function Roflcopter:_update(dt)
  self.engine:_update(dt);

  local systemUpdates = {}

  for _, sys in pairs(self.systems) do
    table.insert(systemUpdates, function()
      sys:_update(dt)
    end)
  end

  parallel.waitForAll(table.unpack(systemUpdates))
end

function Roflcopter:_mainLoop()
  local previousTime = os.epoch("utc")

  while true do
    local currentTime = os.epoch("utc")
    self.dt = (currentTime - previousTime) / 1000.0
    self.uptime = self.uptime + self.dt

    self:_update(self.dt)

    previousTime = currentTime
    os.sleep(0.05)
  end
end

---@return [function]
function Roflcopter:_getGlobalThreads()
  local threads = {
    function() self:_mainLoop() end,
  }

  for _, system in ipairs(self.systems) do
    for _, routine in ipairs(system.backgroundRoutines) do
      table.insert(threads, routine)
    end
  end

  return threads
end

function Roflcopter:_run()
  self:_init()
  parallel.waitForAll(table.unpack(self:_getGlobalThreads()))
end

Roflcopter:_run()
