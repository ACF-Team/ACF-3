local ACF             = ACF
local Clock           = ACF.Utilities.Clock
local Countermeasures = ACF.Classes.Countermeasures
local Contraptions    = {}

local ENTITY  = FindMetaTable("Entity")
local PHYSOBJ = FindMetaTable("PhysObj")
local VECTOR  = FindMetaTable("Vector")

local IsEntityValid  = ACF.Optimizations.IsEntityValid
local IsPhysObjValid = ACF.Optimizations.IsPhysObjValid

local function UpdateValues(Contraption)
	local Entity = Contraption.ACF_Baseplate
	-- If legal checks are disabled, use any ancestor
	if not ACF.LegalChecks and not IsEntityValid(Entity) and Contraption and Contraption.families then
		local NextFamily = next(Contraption.families)
		if NextFamily then
			local Ancestor   = NextFamily.ancestor
			if IsEntityValid(Ancestor) then
				Entity = Ancestor
			end
		end
	end

	if not IsEntityValid(Entity) then return end

	local SelfTable = ENTITY.GetTable(Entity)
	local PhysObj   = ENTITY.GetPhysicsObject(Entity)
	local Velocity  = ENTITY.GetVelocity(Entity)
	local PrevPos   = SelfTable.ACF_Position
	local Position

	if IsPhysObjValid(PhysObj) then
		Position = ENTITY.LocalToWorld(Entity, PHYSOBJ.GetMassCenter(PhysObj))
	else
		Position = ENTITY.GetPos(Entity)
	end

	-- Entities being moved around by SetPos will have a velocity of 0
	-- By using the difference between positions we can get a proper value
	if VECTOR.LengthSqr(Velocity) == 0 and PrevPos then
		Velocity = Position - PrevPos
		VECTOR.Div(Velocity, Clock.DeltaTime)
	end

	SelfTable.ACF_Position = Position
	SelfTable.ACF_Velocity = Velocity
	Contraption.Ancestor = Entity
end

-- Maintain ancestors array
hook.Add("cfw.contraption.created", "ACF Entity Tracking", function(Contraption)
	Contraptions[Contraption] = true
end)

hook.Add("cfw.contraption.removed", "ACF Entity Tracking", function(Contraption)
	Contraptions[Contraption] = nil
end)

hook.Add("ACF_OnTick", "ACF Entity Tracking", function()
	for Contraption in pairs(Contraptions) do UpdateValues(Contraption) end
end)

function ACF.GetEntitiesInCone(Position, Direction, Degrees, Contraption)
	local Result = {}

	for Con in pairs(Contraptions) do
		local Entity = Con.Ancestor
		if not IsValid(Entity) then continue end
		local EntityContraption = Entity:CFW_GetContraption()
		if Contraption and EntityContraption == Contraption then continue end

		if ACF.LegalChecks and Entity:GetClass() == "acf_baseplate" and Entity.Disabled then continue end

		if Countermeasures.ConeContainsPos(Position, Direction, Degrees, Entity:GetPos()) then
			Result[Entity] = true
		end
	end

	return Result
end

function ACF.GetEntitiesInSphere(Position, Radius, Contraption)
	local Result = {}
	local RadiusSqr = Radius * Radius

	for Con in pairs(Contraptions) do
		local Entity = Con.Ancestor
		if not IsValid(Entity) then continue end
		if Contraption and Entity:CFW_GetContraption() == Contraption then continue end
		-- Skip disabled baseplates here

		if Position:DistToSqr(Entity:GetPos()) <= RadiusSqr then
			Result[Entity] = true
		end
	end

	return Result
end
