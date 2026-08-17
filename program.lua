---@type ccTweaked.peripheral.Monitor
local monitor = peripheral.find("monitor")
---@type cctweaked.peripheral.Radar
local radar = peripheral.find("create_radar:radar_bearing")

---@param color ccTweaked.colors.color
local function clearBackground(color)
  local width, height = monitor.getSize();

  term.redirect(monitor)
  paintutils.drawBox(0, 0, width, height)
end


local function setup()
  clearBackground(colors.black)
end

local function update()
  clearBackground(colors.black)
  for i, track in ipairs(radar:getTracks()) do
    monitor.setCursorPos(1, i + 1)
    monitor.setBackgroundColour(colors.black)
    monitor.setTextColor(colors.white)
    monitor.write(track.entityType .. " - " .. tostring(track.position) .. "\n")
  end
end

setup()

while true do update() end
