---@meta
---@class ccTweaked.peripheral.RedstoneRelay
RedstoneRelay = {}


---@param side ccTweaked.peripheral.computerSide
---@param state boolean
function RedstoneRelay.setOutput(side, state)
end

---@param side ccTweaked.peripheral.computerSide
---@return boolean
function RedstoneRelay.getOutput(side)
end

---@param side ccTweaked.peripheral.computerSide
---@return boolean
function RedstoneRelay.getInput(side)
end

---@param side ccTweaked.peripheral.computerSide
---@param output number
function RedstoneRelay.setAnalogOutput(side, output)
end

---@param side ccTweaked.peripheral.computerSide
---@return number
function RedstoneRelay.getAnalogOutput(side)
end

---@param side ccTweaked.peripheral.computerSide
---@return number
function RedstoneRelay.getAnalogInput(side)
end
