---@class rofl.Thruster : rofl.PeripheralWrapper
---@field device cctweaked.peripheral.Thruster
local Thruster = {}

Thruster.__index = Thruster

---@return rofl.Thruster
---@param thruster string | cctweaked.peripheral.Thruster
function Thruster.new(thruster)
  local self = setmetatable({}, Thruster)


  if type(thruster) == "string" then
    self.device = peripheral.wrap(thruster) --[[@as cctweaked.peripheral.Thruster]]
  else
    self.device = thruster
  end

  return self
end
