---@class rofl.InfoDisplay.Sensore
local InfoDisplaySensors = {}

---@class rofl.Roflcopter
local Roflcopter = {

  ---@type [rofl.Display]
  displays = {},

  animatronic = peripheral.wrap("top") --[[@as ccTweaked.peripheral.Animatronic]],

  dt = 0,
  uptime = 0.0,

  displayBootscreen = false,


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
  }
}


function Roflcopter:bootscreen()
  if not self.displayBootscreen then
    return
  end

  local allMonitors = { peripheral.find("monitor") }

  for i = 1, 10, 1 do
    for name, monitor in pairs(allMonitors) do
      ---@cast monitor ccTweaked.peripheral.Monitor
      monitor.setCursorPos(1, i)
      monitor.write("GOOSE OS LOADING " .. name)
    end
    os.sleep(0.2)
  end

  for _, monitor in pairs(allMonitors) do
    ---@cast monitor ccTweaked.peripheral.Monitor
    monitor.clear()
  end
end

function Roflcopter:init()
  self:bootscreen();
  self.animatronic.setTransition("rusty")




  self.displays = {
    require("CaptainDisplayLeft"),
    require("CaptainNavigation"),
    require("CaptainDisplayVisualizer"),
  }
end

---@param dt number
function Roflcopter:update(dt)
  for _, display in ipairs(self.displays) do
    display:display(self)
  end
end

function Roflcopter:run()
  local previousTime = os.epoch("utc")

  self:init()

  while true do
    local currentTime = os.epoch("utc")
    self.dt = (currentTime - previousTime) / 1000.0
    self.uptime = self.uptime + self.dt

    self:update(self.dt)

    previousTime = currentTime
    os.sleep(0.05)
  end
end

Roflcopter:run()
