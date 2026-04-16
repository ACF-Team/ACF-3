-- Some helpers for when you know the data-type of what you're validating
-- Because otherwise, IsValid does an __index call...
ACF.Optimizations = {}

local ENTITY     = FindMetaTable("Entity")
local PHYSOBJ    = FindMetaTable("PhysObj")

function ACF.Optimizations.IsEntityValid(X)  return X and ENTITY.IsValid(X)  end
function ACF.Optimizations.IsPhysObjValid(X) return X and PHYSOBJ.IsValid(X) end