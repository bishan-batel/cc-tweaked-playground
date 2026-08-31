---@class Matrix
---@field rows integer
---@field cols integer
---@field data number[][]
---@operator add(Matrix): Matrix
---@operator sub(Matrix): Matrix
---@operator mul(number): Matrix
---@operator mul(Matrix): Matrix
---@operator unm(): Matrix
---@operator div(number): Matrix
local Matrix = {}
Matrix.__index = Matrix

local EPSILON = 1E-9

--- Creates a matrix initialized with all zeros
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

---@param dim integer
---@return Matrix
function Matrix.identity(dim)
  local self = Matrix.new(dim, dim)

  for i = 1, dim do
    self.data[i][i] = 1
  end

  return self
end

--- Creates a matrix from a 2D table
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
  assert(
    self.rows == other.rows and self.cols == other.cols,
    "Dimension mismatch for matrix addition."
  )
  local result = Matrix.new(self.rows, self.cols)
  for i = 1, self.rows do
    for j = 1, self.cols do
      result.data[i][j] = self.data[i][j] + other.data[i][j]
    end
  end
  return result
end

--- Subtracts two matrices of the same dimensions together.
---@param other Matrix
---@return Matrix
function Matrix:sub(other)
  assert(
    self.rows == other.rows and self.cols == other.cols,
    "Dimension mismatch for matrix subtraction."
  )

  local result = Matrix.new(self.rows, self.cols)

  for i = 1, self.rows do
    for j = 1, self.cols do
      result.data[i][j] = self.data[i][j] - other.data[i][j]
    end
  end

  return result
end

--- Multiplies the matrix by either a scalar or another matrix.
---@overload fun(self, val: number): Matrix
---@overload fun(self, val: Matrix): Matrix
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
      "Dimension mismatch: Matrix A cols must match Matrix B rows. "
        .. self.rows
        .. ", "
        .. self.cols
        .. " * "
        .. val.rows
        .. ","
        .. val.cols
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

---Multiplies the matrix by 1/scalar
---@param scalar number
function Matrix:divide(scalar)
  scalar = 1.0 / scalar

  local result = Matrix.new(self.rows, self.cols)

  for i = 1, self.rows do
    for j = 1, self.cols do
      result.data[i][j] = self.data[i][j] * scalar
    end
  end

  return result
end

--- Returns the negative of this matrix
---@return Matrix
function Matrix:negate()
  return self:multiply(-1)
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

--- Creates a new sub-matrix by removing a specific row and column
---@param excludeRow integer
---@param excludeCol integer
---@return Matrix
function Matrix:subMatrix(excludeRow, excludeCol)
  local result = Matrix.new(self.rows - 1, self.cols - 1)
  local r = 1
  for i = 1, self.rows do
    if i ~= excludeRow then
      local c = 1
      for j = 1, self.cols do
        if j ~= excludeCol then
          result.data[r][c] = self.data[i][j]
          c = c + 1
        end
      end
      r = r + 1
    end
  end
  return result
end

--- Calculates the determinant of a square matrix recursively
---@return number
function Matrix:determinant()
  assert(
    self.rows == self.cols,
    "Determinant can only be calculated for square matrices"
  )

  local n = self.rows

  if n == 1 then
    return self.data[1][1]
  end

  if n == 2 then
    local d = self.data
    return d[1][1] * d[2][2] - d[1][2] * d[2][1]
  end

  local det = 0
  for j = 1, n do
    local sign = (j % 2 == 1) and 1 or -1
    local sub = self:subMatrix(1, j)
    det = det + sign * self.data[1][j] * sub:determinant()
  end
  return det
end

--- Computes the cofactor matrix of a *square* matrix
---@return Matrix
function Matrix:cofactor()
  assert(
    self.rows == self.cols,
    "Cofactor matrix can only be calculated for square matrices."
  )

  local n = self.rows
  local result = Matrix.new(n, n)

  if n == 1 then
    result.data[1][1] = 1
    return result
  end

  for i = 1, n do
    for j = 1, n do
      local sub = self:subMatrix(i, j)
      local sign = ((i + j) % 2 == 0) and 1 or -1
      result.data[i][j] = sign * sub:determinant()
    end
  end
  return result
end

--- Computes the inverse of a square matrix using the Adjugate/Cofactor method.
--- Returns nil if the matrix is singular (determinant is zero).
---@return Matrix?, string?
function Matrix:inverse()
  assert(self.rows == self.cols, "Only square matrices can be inverted.")

  local det = self:determinant()

  if math.abs(det) < EPSILON then
    return nil, "Singular" -- Matrix is singular and cannot be inverted
  end

  -- For a 1x1 matrix, the inverse is just 1 / element
  if self.rows == 1 then
    local result = Matrix.new(1, 1)
    result.data[1][1] = 1 / self.data[1][1]
    return result
  end

  local matCofactor = self:cofactor()
  local matAdjugate = matCofactor:transpose()

  return matAdjugate:multiply(1 / det)
end

---@param vector Vector
function Matrix.fromVector(vector)
  return Matrix.fromTable({
    { vector.x },
    { vector.y },
    { vector.z },
  })
end

--- Converts this matrix to a Vector, this only works if the matrix is 3x1 / a 3
--- dim column vector
---@return Vector
function Matrix:toVector()
  assert(
    self.rows == 3 and self.cols == 1,
    "toVector only works for 3x1 matrices"
  )

  return vector.new(self.data[1][1], self.data[2][1], self.data[3][1])
end

--- Creates a 3x3 rotation matrix from Euler angles (Roll, Pitch, Yaw)
--- Yaw * Pitch * Roll
---@param angles EulerAngles
---@return Matrix
function Matrix.fromEuler(angles)
  local pitch = angles.pitch
  local yaw = angles.yaw
  local roll = angles.roll

  local cosRoll, sinRoll = math.cos(roll), math.sin(roll)
  local cosPitch, sinPitch = math.cos(pitch), math.sin(pitch)
  local cosYaw, sinYaw = math.cos(yaw), math.sin(yaw)

  local data = {
    {
      cosYaw * cosRoll + sinYaw * sinPitch * sinRoll,
      sinYaw * sinPitch * cosRoll - cosYaw * sinRoll,
      sinYaw * cosPitch,
    },
    {
      cosPitch * sinRoll,
      cosPitch * cosRoll,
      -sinPitch,
    },
    {
      cosYaw * sinPitch * sinRoll - sinYaw * cosRoll,
      sinYaw * sinRoll + cosYaw * sinPitch * cosRoll,
      cosYaw * cosPitch,
    },
  }

  return Matrix.fromTable(data)
end

Matrix.__add = Matrix.add
Matrix.__sub = Matrix.sub
Matrix.__mul = Matrix.multiply
Matrix.__div = Matrix.divide
Matrix.__unm = Matrix.negate

return Matrix
