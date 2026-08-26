local Display = require("display")

---@class rofl.CaptainDisplayNav : rofl.Display
local CaptainDisplayNav = Display:new(
  peripheral.wrap("monitor_12") --[[@as ccTweaked.peripheral.Monitor]]
)
CaptainDisplayNav.refreshRate = 5
CaptainDisplayNav.__index = CaptainDisplayNav

function CaptainDisplayNav:_draw(kernel)
end

return CaptainDisplayNav
