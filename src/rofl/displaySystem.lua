local System = require("system")

---@class rofl.DisplaySystem : rofl.System
---@field private _displays [rofl.Display]
local DisplaySystem = {}
DisplaySystem.__index = DisplaySystem

---@param rofl rofl.Roflcopter
function DisplaySystem.new(rofl)
  local instance = System.new("rofl.DisplaySystem", rofl)
  setmetatable(instance, DisplaySystem)

  return instance
end

function DisplaySystem:_init()
  self._displays = {
    require("CaptainDisplayLeft"),
    require("CaptainNavigation"),
    require("CaptainDisplayVisualizer"),
    require("DisplayEngineInfo")
  }
end

function DisplaySystem:_update(dt)
  for _, display in ipairs(self._displays) do
    display:display(self.rofl)
  end
end

return DisplaySystem
