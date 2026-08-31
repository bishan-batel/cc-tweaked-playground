---@class BakedFunction
---@field points [ [number, number] ]
---@field resolution number
---@field min number
---@field max number
local BakedFunction = {}
BakedFunction.__index = BakedFunction

---@param func fun(x: number): number
---@param min number
---@param max number
---@param resolution number
function BakedFunction.bake(func, min, max, resolution)
  local self = setmetatable({}, BakedFunction)
  self.points = {}
  self.min = min
  self.max = max
  self.resolution = resolution

  local x = min

  local dt = (max - min) / resolution

  while x <= max do
    local y = func(x)

    table.insert(self.points, { x, y })

    x = x + dt
  end

  return self
end

---@param i number
function BakedFunction:sampleRaw(i)
  return self.points[
    math.round(i) --[[@as integer]]
  ]
end

---@param x number
function BakedFunction:sample(x)
  local percentage = (x - self.min) / (self.max - self.min)

  local i = math.round(percentage)
  local j = math.min(i + 1, 1)

  local y1 = self:sampleRaw(i)
  local y2 = self:sampleRaw(j)
end

return BakedFunction
