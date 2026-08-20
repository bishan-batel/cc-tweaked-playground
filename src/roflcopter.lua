---@class rofl.InfoDisplay.Sensors : rofl.Monitor
local InfoDisplaySensors = {}

---@class rofl.Roflcopter
local Roflcopter = {
  displays = {
    sensors = peripheral.wrap("monitor_2") --[[@as ccTweaked.peripheral.Monitor]]
  }
}

function Roflcopter:init()
end

---@param dt number
function Roflcopter:update(dt)
  self:updateInfoDisplaySensors()
end

function Roflcopter:updateInfoDisplaySensors()
  local old = term.redirect(self.displays.sensors)

  local width, height = term.getSize()

  paintutils.drawFilledBox(
    1, 1, width, height, 0x0
  )

  term.redirect(old)
end

function Roflcopter:run()
  local previousTime = os.epoch("utc")

  self:init()

  while true do
    local currentTime = os.epoch("utc")
    local dt = (currentTime - previousTime) / 1000.0

    self:update(dt)

    previousTime = currentTime
    os.sleep(0.5)
  end
end

Roflcopter:run()
