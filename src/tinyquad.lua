require("mathutils")

print("Initial")

local SEA_LEVEL                 = 66.5
local MINIMUM_SPEED             = 107
local PITCH_CORRECT_MAX         = 15
local PITCH_CORRECT_SENSITIVITY = 1.0 / 7

local ROLL_CORRECT_MAX          = 5
local ROLL_CORRECT_SENSITIVITY  = 1.0 / 5


local THROTTLE_ANGLE = 10
local THROTTLE_POWER = 10
local STEER_ANGLE    = 2

local typewriter     = peripheral.find("linked_typewriter") --[[@as cctweaked.peripheral.Typewriter]]

---@return { number : boolean }
local function getPressedKeys()
  local codes = {}
  for _, code in ipairs(typewriter.getPressedKeyCodes()) do
    codes[code] = true
  end
  return codes
end

--[[
-- Create_RotationSpeedController_0
-- tilt_adapter_0
--]]


local sensors = {
  velocity = peripheral.wrap("left") --[[@as cctweaked.peripheral.VelocitySensor]],
  gimbal = peripheral.wrap("top") --[[@as cctweaked.peripheral.GimbalSensor]],
  altitude = peripheral.wrap("right") --[[@as cctweaked.peripheral.AltitudeSensor]]
}


local tiltAdapters = {
  --back left
  peripheral.wrap("tilt_adapter_0"),

  peripheral.wrap("tilt_adapter_1"),
  peripheral.wrap("tilt_adapter_2"),
  peripheral.wrap("tilt_adapter_3"),
}
---@cast tiltAdapters [cctweaked.peripheral.TiltAdapter]

local speedControllers = {
  peripheral.wrap("Create_RotationSpeedController_0"),
  peripheral.wrap("Create_RotationSpeedController_1"),
  peripheral.wrap("Create_RotationSpeedController_2"),
  peripheral.wrap("Create_RotationSpeedController_3"),
}
---@cast speedControllers [cctweaked.peripheral.RotationSpeedController]


local scroller = peripheral.wrap("scroller_0") --[[@as cctweaked.peripheral.Scroller]]

local tiltAdapter = {
  back = {
    ---@type cctweaked.peripheral.TiltAdapter
    left = tiltAdapters[1],
    ---@type cctweaked.peripheral.TiltAdapter
    right = tiltAdapters[2]
  },
  front = {
    ---@type cctweaked.peripheral.TiltAdapter
    left = tiltAdapters[4],
    ---@type cctweaked.peripheral.TiltAdapter
    right = tiltAdapters[3]
  }
}

local speedController = {
  back = {
    ---@type cctweaked.peripheral.RotationSpeedController
    left = speedControllers[3],
    ---@type cctweaked.peripheral.RotationSpeedController
    right = speedControllers[4],
  },
  front = {
    ---@type cctweaked.peripheral.RotationSpeedController
    left = speedControllers[1],
    ---@type cctweaked.peripheral.RotationSpeedController
    right = speedControllers[2]
  }
}


while true do
  local angles = sensors.gimbal:getAngles()

  local pitch = angles[1]
  local roll = angles[2]


  for _, adapter in ipairs(tiltAdapters) do
  end

  local baseSpeed = 0.0

  baseSpeed = MINIMUM_SPEED


  local airPressure = sensors.altitude:getAirPressure()
  baseSpeed         = baseSpeed

  local backLeft    = 0
  local backRight   = 0
  local frontLeft   = 0
  local frontRight  = 0

  local tilt        = {
    backLeft = 0,
    backRight = 0,
    frontLeft = 0,
    frontRight = 0,
  }


  local pitchSpeedOffset = -math.clampMargin(
    math.margin(pitch - 16, 0) * PITCH_CORRECT_SENSITIVITY,
    -PITCH_CORRECT_MAX,
    PITCH_CORRECT_MAX, 2)

  local rollSpeedOffset  = -math.clampMargin(
    math.margin(roll, 0) * ROLL_CORRECT_SENSITIVITY,
    -ROLL_CORRECT_MAX,
    ROLL_CORRECT_MAX, 0)


  backLeft          = backLeft + pitchSpeedOffset - rollSpeedOffset
  backRight         = backRight + pitchSpeedOffset + rollSpeedOffset
  frontLeft         = frontLeft - pitchSpeedOffset - rollSpeedOffset
  frontRight        = frontRight - pitchSpeedOffset + rollSpeedOffset

  local pressedKeys = getPressedKeys()

  if pressedKeys[keys.space] then
    baseSpeed = baseSpeed + 50
  end
  if pressedKeys[keys.leftShift] then
    baseSpeed = baseSpeed - 40
  end

  if pressedKeys[keys.w] then
    tilt.backLeft = -THROTTLE_ANGLE + tilt.backLeft
    tilt.backRight = -THROTTLE_ANGLE + tilt.backRight
    tilt.frontLeft = -THROTTLE_ANGLE + tilt.frontLeft
    tilt.frontRight = -THROTTLE_ANGLE + tilt.frontRight

    backLeft = THROTTLE_POWER + backLeft
    backRight = THROTTLE_POWER + backRight
    frontLeft = THROTTLE_POWER + frontLeft
    frontRight = THROTTLE_POWER + frontRight
  end

  if pressedKeys[keys.s] then
    tilt.backLeft = THROTTLE_ANGLE + tilt.backLeft
    tilt.backRight = THROTTLE_ANGLE + tilt.backRight
    tilt.frontLeft = THROTTLE_ANGLE + tilt.frontLeft
    tilt.frontRight = THROTTLE_ANGLE + tilt.frontRight

    backLeft = THROTTLE_POWER + backLeft
    backRight = THROTTLE_POWER + backRight
    frontLeft = THROTTLE_POWER + frontLeft
    frontRight = THROTTLE_POWER + frontRight
  end

  if pressedKeys[keys.d] then
    tilt.backLeft = -STEER_ANGLE + tilt.backLeft
    tilt.backRight = STEER_ANGLE + tilt.backRight
    tilt.frontLeft = -STEER_ANGLE + tilt.frontLeft
    tilt.frontRight = STEER_ANGLE + tilt.frontRight

    -- backLeft = STEER_POWER + backLeft
    -- backRight = STEER_POWER + backRight
    -- frontLeft = STEER_POWER + frontLeft
    -- frontRight = STEER_POWER + frontRight
  end

  if pressedKeys[keys.a] then
    tilt.backLeft = STEER_ANGLE + tilt.backLeft
    tilt.backRight = -STEER_ANGLE + tilt.backRight
    tilt.frontLeft = STEER_ANGLE + tilt.frontLeft
    tilt.frontRight = -STEER_ANGLE + tilt.frontRight

    -- backLeft = STEER_POWER + backLeft
    -- backRight = STEER_POWER + backRight
    -- frontLeft = STEER_POWER + frontLeft
    -- frontRight = STEER_POWER + frontRight
  end


  backLeft   = math.min(baseSpeed, backLeft)
  backRight  = math.min(baseSpeed, backRight)
  frontLeft  = math.min(baseSpeed, frontLeft)
  frontRight = math.min(baseSpeed, frontRight)


  speedController.back.left.setTargetSpeed((baseSpeed + backLeft) / airPressure);
  speedController.back.right.setTargetSpeed((baseSpeed + backRight) / airPressure);
  speedController.front.left.setTargetSpeed((baseSpeed + frontLeft) / airPressure);
  speedController.front.right.setTargetSpeed((baseSpeed + frontRight) /
    airPressure);

  tiltAdapter.back.left.setTargetAngle(pitch + tilt.backLeft)
  tiltAdapter.back.right.setTargetAngle(pitch + tilt.backRight)
  tiltAdapter.front.left.setTargetAngle(pitch + tilt.frontLeft)
  tiltAdapter.front.right.setTargetAngle(pitch + tilt.frontRight)

  term.redirect(peripheral.find("monitor"))
  term.clear()
  term.setCursorPos(1, 1)

  term.setTextColor(colors.lightBlue)
  write("VEL=" .. math.roundTo(sensors.velocity:getVelocity(), 2) .. " ")
  write("ALT=" ..
    math.roundTo(sensors.altitude:getHeight() - SEA_LEVEL, 2) .. " ")
  write("AIR=" .. math.roundTo(airPressure, 2))
  write("\n")

  term.setTextColor(colors.lightGray)
  write("PITCH=" .. math.round(pitch) .. " ")
  write("ROLL=" .. math.round(roll))
  write("\n")


  term.setTextColor(colors.blue)

  scroller.setLimit(60)
  local scrollerValue = scroller.getValue() + SEA_LEVEL
  print("TargetY=", scrollerValue)

  term.setTextColor(colors.lightGray)
  write("BASE=")
  term.setTextColor(colors.red)
  write(tostring(math.roundTo(baseSpeed, 2)))
  write("\n\n")


  term.setTextColor(colors.lightGray)
  write("FL=")
  term.setTextColor(colors.red)
  write(tostring(math.roundTo(frontLeft, 3)))

  term.setTextColor(colors.lightGray)
  write(" FR=")
  term.setTextColor(colors.red)
  write(tostring(math.roundTo(frontRight, 3)))

  write("\n")

  term.setTextColor(colors.lightGray)
  write("BL=")
  term.setTextColor(colors.red)
  write(tostring(math.roundTo(backLeft, 3)))

  term.setTextColor(colors.lightGray)
  write(" BR=")
  term.setTextColor(colors.red)
  write(tostring(math.roundTo(backRight, 3)))


  term.setTextColor(colors.white)
  write("\nPITCHCOR=" .. tostring(math.roundTo(pitchSpeedOffset, 2)))
  write("\nROLLCOR=" .. tostring(math.roundTo(rollSpeedOffset, 2)))
  sleep(1.0 / 20)
end
