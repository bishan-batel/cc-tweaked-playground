---@param x number
---@return number
function math.round(x)
  return math.floor(x + 0.5)
end

---@param x number
---@param place number
---@return number
function math.roundTo(x, place)
  place = math.pow(10, place)
  return math.round(x * place) / place
end

---@param x number
---@return number
function math.clamp(x, min, max)
  return math.min(math.max(x, min), max)
end

---@param value number
---@param errorValue number
function math.margin(value, errorValue)
  if math.abs(value) < math.abs(errorValue) then
    return 0
  else
    return value
  end
end

---@param value number
---@param errorValue number
function math.clampMargin(value, min, max, errorValue)
  return math.margin(math.clamp(value, min, max), errorValue)
end
