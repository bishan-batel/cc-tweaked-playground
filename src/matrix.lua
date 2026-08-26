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
      "Dimension mismatch: Matrix A cols must match Matrix B rows. " ..
      self.rows .. ", " .. self.cols .. " * " .. val.rows .. "," .. val.cols
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

--- Computes the inverse of a 3x3 matrix specifically using Cramer's Rule.
--- Returns nil if the matrix is not 3x3 or is singular (determinant close to zero).
---@return Matrix|nil
function Matrix:inverse3x3()
  assert(self.rows == 3 and self.cols == 3,
    "This function only works for 3x3 Matrices")

  local d = self.data
  local m11, m12, m13 = d[1][1], d[1][2], d[1][3]
  local m21, m22, m23 = d[2][1], d[2][2], d[2][3]
  local m31, m32, m33 = d[3][1], d[3][2], d[3][3]

  -- harcode determinant
  local det = m11 * (m22 * m33 - m23 * m32)
    - m12 * (m21 * m33 - m23 * m31)
    + m13 * (m21 * m32 - m22 * m31)

  -- if determinant is basically zero then bail
  if math.abs(det) < 1e-6 then
    return nil
  end

  local invDet = 1 / det

  local result = Matrix.new(3, 3)

  local rd = result.data

  -- Row 1 elements
  rd[1][1] = (m22 * m33 - m23 * m32) * invDet
  rd[1][2] = (m13 * m32 - m12 * m33) * invDet
  rd[1][3] = (m12 * m23 - m13 * m22) * invDet

  -- Row 2 elements
  rd[2][1] = (m23 * m31 - m21 * m33) * invDet
  rd[2][2] = (m11 * m33 - m13 * m31) * invDet
  rd[2][3] = (m13 * m21 - m11 * m23) * invDet

  -- Row 3 elements
  rd[3][1] = (m21 * m32 - m22 * m31) * invDet
  rd[3][2] = (m12 * m31 - m11 * m32) * invDet
  rd[3][3] = (m11 * m22 - m12 * m21) * invDet

  return result
end

--- Creates a new sub-matrix by removing a specific row and column.
--- (Helper function used for determinant and cofactor calculations)
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

--- Calculates the determinant of a square matrix recursively.
---@return number
function Matrix:determinant()
  assert(
    self.rows == self.cols,
    "Determinant can only be calculated for square matrices"
  )

  local n = self.rows

  if n == 1 then return self.data[1][1] end

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

--- Computes the cofactor matrix of a square matrix.
---@return Matrix
function Matrix:cofactor()
  assert(self.rows == self.cols,
    "Cofactor matrix can only be calculated for square matrices.")

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
---@return Matrix|nil, string?
function Matrix:inverse()
  assert(self.rows == self.cols, "Only square matrices can be inverted.")

  -- if self.rows == 3 and self.cols == 3 then
  --   return self:inverse3x3()
  -- end

  local det = self:determinant()

  if math.abs(det) < 1e-9 then
    return nil, "Singular" -- Matrix is singular and cannot be inverted
  end

  -- For a 1x1 matrix, the inverse is just 1 / element
  if self.rows == 1 then
    local result = Matrix.new(1, 1)
    result.data[1][1] = 1 / self.data[1][1]
    return result
  end

  -- The inverse is equal to (1 / determinant) * Transpose(CofactorMatrix)
  local matCofactor = self:cofactor()
  local matAdjugate = matCofactor:transpose()

  return matAdjugate:multiply(1 / det)
end

return Matrix
