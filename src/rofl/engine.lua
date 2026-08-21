---@class rofl.Engine
---@field rofl rofl.Roflcopter
---@field private _target ccTweaked.peripheral.Target
---@field private _turnOn ccTweaked.peripheral.RedstoneRelay
---@field private _turnOff ccTweaked.peripheral.RedstoneRelay
---@field private _metrics rofl.Engine.Metrics
---@field private _running boolean
local Engine = {
  --- Minimum RPM required before turning off the kickstart battery
  KICKSTART_RPM = 64
}

---@class rofl.Engine.Metrics
---@field rpm  number
---@field su number
---@field fuel number

Engine.__index = Engine

---@param rofl rofl.Roflcopter
function Engine.new(rofl)
  ---@type rofl.Engine
  local obj = {
    rofl = rofl,
    _turnOn =
      peripheral.wrap("redstone_relay_2") --[[@as ccTweaked.peripheral.RedstoneRelay]],
    _turnOff =
      peripheral.wrap("redstone_relay_3") --[[@as ccTweaked.peripheral.RedstoneRelay]],
    _target =
      peripheral.wrap("create_target_0") --[[@as ccTweaked.peripheral.Target]],
    _metrics = {
      rpm = 0,
      su = 0,
      fuel = 100,
    },
    _running = false
  }

  setmetatable(obj, Engine)

  return obj
end

---@param dt number
function Engine:_update(dt)
  if self:isKeyTurned() then
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
  local text = self._target.getLine(3):gsub(",", ""):gsub(" RPM", "")
  self._metrics.rpm = tonumber(text) or 0
end

function Engine:cacheMetricSu()
  local text = self._target.getLine(2):gsub(",", ""):gsub("su", "")
  self._metrics.su = tonumber(text) or 0
end

function Engine:cacheMetricFuel()
  local text = self._target.getLine(1):gsub("%%", "")
  return tonumber(text)
end

function Engine:getMetrics()
  return self._metrics
end

function Engine:getRpm()
  return self._metrics.rpm
end

function Engine:getFuel()
  return self._metrics.fuel
end

function Engine:getSu()
  return self._metrics.su
end

function Engine:isKeyTurned()
  return redstone.getInput("front")
end

function Engine:isRunning()
  return self._running
end

function Engine:start()
  self._turnOn.setOutput("back", self:getRpm() < Engine.KICKSTART_RPM)
  self._turnOff.setOutput("back", false)
  self._running = true
end

function Engine:stop()
  self._turnOn.setOutput("back", false)
  self._turnOff.setOutput("back", true)
  self._running = false
end

return Engine
