local Display = require("display")

---@class rofl.CaptainDisplayVisualizer : rofl.Display
local CaptainDisplayVisualizer = Display:new(
  peripheral.wrap("monitor_3") --[[@as ccTweaked.peripheral.Monitor]]
)
CaptainDisplayVisualizer.refreshRate = 60
CaptainDisplayVisualizer.__index = CaptainDisplayVisualizer

function CaptainDisplayVisualizer:_draw(rofl)
  term.clear()

  term.setCursorPos(1, 1)
  term.write("Visualizer")
end

return CaptainDisplayVisualizer
