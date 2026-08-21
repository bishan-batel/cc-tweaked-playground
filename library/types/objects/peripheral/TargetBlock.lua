---@meta
---@class ccTweaked.peripheral.Target
Target = {}

---@return [string]
function Target.dump() end

---@return integer, integer
function Target.getSize() end

---@param w integer
---@param h integer
function Target.resize(w, h) end

---@param n integer
---@return string
function Target.getLine(n) end
