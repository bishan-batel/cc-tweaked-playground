local url = "wss://unpadded-unclasp-steep.ngrok-free.dev"

settings.load("reload.settings")

local main_file = settings.get("main_file", "main.lua")

local function info(message)
  term.redirect(term.native())

  local fg, bg = term.getTextColor(), term.getBackgroundColor()

  term.setTextColor(colors.lightGray)
  term.setBackgroundColor(colors.black)
  term.write(message)
  term.write("\n")
  term.setTextColor(fg)
  term.setBackgroundColor(bg)
end

if #arg > 0 then
  main_file = arg[1] .. ".lua"
  settings.set("main_file", main_file)
  settings.save("reload.settings")
end


term.clear()


local ws, err = http.websocket(url)

if not ws then
  error("Connection failed: " .. tostring(err))
end

info("Connected")


while true do
  local message = ws.receive()
  if not message then
    error("Disconnected from server.")
    break
  end

  term.redirect(term.native())
  term.clear()

  local seperator = message:find("@")

  local fileName = message:sub(0, seperator - 1);
  local fileData = message:sub(seperator + 1);

  local file = fs.open(fileName, "w")

  info("Received file " .. fileName)

  if file == nil then
    info("\tFailed to open file " .. fileName)
  else
    file.write(fileData)
    file.close()
  end


  local function runYourCode()
    info("Executing " .. main_file)

    local success, err = pcall(function()
      shell.run(main_file)
    end)
    if not success then
      info("Code Error: " .. tostring(err))
    else
      info("Program finished running on its own.")
    end
  end

  local function waitForInterrupt()
    while true do
      local event, param1 = os.pullEvent()

      if event == "key" and param1 == keys.q then
        info("\nStopped")
        return
      end

      if event == "websocket_message" and param1 == url then
        info("\nReloading...")
        os.queueEvent("websocket_message", url, ws.receive())
        return
      end
    end
  end

  parallel.waitForAny(runYourCode, waitForInterrupt)
end
