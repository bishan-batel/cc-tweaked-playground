local Display = require("display")
local Pine3D = require("..Pine3D")

---@class rofl.CaptainDisplayVisualizer : rofl.Display
---@field objects [PineObject]
local CaptainDisplayVisualizer = Display:new(
  peripheral.wrap("monitor_4") --[[@as ccTweaked.peripheral.Monitor]]
)
CaptainDisplayVisualizer.__index = CaptainDisplayVisualizer

CaptainDisplayVisualizer.refreshRate = 60

function CaptainDisplayVisualizer:_init()
  local width, height = self.monitor.getSize()

  local old = term.redirect(self.monitor)

  self.frame = Pine3D.newFrame(nil, nil, width, height)
  self.frame:setCamera(1, 0.6, 0)
  self.frame:setFoV(60)

  self.objects = {
    self.frame:newObject("/programs/pinetree.lua", 2, 0, 0, nil, math.pi * 0.25,
      nil),
  }

  self.frame:setWireFrame(true)

  term.redirect(old)
end

function CaptainDisplayVisualizer:_draw(rofl)
  local engine = rofl.engine
end

CaptainDisplayVisualizer:_init()

return CaptainDisplayVisualizer
