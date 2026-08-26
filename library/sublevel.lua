---@meta

---@module "sublevel"
sublevel = {}

---@return ccTweaked.Vector
function sublevel.getCenterOfMass() end

---@return number
function sublevel.getMass() end

---@return ccTweaked.Vector
function sublevel.getVelocity() end

---@return ccTweaked.Vector
function sublevel.getAngularVelocity() end

---@return ccTweaked.sublevel.Pose
function sublevel.getLogicalPose() end

---@class ccTweaked.sublevel.Pose
---@field orientation Quaternion
---@field position Vector
---@field rotationPoint Vector
---@field scale Vector

return sublevel
