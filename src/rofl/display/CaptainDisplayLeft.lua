local Display = require("display.init")
local class = require "..class"

local colorutils = require("colorutils")

---@class rofl.CaptainDisplayLeft.Data
---@field altitude number
---@field velocityForward number
---@field airPressure number
---@field heading number

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
local CaptainDisplayLeft = {}
class.derived(CaptainDisplayLeft, Display)

---@return rofl.CaptainDisplayLeft
---@param monitor string
function CaptainDisplayLeft.new(monitor)
  local self = Display.new(monitor)

  self = setmetatable(
    self,
    CaptainDisplayLeft
  )

  self.refreshRate = 5

  ---@type rofl.CaptainDisplayLeft
  return self
end

function CaptainDisplayLeft:_draw(kernel)
  local data = self:getInfoData(kernel)

  local width, height = term.getSize()
  paintutils.drawFilledBox(1, 1, width, height, colors.black)

  self:_drawAlt(kernel, data)
  self:_drawAirPressure(kernel, data)
  self:_drawVelocity(kernel, data)
  self:_drawHeading(kernel, data)
end

---@param rofl rofl.Kernel
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

---@param rofl rofl.Kernel
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

---@param rofl rofl.Kernel
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

---@param rofl rofl.Kernel
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
    [360] = '-',
  }

  local index = math.round(headingDegree / 45) * 45

  term.setCursorPos(center.x, center.y)
  term.write("*")

  term.setCursorPos(tip.x, tip.y)
  term.write(dirChars[index])
  term.write(index)

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

---@param kernel rofl.Kernel
---@return rofl.CaptainDisplayLeft.Data
function CaptainDisplayLeft:getInfoData(kernel)
  local sensors = kernel:getSystem("rofl.SensorSystem")
  return {
    altitude = sensors.altitude,
    airPressure = sensors.airPressure,
    velocityForward = sensors.velocity:length(),
    heading = math.rad(0)
  }
end

return CaptainDisplayLeft
