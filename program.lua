---@type ccTweaked.peripheral.Monitor
local monitor = peripheral.find("monitor")

---@type any
local radar = peripheral.find("create_radar:radar_bearing")

monitor.clear()

local width, height = monitor.getSize()


---@param color ccTweaked.colors.color
local function clearBackground(color)
  monitor.setBackgroundColour(color)
  monitor.setTextColor(color)

  for y = 1, height, 1 do
    for x = 1, width, 1 do
      monitor.setCursorPos(x, y)
      monitor.write(" ")
    end
  end
end


local function osLoop()
  clearBackground(colors.black)

  ---@type [RadarTrack]
  local tracks = radar.getTracks()


  print(tracks)

  monitor.setCursorPos(1, 1)

  for _, track in ipairs(tracks) do
    monitor.setBackgroundColour(colors.black)
    monitor.setTextColor(colors.white)
    monitor.write(track.entityType .. " - " .. tostring(track.position) .. "\n")
  end
end

while true do
  osLoop()
end
