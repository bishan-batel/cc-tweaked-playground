local Display = require("display")

---@class rofl.CaptainDisplayNav : rofl.Display
local CaptainDisplayNav = Display:new(
  peripheral.wrap("monitor_12") --[[@as ccTweaked.peripheral.Monitor]]
)
CaptainDisplayNav.refreshRate = 5
CaptainDisplayNav.__index = CaptainDisplayNav

function CaptainDisplayNav:_draw(rofl)
  local sensors = rofl:getSystem("rofl.SensorSystem")

  term.clear()
  term.setCursorPos(1, 1)
  print("Running: ", rofl.engine:isRunning(), "Key: ", rofl.engine:isKeyTurned())
  print("RPM=", rofl.engine:getRpm(), "SU=", rofl.engine:getSu(), "FL=",
    rofl.engine:getFuel())

  local pitch, roll = table.unpack(rofl.sensors.front.gimbal:getAngles())


  print(string.format("Pitch %.1f", pitch))
  print(string.format("Roll %.1f", roll))

  local propellers = rofl:getSystem("rofl.PropellerControlSystem")


  print(string.format("LPA=%.2f", propellers.lastPitchCorrection or 0))
  print(string.format("LRA=%.2f", propellers.lastRollCorrection or 0))
  print(string.format("BRPM=%.0f", propellers.baseRpm or 0))
end

return CaptainDisplayNav
