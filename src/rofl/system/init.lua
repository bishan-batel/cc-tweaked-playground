---@class rofl.System
---@field backgroundRoutines [function]
---@field kernel rofl.Kernel
---@field name string
local System = {}
System.__index = System

---@generic T
---@param name `T`
---@param kernel rofl.Kernel
---@return `T`
function System.new(name, kernel)
  local self = setmetatable({}, System)
  self.kernel = kernel
  self.name = name
  self.backgroundRoutines = {}

  return self
end

function System:_init()
end

---@param dt number
function System:_update(dt)
end

return System
