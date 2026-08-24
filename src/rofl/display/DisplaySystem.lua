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
    require("display.CaptainDisplayLeft"),
    require("display.CaptainNavigation"),
    require("display.CaptainDisplayVisualizer"),
    require("display.DisplayEngineInfo")
  }
end

function DisplaySystem:_update(dt)
  local displayFunctions = {}
  for _, display in ipairs(self._displays) do
    table.insert(displayFunctions, function()
      display:display(self.rofl)
    end)
  end
  parallel.waitForAll(table.unpack(displayFunctions))
end

return DisplaySystem
