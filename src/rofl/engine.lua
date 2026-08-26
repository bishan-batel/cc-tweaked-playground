---@class rofl.Engine
---@field rofl rofl.Kernel
---@field name string
---@field private side string
---@field private target ccTweaked.peripheral.Target
---@field private turnOn ccTweaked.peripheral.RedstoneRelay
---@field private turnOff ccTweaked.peripheral.RedstoneRelay
---@field private metrics rofl.Engine.Metrics
---@field private _running boolean
---@field isKeyTurned fun(): boolean
---@field metricSuLine integer
---@field metricRpmLine integer
---@field metricFuelLine integer
local Engine = {
  --- Minimum RPM required before turning off the kickstart battery
  KICKSTART_RPM = 64
}

---@class rofl.Engine.Metrics
---@field rpm  number
---@field su number
---@field fuel number

Engine.__index = Engine

---@param rofl rofl.Kernel
---@param name string
---@param side ccTweaked.peripheral.computerSide
---@param isKeyTurned fun(): boolean
function Engine.new(rofl, name, side, isKeyTurned)
  ---@type rofl.Engine
  local obj = {
    rofl = rofl,
    turnOn =
      peripheral.wrap("redstone_relay_2") --[[@as ccTweaked.peripheral.RedstoneRelay]],
    turnOff =
      peripheral.wrap("redstone_relay_3") --[[@as ccTweaked.peripheral.RedstoneRelay]],
    target =
      peripheral.wrap("create_target_0") --[[@as ccTweaked.peripheral.Target]],
    metrics = {
      rpm = 0,
      su = 0,
      fuel = 100,
    },
    _running = false,
    name = name,
    side = side,
    isKeyTurned = isKeyTurned,
    metricFuelLine = 1,
    metricSuLine = 2,
    metricRpmLine = 3
  }

  setmetatable(obj, Engine)

  obj.isKeyTurned = isKeyTurned

  return obj
end

function Engine:_update(...)
  if self.isKeyTurned() then
    self:start()
  else
    self:stop()
  end

  self:cacheMetrics()
end

function Engine:cacheMetrics()
  self:cacheMetricFuel()
  self:cacheMetricRpm()
  self:cacheMetricSu()
end

function Engine:cacheMetricRpm()
  local text = self.target.getLine(self.metricRpmLine):gsub(",", ""):gsub(" RPM",
    "")
  self.metrics.rpm = tonumber(text) or 0
end

function Engine:cacheMetricSu()
  local text = self.target.getLine(self.metricSuLine):gsub(",", ""):gsub("su", "")
  self.metrics.su = tonumber(text) or 0
end

function Engine:cacheMetricFuel()
  local text = self.target.getLine(self.metricFuelLine):gsub("%%", "")
  return tonumber(text)
end

function Engine:getMetrics()
  return self.metrics
end

function Engine:getRpm()
  return self.metrics.rpm
end

function Engine:getFuel()
  return self.metrics.fuel
end

function Engine:getSu()
  return self.metrics.su
end

function Engine:isRunning()
  return self._running
end

function Engine:start()
  self.turnOn.setOutput(self.side, self:getRpm() < Engine.KICKSTART_RPM)
  self.turnOff.setOutput(self.side, false)
  self._running = true
end

function Engine:stop()
  self.turnOn.setOutput(self.side, false)
  self.turnOff.setOutput(self.side, true)
  self._running = false
end

return Engine
