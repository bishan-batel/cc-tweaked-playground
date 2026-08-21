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
end

return CaptainDisplayNav
