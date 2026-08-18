---@meta

---@class cctweaked.peripheral.TiltAdapter
TiltAdapter = {}

---@return number
function TiltAdapter.getLeftSignal() end

---@return number
function TiltAdapter.getRightSignal() end

---@param angle
function TiltAdapter.setTargetAngle(angle) end

---@class cctweaked.peripheral.RotationSpeedController
RotationSpeedController = {}

---@param speed number
function RotationSpeedController.setTargetSpeed(speed) end

---@return number
function RotationSpeedController.getTargetSpeed() end
