local colorutils = {}

require("..mathutils")

---@param colors [ccTweaked.colors.color]
---@param t number
function colorutils.gradient(colors, t)
  local i = math.round(t * #colors) + 1

  return colors[math.clamp(i, 1, #colors)]
end

return colorutils
