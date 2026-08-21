local Pine3D = require("/Pine3D")

-- term.redirect(peripheral.find("monitor"))

local frame = Pine3D.newFrame()

frame:setCamera(1, 0.6, 0)
frame:setFoV(60)

local objects = {
  frame:newObject("/programs/pinetree.lua", 2, 0, 0, nil, math.pi * 0.25, nil),
}

frame:setWireFrame(true)

local t = 0

while true do
  t = t + 0.05
  objects[1]:setRot(math.pi * 0.25 * t, math.pi * 0.25 * t, math.pi * 0.25 * t)
  frame:drawObjects(objects)
  frame:drawBuffer()
  sleep(0.05)
end
