require("mathutils")
local gfx = require("gfx")


gfx.monitor = peripheral.find("monitor")
term.redirect(gfx.monitor)

local didTap = false

local WIDTH, HEIGHT = gfx.monitor.getSize()
local BIRD_VELOCITY = 10

local JUMP_STRENGTH = 15
local BIRD_SCREEN_X = 5

local GRAVITY = 9.8 * 5
local PIPE_WIDTH = 1
local PIPE_DISTANCE = 30

-- Assets
local birdImage = paintutils.parseImage([[
 4f4f
 4411
]])

local pipeImage = paintutils.parseImage([[
 555
 555
 555
 555
 555
 555
 555
 555
 555
 555
 555
55555







55555
 555
 555
 555
 555
 555
 555
 555
 555
 555
 555
 555
 555
]])


---@class flappy.Pipe
---@field x number
---@field y number
---@field scoreAdded boolean
Pipe = {}
Pipe.__index = Pipe

---@param x number
function Pipe:new(x)
  local instance = setmetatable({}, self)

  instance.x = x
  instance.scoreAdded = false
  instance:randomY()

  return instance
end

function Pipe:randomY()
  self.y = math.random() * 10
  self.y = 5 + math.random() * 10
end

---@param dt number
function Pipe:update(dt)
  self.x = self.x - dt * BIRD_VELOCITY
  if self.x < 0 then
    self.x = WIDTH
    self:randomY()
    self.scoreAdded = false
  end
end

function Pipe:render()
  if self.x > WIDTH + 3 then
    return
  end
  paintutils.drawImage(pipeImage, self.x - 2, self.y - 15)
end

---@param playerY number
function Pipe:isTouching(playerY)
  if math.abs(BIRD_SCREEN_X - self.x + 3) > PIPE_WIDTH + 2 then
    return false
  end


  if math.abs(playerY - (self.y)) > 4 then
    return true
  end

  return false
end

local function main()
  local lastTime = 0

  local y = 0
  local dy = 0
  local score = 0

  ---@type [flappy.Pipe]
  local pipes = {}

  local function reset()
    y = HEIGHT / 2
    dy = 0
    score = 0
    pipes = {}
    for i = 0, WIDTH, PIPE_DISTANCE do
      table.insert(pipes, Pipe:new(WIDTH + i))
    end
    lastTime = os.epoch("utc")
  end


  local function renderPlayer()
    local offx = -2
    local offy = math.clamp(dy * 0.5, -1.5, 1.0)

    paintutils.drawLine(
      1 + BIRD_SCREEN_X, y,
      1 + BIRD_SCREEN_X + offx, y + offy,
      colors.yellow
    )
    paintutils.drawLine(
      3 + BIRD_SCREEN_X, y,
      3 + BIRD_SCREEN_X - offx, y + offy,
      colors.yellow
    )
    paintutils.drawImage(birdImage, BIRD_SCREEN_X, y - 1)
  end

  reset()

  while true do
    local currentTime = os.epoch("utc")
    local dt = (currentTime - lastTime) / 1000.0
    lastTime = currentTime

    y = y + dy * dt
    dy = dy + GRAVITY * dt

    if y > HEIGHT then
      y = HEIGHT
      dy = 0
    end


    if didTap then
      dy = -JUMP_STRENGTH
      didTap = false
    end

    local shouldReset = false

    for _, pipe in ipairs(pipes) do
      pipe:update(dt)

      if pipe:isTouching(y) then
        shouldReset = true
      end

      if pipe.x < BIRD_SCREEN_X and not pipe.scoreAdded then
        pipe.scoreAdded = true
        score = score + 1
      end
    end

    gfx.clear(colors.lightBlue)

    renderPlayer()


    for _, pipe in ipairs(pipes) do
      pipe:render()
    end

    local scoreMessage = tostring(math.round(score))

    paintutils.drawFilledBox(1, 1, WIDTH, 1, colors.black)
    term.setCursorPos(WIDTH / 2 - #scoreMessage / 2, 1)
    term.setTextColor(colors.white)
    term.write(scoreMessage)

    if shouldReset then
      y = HEIGHT / 2
      local loseMessage = "YOU LOSE"

      local state = false
      for _ = 1, 10, 1 do
        -- gfx.clear(colors.red)
        term.setCursorPos(WIDTH / 2 - #loseMessage / 2, HEIGHT / 2)
        state = not state
        if state then
          term.setBackgroundColor(colors.black)
          term.setTextColor(colors.red)
        else
          term.setBackgroundColor(colors.red)
          term.setTextColor(colors.black)
        end
        term.write(loseMessage)
        os.sleep(0.2)
      end
      reset()
    end

    os.sleep(1.0 / 60)
  end
end

local function touchEvent()
  while true do
    local _, _, _, _ = os.pullEvent("monitor_touch")

    didTap = true
  end
end

parallel.waitForAny(main, touchEvent)
