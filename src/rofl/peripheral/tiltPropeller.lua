local Propeller = require("peripheral.propeller")

---@class rofl.TiltPropeller: rofl.Propeller
---@field private tiltAdapter cctweaked.peripheral.TiltAdapter|nil
---@field baseTilt number Base tilt / pitch of the propellar
---@field deltaTilt rofl.Propeller.Offsets Offset tilt from base
---@field lastSentTilt number
local TiltPropeller = {}
TiltPropeller.__index = TiltPropeller

---@param name string
---@param speedControl cctweaked.peripheral.RotationSpeedController|string
---@param tiltAdapter cctweaked.peripheral.TiltAdapter|string
---@param relativePosition Vector
---@param direction Vector?
---@param inverse boolean?
function TiltPropeller.new(
  name,
  speedControl,
  tiltAdapter,
  relativePosition,
  direction,
  inverse
)
  self = Propeller.new(
    name,
    speedControl,
    relativePosition,
    direction,
    inverse
  )

  self = setmetatable(self, TiltPropeller)

  if type(tiltAdapter) == "string" then
    tiltAdapter = peripheral.wrap(tiltAdapter) --[[@as cctweaked.peripheral.TiltAdapter]]
  end

  assert(tiltAdapter, "Tilt Adapter must not be nil for Propeller" .. name)

  self.baseTilt = 0
  self.deltaTilt = 0
  self.lastSentTilt = 0
end

---@param baseTilt number?
function TiltPropeller:resetTilt(baseTilt)
  self.deltaTilt = {}
  self.baseTilt = baseTilt or self.baseTilt
end

---@param name string
---@param delta number
function TiltPropeller:addTilt(name, delta)
  self.deltaTilt[name] = delta
end

--- Gets the total tilt sent to the controller
---@return number
function TiltPropeller:calculateTilt()
  if not self.enabled then
    return 0
  end

  local tilt = self.baseTilt

  for _, delta in pairs(self.deltaTilt) do
    tilt = tilt + delta
  end

  if self.inverse then return tilt end
  return tilt
end

function TiltPropeller:sendAll()
  parallel.waitForAll(
    function() self:sendTilt() end,
    function() Propeller.sendAll(self) end
  )
end

--- Sends the Tilt into the controller, note that this is considerably laggy
function TiltPropeller:sendTilt()
  if not self.tiltAdapter then return end
  local tilt = self:calculateTilt()
  self.tiltAdapter.setTargetAngle(tilt)
  self.lastSentTilt = tilt
end

---@param yaw number The yaw of the ship in degrees
---@param roll number The roll of the ship in degrees
---@param pitch number The pitch of the ship
function TiltPropeller:calculateDir(yaw, roll, pitch)
  return self:calculateDir(yaw, roll, pitch + (self.lastSentTilt or 0))
end

return TiltPropeller
