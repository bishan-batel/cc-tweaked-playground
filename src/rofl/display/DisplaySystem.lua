local System = require "system"
local CaptainLeft = require "display.CaptainDisplayLeft"
local CaptainNavigation = require "display.CaptainNavigation"
local Visualizer = require "display.CaptainDisplayVisualizer"
local EngineInfo = require "display.DisplayEngineInfo"

---@class rofl.DisplaySystem : rofl.System
---@field private displays [rofl.Display]
local DisplaySystem = {}
DisplaySystem.__index = DisplaySystem

---@param kernel rofl.Kernel
function DisplaySystem.new(kernel)
  local self = System.new("rofl.DisplaySystem", kernel)
  return setmetatable(self, DisplaySystem)
end

function DisplaySystem:_init()
  self.displays = {
    CaptainLeft.new("monitor_11"),
    CaptainNavigation.new("monitor_12"),
    Visualizer.new("monitor_6"),
    EngineInfo.new("monitor_5")
  }

  for _, display in pairs(self.displays) do
    display:init(self.kernel)
  end
end

function DisplaySystem:resetAllMonitors()
  local monitors = { peripheral.find('monitor') }
  ---@cast monitors [ccTweaked.peripheral.Monitor]

  for _, monitor in pairs(monitors) do
    monitor.clear()
  end
end

function DisplaySystem:_update(_)
  local native = term.native()

  for _, display in ipairs(self.displays) do
    display:display(self.kernel)
  end

  term.redirect(native)
end

return DisplaySystem
