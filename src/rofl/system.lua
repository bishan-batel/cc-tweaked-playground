---@class rofl.System
---@field backgroundRoutines [function]
---@field rofl rofl.Roflcopter
---@field name string
local System = {}
System.__index = System

---@generic T
---@param name `T`
---@param rofl rofl.Roflcopter
---@return `T`
function System.new(name, rofl)
  local self = setmetatable({}, System)
  self.rofl = rofl
  self.name = name

  return self
end

function System:_init()
end

---@param dt number
function System:_update(dt)
end

return System
