---@meta

---@class cctweaked.peripheral.Scroller
Scroller = {}

---@return number
function Scroller.getLimit() end

---@return number
function Scroller.getValue() end

---@return boolean
function Scroller.hasMinusSpectrum() end

---@return boolean
function Scroller.isLocked() end

function Scroller.toggleMinusSpectrum() end

---@param limit number
function Scroller.setLimit(limit) end

---@param value number
function Scroller.setValue(value) end

---@param lock boolean
function Scroller.setLock(lock) end
