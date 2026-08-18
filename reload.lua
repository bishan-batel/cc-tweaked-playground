local url = "wss://unpadded-unclasp-steep.ngrok-free.dev"

settings.load("reload.settings")

local main_file = settings.get("main_file", "main.lua")

if #arg > 0 then
  main_file = arg[1] .. ".lua"
  settings.set("main_file", main_file)
  settings.save("reload.settings")
end




local ws, err = http.websocket(url)

if not ws then
  error("Connection failed: " .. tostring(err))
end

print("Connected")

while true do
  local message = ws.receive()
  if not message then
    error("Disconnected from server.")
    break
  end

  local seperator = message:find("@")

  local fileName = message:sub(0, seperator - 1);
  local fileData = message:sub(seperator + 1);

  local file = fs.open(fileName, "w")

  print("Received file ", fileName)

  if file == nil then
    print("\tFailed to open file", fileName)
  else
    file.write(fileData)
    file.close()
  end


  local function runYourCode()
    print("Executing", main_file)

    local success, err = pcall(function()
      shell.run(main_file)
    end)
    if not success then
      print("\nCode Error: " .. tostring(err))
    else
      print("\nProgram finished running on its own.")
    end
  end

  local function waitForInterrupt()
    while true do
      local event, param1 = os.pullEvent()

      if event == "key" and param1 == keys.q then
        print("\nStopped")
        return
      end

      if event == "websocket_message" and param1 == url then
        print("\nReloading...")
        os.queueEvent("websocket_message", url, ws.receive())
        return
      end
    end
  end

  parallel.waitForAny(runYourCode, waitForInterrupt)
end
