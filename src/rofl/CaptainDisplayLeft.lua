local Display = require("display")

local colorutils = require("colorutils")

---@alias rofl.CaptainDisplayLeft.Data { altitude: number, velocityForward: number, airPressure: number, heading: number }

local VELOCITY_GRADIENT = {
  colors.white,
  colors.lightBlue,
  colors.blue,
  colors.yellow,
  colors.orange,
  colors.red,
}

local PRESSURE_GRADIENT = {
  colors.red,
  colors.red,
  colors.red,
  colors.red,
  colors.red,
  colors.red,
  colors.red,
  colors.orange,
  colors.orange,
  colors.yellow,
  colors.yellow,
  colors.green
}

local MAX_VELOCITY = 20

---@class rofl.CaptainDisplayLeft : rofl.Display
local CaptainDisplayLeft = Display:new(
  peripheral.wrap("monitor_2") --[[@as ccTweaked.peripheral.Monitor]]
)

CaptainDisplayLeft.refreshRate = 20

CaptainDisplayLeft.__index = CaptainDisplayLeft

function CaptainDisplayLeft:_draw(rofl)
  local data = self:getInfoData(rofl)

  local width, height = term.getSize()
  paintutils.drawFilledBox(1, 1, width, height, colors.black)

  self:_drawAlt(rofl, data)
  self:_drawAirPressure(rofl, data)
  self:_drawVelocity(rofl, data)
  self:_drawHeading(rofl, data)
end

---@param rofl rofl.Roflcopter
---@param data rofl.CaptainDisplayLeft.Data
function CaptainDisplayLeft:_drawAlt(rofl, data)
  term.setCursorPos(1, 1)
  term.setTextColor(colors.lightGray)
  term.write("ALT   ")

  term.setTextColor(colors.yellow)

  term.write(string.format("%05.1f", data.altitude))
  term.setTextColor(colors.gray)
  term.write(" m")
end

---@param rofl rofl.Roflcopter
---@param data rofl.CaptainDisplayLeft.Data
function CaptainDisplayLeft:_drawAirPressure(rofl, data)
  term.setCursorPos(1, 3)
  term.setTextColor(colors.lightGray)
  term.setTextColor(colors.lightGray)
  term.write("APRES ")

  term.setTextColor(colorutils.gradient(PRESSURE_GRADIENT, data.airPressure))
  term.write(string.format("%5.0f", 100 * data.airPressure))
  term.setTextColor(colors.gray)
  term.write(" %")
end

---@param rofl rofl.Roflcopter
---@param data rofl.CaptainDisplayLeft.Data
function CaptainDisplayLeft:_drawVelocity(rofl, data)
  term.setCursorPos(1, 5)
  term.setTextColor(colors.lightGray)
  term.write("VEL  ")

  local vel = math.abs(data.velocityForward)

  if data.velocityForward < 0 then
    term.setTextColor(colors.red)
    term.write("-")
  else
    term.setTextColor(colors.green)
    term.write("+")
  end

  term.setTextColor(colorutils.gradient(VELOCITY_GRADIENT, vel / MAX_VELOCITY))
  term.write(string.format("%  5.1f", vel))
  term.setTextColor(colors.gray)
  term.write(" m/s")
end

---@param rofl rofl.Roflcopter
---@param data rofl.CaptainDisplayLeft.Data
function CaptainDisplayLeft:_drawHeading(rofl, data)
  local topLeft = vector.new(17, 1, 1)
  local bottomRight = vector.new(29, 5, 1)

  local center = bottomRight:add(topLeft):div(2.0)

  -- paintutils.drawFilledBox(
  --   topLeft.x, topLeft.y,
  --   bottomRight.x, bottomRight.y,
  --   colors.black
  -- )

  local heading = data.heading


  local tip = vector.new(
    0.5 + math.round(math.cos(heading) * 2),
    0.5 + math.round(math.sin(heading) * 1),
    1
  )

  local headingDegree = math.fmod(math.deg(heading), 360.0)

  tip = tip:add(center)

  local dirChars = {
    [-45] = '/',
    [0] = '-',
    [45] = '\\',
    [90] = '|',
    [135] = '/',
    [180] = '-',
    [225] = '\\',
    [270] = '|',
    [315] = '/',
    [360] = '-'
  }

  local index = math.round(headingDegree / 45) * 45

  term.setCursorPos(center.x, center.y)
  term.write("*")

  term.setCursorPos(tip.x, tip.y)
  term.write(dirChars[index])

  term.setCursorPos(topLeft.x, topLeft.y)

  term.setTextColor(colors.lightGray)

  term.setBackgroundColor(colors.black)

  term.setTextColor(colors.red)
  term.setCursorPos(center.x, topLeft.y)
  term.write("N")

  term.setTextColor(colors.blue)
  term.setCursorPos(center.x, bottomRight.y)
  term.write("S")

  term.setTextColor(colors.lime)
  term.setCursorPos(bottomRight.x - 3, center.y)
  term.write("E")

  term.setTextColor(colors.magenta)
  term.setCursorPos(topLeft.x + 3, center.y)
  term.write("W")
end

---@param rofl rofl.Roflcopter
---@return rofl.CaptainDisplayLeft.Data
function CaptainDisplayLeft:getInfoData(rofl)
  return {
    altitude = (rofl.sensors.front.altitude:getHeight() + rofl.sensors.back.altitude:getHeight()) /
      2,
    airPressure = (rofl.sensors.front.altitude:getAirPressure() + rofl.sensors.back.altitude:getAirPressure()) /
      2,
    velocityForward = rofl.sensors.front.velocityForward:getVelocity(),
    heading = rofl.sensors.navigation_table.getRelativeAngleRad(),
  }
end

return CaptainDisplayLeft
