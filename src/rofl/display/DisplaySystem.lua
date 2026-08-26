local System = require("system")

---@class rofl.DisplaySystem : rofl.System
---@field private _displays [rofl.Display]
local DisplaySystem = {}
DisplaySystem.__index = DisplaySystem

---@param kernel rofl.Kernel
function DisplaySystem.new(kernel)
  local instance = System.new("rofl.DisplaySystem", kernel)
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
      display:display(self.kernel)
    end)
  end
  parallel.waitForAll(table.unpack(displayFunctions))
end

return DisplaySystem
