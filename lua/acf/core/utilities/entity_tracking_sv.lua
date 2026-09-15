local ACF             = ACF
local Clock           = ACF.Utilities.Clock
-- Resolved at call time: this file loads under core/, before entities/countermeasure/ creates the table.
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

hook.Add("cfw.contraption.merged", "ACF Entity Tracking", function(Contraption)
	Contraptions[Contraption] = nil
end)

hook.Add("ACF_OnTick", "ACF Entity Tracking", function()
	for Contraption in pairs(Contraptions) do UpdateValues(Contraption) end
end)

-- TODO: Fix this properly. It's something with CFW and elastics. I do not have the time to investigate why this happens at the moment,
-- and to properly understand it we require a REALLY in-depth frame loop analysis
timer.Create("ACF_CheckForDeadContraptionsHack", 10, 0, function()
	local DeadContraptions = {}

	for Contraption in pairs(Contraptions) do
		local AnyValid = false
		for Ent in pairs(Contraption.ents) do
			if IsValid(Ent) then
				AnyValid = true
				break
			end
		end
		if not AnyValid then
			DeadContraptions[#DeadContraptions + 1] = Contraption
		end
	end

	for _, Contraption in ipairs(DeadContraptions) do
		Contraptions[Contraption] = nil
	end
end)

function ACF.GetEntitiesInCone(Position, Direction, Degrees, Contraption)
	local Result = {}

	for Con in pairs(Contraptions) do
		local Entity = Con.Ancestor
		if not IsValid(Entity) then continue end
		local EntityContraption = Entity:CFW_GetContraption()
		if Contraption and EntityContraption == Contraption then continue end

		if ACF.LegalChecks and Entity:GetClass() == "acf_baseplate" and Entity.Disabled then continue end

		if ACF.Countermeasures.ConeContainsPos(Position, Direction, Degrees, Entity:GetPos()) then
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

--- Tests every tracked contraption against a list of shapes (cones and/or spheres) in a single pass, instead
--- of iterating the tracked contraption pool once per shape. Intended for aggregating many radars' detection
--- zones at once (e.g. a Radar Synchronizer batching same-rate-group radars) where a naive per-radar call to
--- GetEntitiesInCone or GetEntitiesInSphere would mean one full iteration of the tracked pool per radar.
--- @param Shapes table An array of shape entries: {Radar = <key>, Position = Vector, Direction = Vector, Degrees = number} for a cone, or {Radar = <key>, Position = Vector, Radius = number} for a sphere.
--- @param Contraption table|nil If supplied, candidates belonging to this contraption are skipped for every shape (self filter).
--- @return table<Entity, table> A table mapping matched entities to an array of the Radar keys (from Shapes) whose geometry matched them.
function ACF.GetEntitiesInShapes(Shapes, Contraption)
	local Result = {}

	for Con in pairs(Contraptions) do
		local Entity = Con.Ancestor
		if not IsValid(Entity) then continue end
		local EntityContraption = Entity:CFW_GetContraption()
		if Contraption and EntityContraption == Contraption then continue end

		if ACF.LegalChecks and Entity:GetClass() == "acf_baseplate" and Entity.Disabled then continue end

		ACF.Countermeasures.MatchShapes(Result, Entity, Entity:GetPos(), Shapes)
	end

	return Result
end
