---@module 'class'
local class = {}

---@param classObj table
---@param derivedObj table
function class.derived(classObj, derivedObj)
  classObj.__index = classObj
  setmetatable(classObj, derivedObj)
end

---@module "class"
return class
