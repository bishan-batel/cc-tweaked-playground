local Display = require("display")
local Pine3D = require("..Pine3D")

---@class rofl.CaptainDisplayVisualizer : rofl.Display
---@field objects [PineObject]
local CaptainDisplayVisualizer = Display:new(
  peripheral.wrap("monitor_6") --[[@as ccTweaked.peripheral.Monitor]]
)
CaptainDisplayVisualizer.__index = CaptainDisplayVisualizer

CaptainDisplayVisualizer.refreshRate = 5

function CaptainDisplayVisualizer:_init()
  self.monitor.setTextScale(0.5)
  local width, height = self.monitor.getSize()

  local old = term.redirect(self.monitor)

  self.frame = Pine3D.newFrame(nil, nil, width, height)
  self.frame:setCamera(1.5, 1.9, 0, 0, 0, -30)
  self.frame:setFoV(30)

  local cubeModel = Pine3D.models:cube {
    color = colors.purple,
    side = colors.red,
    side2 = colors.orange,
    top = colors.yellow,
    bottom = colors.cyan,
    bottom2 = colors.blue
  }
  cubeModel = cubeModel:scaleNonUniform(vector.new(0.4, 0.4, 0.8))

  -- cubeModel = Pine3D.loadModel "/programs/pinetree.lua"
  -- cubeModel = cubeModel:translate(0, -0.5, 0):scale(0.9)


  local plane = Pine3D.models:plane {
    size = 1,
    color = colors.green
  }

  self.objects = {
    self.frame:newObject(
      cubeModel,
      5,
      0,
      0
    ),
    -- self.frame:newObject(
    --   plane,
    --   5,
    --   -0.6,
    --   0
    -- )
  }

  self.ship = self.objects[1]
  self.ground = self.objects[2]

  self.frame:depthInterpolation(true)
  self.frame:setWireFrame(false)

  term.redirect(old)
end

function CaptainDisplayVisualizer:_draw(kernel)
  local sensors = kernel:getSystem "rofl.SensorSystem"
  local engine = kernel.engine


  self.objects[1]:setRot(
    math.rad(sensors.pitch),
    0,
    -math.rad(sensors.roll)
  )

  self.frame:drawObjects(self.objects)
  term.redirect(self.monitor)
  self.frame:drawBuffer()
end

CaptainDisplayVisualizer:_init()

return CaptainDisplayVisualizer
