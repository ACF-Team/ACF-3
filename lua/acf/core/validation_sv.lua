-- Entity validation for ACF

-- Local Vars -----------------------------------
local ACF          = ACF
local ModelData	   = ACF.ModelData
local StringFind   = string.find
local Baddies	   = ACF.GlobalFilter
local BaddiesLess  = ACF.ArmorableGlobalFilterExceptions

--- Determines the type of damage that should be dealt to the given entity.
--- @param Entity entity The entity to be checked
--- @return string # The type of damage that ACF should deal to the entity
function ACF.GetEntityType(Entity)
	if Entity:IsPlayer() or Entity:IsNPC() or Entity:IsNextBot() then return "Squishy" end

	-- Explicitly handle support for LVS/simfphys/WAC/Glide
	local EntTbl = Entity:GetTable()
	if EntTbl.LVS or EntTbl.IsSimfphyscar or EntTbl.isWacAircraft or EntTbl.IsGlideVehicle then return "Squishy" end

	if Entity:IsVehicle() then return "Vehicle" end

	return "Prop"
end

--- Computes and caches the entity's surface area, used by explosions to determine blast/fragment exposure.
--- @param Entity entity The entity to compute the area for
--- @param PhysObj PhysObj The entity's physics object
--- @return number # The entity's surface area, in cm²
function ACF.UpdateArea(Entity, PhysObj)
	local Area = PhysObj:GetSurfaceArea()

	if Area then -- Normal collisions
		local AreaMult = 0.52505066107 -- This seems to be a conversion from cm to grid units on the architectural scale (approx. 1 / 1.905)
		Area = Area * ACF.InchToCmSq * AreaMult
	elseif PhysObj:GetMesh() then -- Box collisions
		local Size = Entity:OBBMaxs() - Entity:OBBMins()

		Area = ((Size.x * Size.y) + (Size.x * Size.z) + (Size.y * Size.z)) * ACF.InchToCmSq
	else -- Spherical collisions
		local Radius = Entity:BoundingRadius()

		Area = 4 * math.pi * Radius * Radius * ACF.InchToCmSq
	end

	Entity.ACF.Area = Area

	return Area
end

-- Global Funcs ---------------------------------

function ACF.Check(Entity, ForceUpdate) -- IsValid but for ACF
	if not IsValid(Entity) then return false end

	local Class = Entity:GetClass()
	if Baddies[Class] and not BaddiesLess[Class] then return false end

	local PhysObj = Entity:GetPhysicsObject()
	if not IsValid(PhysObj) then return false end

	local EntACF = Entity.ACF

	if not EntACF then
		if Entity:IsWorld() or Entity:IsWeapon() or Entity:GetBrushPlaneCount() > 0 or StringFind(Class, "func_") then
			Baddies[Class] = true

			return false
		end

		ACF.Activate(Entity)
		EntACF = Entity.ACF
	elseif ForceUpdate or not IsValid(EntACF.PhysObj) or EntACF.PhysObj ~= PhysObj then
		ACF.Activate(Entity)
	end

	return EntACF.Type
end

function ACF.Activate(Entity)
	local PhysObj = Entity:GetPhysicsObject()
	local EntTbl  = Entity:GetTable()

	if not IsValid(PhysObj) then return end
	if not EntTbl.ACF then EntTbl.ACF = {} end

	ModelData.Populate(Entity:GetModel())

	EntTbl.ACF.Type      = ACF.GetEntityType(Entity)
	EntTbl.ACF.PhysObj   = PhysObj

	-- Backwards compatibility placeholders. To remove later.
	-- Only set when missing, ACF entities derive their health ratio from these when reactivated (see ComputeVolumetricMesh)
	EntTbl.ACF.Health    = EntTbl.ACF.Health or 1
	EntTbl.ACF.MaxHealth = EntTbl.ACF.MaxHealth or 1

	ACF.UpdateArea(Entity, PhysObj)
	ACF.ComputeVolumetricMesh(Entity)
end