local url = "wss://unpadded-unclasp-steep.ngrok-free.dev" -- Your ngrok URL here
local targetFile = "program.lua"


print("Connecting to local sync server...")
local ws, err = http.websocket(url)

if not ws then
  error("Connection failed: " .. tostring(err))
end

print("Connected! Waiting for code updates...")
print("Press 'q' during execution to cancel.")

-- This function runs your downloaded file inside a coroutine
local function runTargetFile()
  shell.run(targetFile)
end


while true do
  -- 1. Always wait for the very first file to arrive before starting
  local message = ws.receive()
  if not message then
    print("Disconnected from server.")
    break
  end

  -- 2. Save the code to your file
  local file = fs.open(targetFile, "w")
  file.write(message)
  file.close()

  print("\nCode Loaded! Starting execution...")

  -- 3. Define the two tasks we want to run at the same time

  -- Task A: Run your actual downloaded program
  local function runYourCode()
    local success, err = pcall(function()
      shell.run(targetFile)
    end)
    if not success then
      print("\nCode Error: " .. tostring(err))
    else
      print("\nProgram finished running on its own.")
    end
  end

  -- Task B: Wait in the background for a cancel key OR a network update
  local function waitForInterrupt()
    while true do
      local event, param1 = os.pullEvent()

      -- Check if user pressed 'q'
      if event == "key" and param1 == keys.q then
        print("\nStopped: You pressed 'q'")
        return -- This exits the function and stops parallel
      end

      -- Check if a network message came from ngrok
      if event == "websocket_message" and param1 == url then
        print("\nReloading: New save received from IDE!")
        -- Put the message back into the queue so the main loop can read it next
        os.queueEvent("websocket_message", url, ws.receive())
        return -- This exits the function and stops parallel
      end
    end
  end

  -- 4. Run both at once. If either finishes, the other is instantly killed!
  parallel.waitForAny(runYourCode, waitForInterrupt)

  print("---------------------------------------")
  print("Waiting for next trigger...")
end
