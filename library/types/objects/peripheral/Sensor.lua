---@meta

---@class cctweaked.peripheral.GimbalSensor
Gimbal = {}

---@return [number, number]
function Gimbal:getAngles() end

---@return [number, number]
function Gimbal:getAnglesRad() end

---@class cctweaked.peripheral.VelocitySensor
Velocity = {}

---@return number
function Velocity:getVelocity() end

---@class cctweaked.peripheral.AltitudeSensor
Altitude = {}

---@return number
function Altitude:getAirPressure() end

---@return number
function Altitude:getHeight() end
