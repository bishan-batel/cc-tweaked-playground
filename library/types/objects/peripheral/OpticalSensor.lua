---@meta
---@class cctweaked.peripheral.OpticalSensor
OpticalSensor = {}


---@return string
function OpticalSensor.getBlock() end

---@return number
function OpticalSensor.getDistance() end

---@return number
function OpticalSensor.getRange() end

---@param range number
---@return boolean
function OpticalSensor.setRange(range) end

---@return boolean
function OpticalSensor.hasHit() end
