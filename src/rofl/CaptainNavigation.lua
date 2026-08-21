local Display = require("display")

---@class rofl.CaptainDisplayNav : rofl.Display
local CaptainDisplayNav = Display:new(
  peripheral.wrap("monitor_3") --[[@as ccTweaked.peripheral.Monitor]]
)
CaptainDisplayNav.refreshRate = 10
CaptainDisplayNav.__index = CaptainDisplayNav

function CaptainDisplayNav:_draw(rofl)
  term.clear()

  term.setCursorPos(1, 1)
  term.write("FM")

  term.setCursorPos(1, 2)
  term.write("WP")

  term.setCursorPos(1, 3)
  term.write("DST")
  term.setCursorPos(1, 4)
  term.write("ETA")

  term.clear()
  term.setCursorPos(1, 1)
  print("Running: ", rofl.engine:isRunning(), "Key: ", rofl.engine:isKeyTurned())
  print("RPM ", rofl.engine:getRpm())
  print("SU ", rofl.engine:getSu())
  print("Fuel ", rofl.engine:getFuel())
  -- print(math.random())
  -- for i, line in ipairs(rofl.engine.target.dump()) do
  --   term.setCursorPos(1, i)
  --   print(line)
  -- end
end

return CaptainDisplayNav
