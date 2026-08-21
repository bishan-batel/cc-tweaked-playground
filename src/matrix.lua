---@class Matrix
---@field rows integer The number of rows in the matrix.
---@field cols integer The number of columns in the matrix.
---@field data number[][] The raw 2D array containing the matrix numbers.
local Matrix = {}
Matrix.__index = Matrix

--- Creates a new Matrix instance initialized with zeros.
---@param rows integer
---@param cols integer
---@return Matrix
function Matrix.new(rows, cols)
  local self = setmetatable({}, Matrix)
  self.rows = rows
  self.cols = cols
  self.data = {}

  for i = 1, rows do
    self.data[i] = {}
    for j = 1, cols do
      self.data[i][j] = 0
    end
  end
  return self
end

--- Creates a matrix from a raw 2D table.
---@param t number[][]
---@return Matrix
function Matrix.fromTable(t)
  local rows = #t
  local cols = #t[1]
  local m = Matrix.new(rows, cols)
  for i = 1, rows do
    for j = 1, cols do
      m.data[i][j] = t[i][j]
    end
  end
  return m
end

--- Adds two matrices of the same dimensions together.
---@param other Matrix
---@return Matrix
function Matrix:add(other)
  assert(self.rows == other.rows and self.cols == other.cols,
    "Dimension mismatch for matrix addition.")
  local result = Matrix.new(self.rows, self.cols)
  for i = 1, self.rows do
    for j = 1, self.cols do
      result.data[i][j] = self.data[i][j] + other.data[i][j]
    end
  end
  return result
end

--- Multiplies the matrix by either a scalar or another matrix.
---@param val Matrix|number
---@return Matrix
function Matrix:multiply(val)
  if type(val) == "number" then
    -- Scalar Multiplication
    local result = Matrix.new(self.rows, self.cols)
    for i = 1, self.rows do
      for j = 1, self.cols do
        result.data[i][j] = self.data[i][j] * val
      end
    end
    return result
  else
    -- Matrix Multiplication
    assert(
      self.cols == val.rows,
      "Dimension mismatch: Matrix A cols must match Matrix B rows."
    )
    local result = Matrix.new(self.rows, val.cols)
    for i = 1, self.rows do
      for j = 1, val.cols do
        local sum = 0
        for k = 1, self.cols do
          sum = sum + (self.data[i][k] * val.data[k][j])
        end
        result.data[i][j] = sum
      end
    end
    return result
  end
end

--- Transposes the matrix (swaps rows and columns).
---@return Matrix
function Matrix:transpose()
  local result = Matrix.new(self.cols, self.rows)
  for i = 1, self.rows do
    for j = 1, self.cols do
      result.data[j][i] = self.data[i][j]
    end
  end
  return result
end

--- Outputs the matrix beautifully to the ComputerCraft terminal or monitor.
function Matrix:print()
  for i = 1, self.rows do
    local rowStr = "[ "
    for j = 1, self.cols do
      rowStr = rowStr .. string.format("%g", self.data[i][j]) .. " "
    end
    print(rowStr .. "]")
  end
end

return Matrix
