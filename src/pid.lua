local pid = {
  EPSILON = 0.01
}

---@class pid.Number
---@field config pid.Config
---@field lastCorrection number
---@field private integral number
---@field private lastError number
---@field filteredDerivative number Smoothed derivative value
pid.Number = {}
pid.Number.__index = pid.Number

---@class pid.Config
---@field proportion number Proportion Force
---@field integral number Integral Force
---@field derivative number Derivative Force
---@field integralMax? number Maximum of the integral to prevent 'windup'
---@field filterTime? number Optional derivative filter time coeff
---@field scale number? Correction Scale
---@field bounds number | { min: number?, max: number? } | nil Bounds for the output

--- Creates a new numeric PID controller
--- @param config pid.Config
--- @return pid.Number
function pid.Number.new(config)
  local self = setmetatable({}, pid.Number)
  self.config = config
  self.lastCorrection = 0
  self:reset()
  return self
end

--- resets internal state
function pid.Number:reset()
  self.integral = 0
  self.lastError = 0
  self.filteredDerivative = 0
end

--- Computes the next control signal using numbers
--- @param error number Current error (target - current_value)
--- @param dt number Delta time since last update
--- @return number controlOutput
function pid.Number:update(error, dt)
  dt = math.max(dt, pid.EPSILON) -- Prevent division by zero

  local kd = self.config.derivative
  local ki = self.config.integral
  local kp = self.config.proportion
  local filterTime = self.config.filterTime

  -- accumulate error integral
  self.integral = self.integral + (error * dt)

  -- clamp if provided integral max
  local integralMax = self.config.integralMax
  if integralMax then
    self.integral = math.max(-integralMax, math.min(integralMax, self.integral))
  end

  -- calculate derivative
  local rawDerivative = (error - self.lastError) / dt
  self.lastError = error

  if filterTime and filterTime > 0 then
    local alpha = dt / (filterTime + dt)

    self.filteredDerivative =
      self.filteredDerivative + alpha * (rawDerivative - self.filteredDerivative)
  else
    -- bypass filter if not configured
    self.filteredDerivative = rawDerivative
  end

  -- combine error terms

  local derivative = self.filteredDerivative

  local termP = error * kp
  local termI = self.integral * ki
  local termD = derivative * kd

  local correction = termP + termI + termD

  if self.config.scale then
    self.lastCorrection = self.lastCorrection * self.config.scale
  end

  local bounds = self.config.bounds

  if bounds then
    if type(bounds) == "number" then
      correction = math.min(bounds, math.max(bounds, correction))
    else
      local min = bounds.min
      local max = bounds.max

      if min then
        correction = math.max(min, correction)
      end

      if max then
        correction = math.min(max, correction)
      end
    end
  end

  self.lastCorrection = correction

  return correction
end

---@module "pid"
return pid
