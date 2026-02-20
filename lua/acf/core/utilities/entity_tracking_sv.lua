local ACF             = ACF
local Clock           = ACF.Utilities.Clock
local Countermeasures = ACF.Classes.Countermeasures
local Contraptions    = {}

local function UpdateValues(Contraption)
	local Entity = Contraption.ACF_Baseplate
	-- If legal checks are disabled, use any ancestor
	if not ACF.LegalChecks and not IsValid(Entity) and Contraption and Contraption.families and next(Contraption.families) and next(Contraption.families).ancestor then Entity = next(Contraption.families).ancestor end
	if not IsValid(Entity) then return end

	local PhysObj  = Entity:GetPhysicsObject()
	local Velocity = Entity:GetVelocity()
	local PrevPos  = Entity.ACF_Position
	local Position

	if IsValid(PhysObj) then
		Position = Entity:LocalToWorld(PhysObj:GetMassCenter())
	else
		Position = Entity:GetPos()
	end

	-- Entities being moved around by SetPos will have a velocity of 0
	-- By using the difference between positions we can get a proper value
	if Velocity:LengthSqr() == 0 and PrevPos then
		Velocity = (Position - PrevPos) / Clock.DeltaTime
	end

	Entity.ACF_Position = Position
	Entity.ACF_Velocity = Velocity
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
		local EntityContraption = Entity:GetContraption()
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
		if Contraption and Entity:GetContraption() == Contraption then continue end
		-- Skip disabled baseplates here

		if Position:DistToSqr(Entity:GetPos()) <= RadiusSqr then
			Result[Entity] = true
		end
	end

	return Result
end
