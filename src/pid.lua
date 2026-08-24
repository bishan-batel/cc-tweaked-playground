local pid = {
  EPSILON = 0.01
}

---@class pid.Number
---@field config pid.Config
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

--- Creates a new numeric PID controller
--- @param config pid.Config
--- @return pid.Number
function pid.Number.new(config)
  local self = setmetatable({}, pid.Number)
  self.config = config
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
  dt = math.max(dt, 0.01) -- Prevent division by zero

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

    self.filteredDerivative = self.filteredDerivative +
      alpha * (rawDerivative - self.filteredDerivative)
  else
    -- bypass filter if not configured
    self.filteredDerivative = rawDerivative
  end

  -- combine error terms
  return (error * kp) + (self.integral * ki) + (rawDerivative * kd)
end

---@module "pid"
return pid
