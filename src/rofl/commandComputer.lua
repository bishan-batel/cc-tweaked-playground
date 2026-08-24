print("Command Computer")

local modem = peripheral.find "modem" --[[@as ccTweaked.peripheral.Modem]]

local CHANNEL = 6969
local REPLY_CHANNEL = CHANNEL + 1

while true do
  local x, y, z = commands.getBlockPosition()
  local position = vector.new(x, y, z)
  modem.transmit(CHANNEL, REPLY_CHANNEL, position)
  print("Transmitted ", position)
  sleep(1.0)
end
