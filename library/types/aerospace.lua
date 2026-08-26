---@meta

---@module "aero"
local aero = {}

---@return ccTweaked.Vector
function aero:getGravity() end

---@param position Vector
---@return number
function aero:getAirPressure(position) end

---@module "aero"
return aero
