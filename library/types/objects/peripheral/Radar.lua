---@meta

---@class cctweaked.peripheral.Radar
Radar = {}

---@class cctweaked.peripheral.RadarTrack
---@field velocity ccTweaked.Vector
---@field position ccTweaked.Vector
---@field id string
---@field entityType string
---@field category string
---@field scannedTime integer

---@return [cctweaked.peripheral.RadarTrack]
function Radar:getTracks() end

---@return ccTweaked.Vector
function Radar:getPosition() end

---@return number
function Radar:getRotation() end

---@return number
function Radar:getRotationSpeed() end

---@return number
function Radar:getRange() end

---@return integer
function Radar:getDishCount() end
