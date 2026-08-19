---@module gfx
local gfx = {}

---@type ccTweaked.term.Redirect
gfx.monitor = term.native()

---@param color ccTweaked.colors.color|nil
function gfx.clear(color)
  local width, height = gfx.monitor.getSize()
  paintutils.drawFilledBox(1, 1, width, height, color or colors.black)
end

return gfx
