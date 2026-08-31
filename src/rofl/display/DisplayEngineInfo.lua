local Display = require("display.init")
local class = require("..class")

---@class rofl.DisplayEngineInfo : rofl.Display
local DisplayEngineInfo = {}

class.derived(DisplayEngineInfo, Display)

TEXT_SCALE = 0.5

local PROPELLER_FRAMES = {
  paintutils.parseImage([[
   7
  77
    7
     77
     7
  ]]),
  paintutils.parseImage([[

   7
  77777
     7

  ]]),
  paintutils.parseImage([[
     7
     77
    7
  77
   7
  ]]),
  paintutils.parseImage([[
    7
    77
    7
   77
    7
  ]]),
}

---@param monitor string | ccTweaked.peripheral.Monitor
function DisplayEngineInfo.new(monitor)
  local self = Display.new(monitor)
  setmetatable(self, DisplayEngineInfo)
  self.refreshRate = 8
  return self
end

function DisplayEngineInfo:_draw(kernel)
  local engine = kernel.engine
  local propSystem = kernel:getSystem("rofl.PropellerControlSystem")

  self.monitor.setTextScale(TEXT_SCALE)

  local width, height = term.getSize()

  term.clear()
  paintutils.drawFilledBox(1, 1, width, height, colors.black)

  local thrustAlloc = propSystem.lastThrustAllocation or {}

  for i, propeller in ipairs(propSystem.liftPropellers) do
    i = #propSystem.liftPropellers - i + 1

    local w = 27
    local h = 7

    local vmargin = 0
    local hmargin = 0

    local x = 2 + ((i + 1) % 2) * (w + hmargin)
    local y = 2 + math.floor((i - 1) / 2) * (h + vmargin)

    -- paintutils.drawBox(x, y, x + w, y + h, colors.gray)
    term.setCursorPos(x + 2, y + 1)
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.write(propeller.name)

    term.write(" ")

    term.setTextColor(colors.lightGray)
    term.write(string.format("%.0f", propeller.lastSentRpm))

    term.setTextColor(colors.gray)
    term.write("RPM ")

    local index = 1 + math.floor(8 * kernel.uptime + i * 7) % #PROPELLER_FRAMES

    if not engine:isRunning() then
      index = 1
    end

    paintutils.drawImage(PROPELLER_FRAMES[index], x + 19, y + 2)

    for name, thrust in pairs(thrustAlloc) do
      if name == propeller.name then
        local thrustA = thrust / 2
        local thrustB = thrustA * 1.01793445653
        thrustB = thrustA

        if thrustA > thrustB then
          thrustA, thrustB = thrustB, thrustA
        end

        term.setCursorPos(x + 2, y + 2)
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.red)
        term.write(string.format("ThrustA: %.0f", thrustA))

        term.setCursorPos(x + 2, y + 3)
        term.setTextColor(colors.blue)
        term.write(string.format("ThrustA: %.0f", thrustB))

        term.setCursorPos(x + 2, y + 4)
        term.setTextColor(colors.white)
        term.write(string.format("Thrust: %.0f", thrust))
      end
    end

    term.setBackgroundColor(colors.gray)

    local yOff = y + 2

    for name, delta in pairs(propeller.deltaRpm) do
      term.setCursorPos(x + 2, yOff)

      term.setTextColor(colors.yellow)
      term.write(string.format("%6s", name))

      term.setTextColor(colors.white)
      term.write("=")

      if delta > 0 then
        term.setTextColor(colors.lime)
      elseif delta < 0 then
        term.setTextColor(colors.red)
      else
        term.setTextColor(colors.lightGray)
      end

      term.write(string.format("%+0.2f", delta))

      yOff = yOff + 1
    end
  end
end

return DisplayEngineInfo
