local Display = require("display")

---@class rofl.DisplayEngineInfo : rofl.Display
local DisplayEngineInfo = Display:new(
  peripheral.wrap("monitor_5") --[[@as ccTweaked.peripheral.Monitor]]
)
DisplayEngineInfo.refreshRate = 30
DisplayEngineInfo.__index = DisplayEngineInfo

function DisplayEngineInfo:_draw(rofl)
  local sensors = rofl:getSystem("rofl.SensorSystem")

  term.clear()
  term.setCursorPos(1, 1)
  print("Running: ", rofl.engine:isRunning(), "Key: ", rofl.engine:isKeyTurned())
  print("RPM ", rofl.engine:getRpm())
  print("SU ", rofl.engine:getSu())
  print("Fuel ", rofl.engine:getFuel())

  local pitch, roll = table.unpack(rofl.sensors.front.gimbal:getAngles())


  print(string.format("Pitch %.1f", pitch))
  print(string.format("Roll %.1f", roll))


  print("COM=", sensors.centerOfMass)
  print("MASS=", sensors.mass)
  print("GRAV=", sensors.gravity:length())
end

return DisplayEngineInfo
