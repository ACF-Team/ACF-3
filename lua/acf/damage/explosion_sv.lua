local ents         = ents
local math         = math
local util         = util
local ACF          = ACF
local Damage       = ACF.Damage
local Objects      = Damage.Objects
local White        = Color(255, 255, 255)
local Blue         = Color(0, 0, 255)
local Red          = Color(255, 0, 0)
local TraceData    = {
	start  = true,
	endpos = true,
	filter = true,
	mask   = MASK_SOLID + CONTENTS_AUX,
}
local Ballistics	= ACF.Ballistics
local Debug			= ACF.Debug

--- Checks whether an entity can be affected by ACF explosions.
-- @param Entity The entity to be checked.
-- @return True if the entity can be affected by explosions, false otherwise.
function Damage.isValidTarget(Entity)
	local EntTbl = Entity:GetTable()
	if EntTbl.ACF_Killed or EntTbl.Exploding then return false end

	local EntACF = EntTbl.ACF
	local Type = EntACF and EntACF.Type or ACF.Check(Entity)

	if not Type then return false end
	if not Ballistics.TestFilter(Entity) then return false end

	if Type ~= "Squishy" then return true end

	return Entity:Health() > 0
end

--- Returns a random position on the given entity.
-- @param Entity The entity to get a random position from.
-- @param A world position based on the shape and size of the given entity.
function Damage.getRandomPos(Entity)
	local IsChar = Entity.ACF.Type == "Squishy"

	if IsChar then
		-- Scale down the "hitbox" since most of the character is in the middle
		local Mins = Entity:OBBMins() * 0.65
		local Maxs = Entity:OBBMaxs() * 0.65
		local X    = math.Rand(Mins[1], Maxs[1])
		local Y    = math.Rand(Mins[2], Maxs[2])
		local Z    = math.Rand(Mins[3], Maxs[3])

		return Entity:LocalToWorld(Vector(X, Y, Z))
	end

	local PhysObj   = Entity:GetPhysicsObject()
	local ValidPhys = IsValid(PhysObj)
	local Mesh      = ValidPhys and PhysObj:GetMesh() or nil

	if not Mesh then -- Spherical collisions
		local Mins = Entity:OBBMins()
		local Maxs = Entity:OBBMaxs()
		local X    = math.Rand(Mins[1], Maxs[1])
		local Y    = math.Rand(Mins[2], Maxs[2])
		local Z    = math.Rand(Mins[3], Maxs[3])
		local Rand = Vector(X, Y, Z)

		-- Attempt to a random point in the sphere
		return Entity:LocalToWorld(Rand:GetNormalized() * math.Rand(1, Entity:BoundingRadius() * 0.5))
	else
		local Rand = math.random(3, #Mesh / 3) * 3
		local P    = Vector()

		for I = Rand - 2, Rand do P = P + Mesh[I].pos end

		return Entity:LocalToWorld(P / 3) -- Attempt to hit a point on a face of the mesh
	end
end

--- Creates an explosion. Important to note this explosion is completely invisible
-- See: ACF.Damage.explosionEffect to create a visual representation of an explosion.
-- @param Position The world coordinates where the explosion will be created at.
-- @param FillerMass The amount of HE filler on kilograms used to create this explosion.
-- @param FragMass The amount of steel containing the filler on kilograms.
-- @param Filter Optional, a list of entities that will not be affected by the explosion.
-- @param DmgInfo A DamageInfo object. It's recommended to populate the Attacker and Inflictor fields.
-- All the other fields will be controlled by the explosion itself, so they're not necessary.
function Damage.createExplosion(Position, FillerMass, FragMass, Filter, DmgInfo)
	local Power       = FillerMass * ACF.HEPower -- Power in KJ of the filler mass of TNT
	local Radius      = Damage.getBlastRadius(FillerMass)
	local MaxSphere   = 4 * math.pi * (Radius * ACF.InchToCm) ^ 2 -- Surface Area of the sphere at maximum radius
	local Fragments   = math.max(math.floor(FillerMass / FragMass * ACF.HEFrag ^ 0.5), 2)
	local FragMass    = FragMass / Fragments
	local BaseFragV   = (Power * 50000 / FragMass / Fragments) ^ 0.5
	local FragArea    = (FragMass / 7.8) ^ 0.33 -- cm2
	local FragCaliber = 20 * (FragMass / math.pi) ^ 0.5 --mm
	local Found       = ents.FindInSphere(Position, Radius)
	local Targets     = {}
	local Loop        = true -- Find more props to damage whenever a prop dies

	if not Filter then Filter = {} end

	Debug.Cross(Position, 15, 15, White, true)
	--Debug.Sphere(Position, Radius, 15, White, true)

	do -- Screen shaking
		local Amp = math.min(Power * 0.0005, 50)

		util.ScreenShake(Position, Amp, Amp, Amp / 15, Radius * 10)
	end

	-- Quickly getting rid of all the entities we can't damage
	for Index, Entity in ipairs(Found) do
		if Damage.isValidTarget(Entity) then
			Targets[Entity] = true
			Found[Index]    = nil
		else
			Filter[#Filter + 1] = Entity
		end
	end

	if not next(Targets) then return end -- There's nothing to damage

	DmgInfo:SetOrigin(Position)

	TraceData.start  = Position
	TraceData.filter = Filter

	while Loop and Power > 0 do
		local PowerSpent = 0
		local Damaged    = {}

		Loop = false

		for Entity in pairs(Targets) do
			if not Damage.isValidTarget(Entity) then
				Filter[#Filter + 1] = Entity
				Targets[Entity]     = nil

				continue
			end

			local HitPos    = Damage.getRandomPos(Entity)
			local Delta     = HitPos - Position
			local Direction = Delta:GetNormalized()

			TraceData.endpos = Position + Direction * (Delta:Length() + 24)

			local Trace  = ACF.trace(TraceData)
			local HitPos = Trace.HitPos

			if Trace.HitNonWorld then
				local HitEnt = Trace.Entity

				if not Damaged[HitEnt] and Damage.isValidTarget(HitEnt) then
					local Distance      = Position:Distance(HitPos)
					local Sphere        = math.max(4 * math.pi * (Distance * ACF.InchToCm) ^ 2, 1) -- Surface Area of the sphere at the range of that prop
					local EntArea       = HitEnt.ACF.Area
					local EntArmor      = HitEnt.ACF.Armour
					local Area          = math.min(EntArea / Sphere, 0.5) * MaxSphere -- Project the Area of the prop to the Area of the shadow it projects at the explosion max radius
					local AreaFraction  = Area / MaxSphere
					local PowerFraction = Power * AreaFraction -- How much of the total power goes to that prop
					local BlastResult, FragResult, Losses

					Debug.Line(Position, HitPos, 15, Red, true) -- Red line for a successful hit

					DmgInfo:SetHitPos(HitPos)
					DmgInfo:SetHitGroup(Trace.HitGroup)

					do -- Blast damage
						local Feathering  = 1 - math.min(0.99, Distance / Radius) ^ 0.5 -- 0.5 was ACF.HEFeatherExp
						local BlastArea   = EntArea / ACF.Threshold * Feathering
						local BlastEnergy = PowerFraction ^ 0.3 * BlastArea -- 0.3 was ACF.HEBlastPen
						local BlastPen    = Damage.getBlastPenetration(BlastEnergy, BlastArea)
						local BlastDmg    = Objects.DamageResult(BlastArea, BlastPen, EntArmor)

						DmgInfo:SetType(DMG_BLAST)

						BlastResult = Damage.dealDamage(HitEnt, BlastDmg, DmgInfo)
						Losses      = BlastResult.Loss * 0.5
					end

					do -- Fragment damage
						local FragHit = math.floor(Fragments * AreaFraction)

						if FragHit > 0 then
							local Loss    = BaseFragV * Distance / Radius
							local FragVel = math.max(BaseFragV - Loss, 0) * ACF.InchToMeter
							local FragPen = ACF.Penetration(FragVel, FragMass, FragCaliber)
							local FragDmg = Objects.DamageResult(FragArea, FragPen, EntArmor, nil, nil, Fragments)

							DmgInfo:SetType(DMG_BULLET)

							FragResult = Damage.dealDamage(HitEnt, FragDmg, DmgInfo)
							Losses     = Losses + FragResult.Loss * 0.5
						end
					end

					Damaged[HitEnt] = true -- This entity can no longer receive damage from this explosion

					local FragKill = FragResult and FragResult.Kill

					if BlastResult.Kill or FragKill then
						-- local Min = HitEnt:OBBMins()
						-- local Max = HitEnt:OBBMaxs()

						-- Debug.BoxAngles(HitEnt:GetPos(), Min, Max, HitEnt:GetAngles(), 15, Red) -- Red box on destroyed entities

						Filter[#Filter + 1] = HitEnt -- Filter from traces
						Targets[HitEnt]     = nil -- Remove from list

						if FragKill then
							ACF.APKill(HitEnt, Direction, PowerFraction, DmgInfo)
						else
							local Debris = ACF.HEKill(HitEnt, Direction, PowerFraction, Position, DmgInfo)

							for Fireball in pairs(Debris) do
								if IsValid(Fireball) then Filter[#Filter + 1] = Fireball end
							end
						end

						Loop = true -- Check for new targets since something died, maybe we'll find something new
					elseif ACF.HEPush then -- Just damaged, not killed, so push on it some
						ACF.KEShove(HitEnt, Position, Direction, PowerFraction * 33.3) -- Assuming about 1/30th of the explosive energy goes to propelling the target prop (Power in KJ * 1000 to get J then divided by 33)
					end

					PowerSpent = PowerSpent + PowerFraction * Losses -- Removing the energy spent killing props
				elseif not Damaged[HitEnt] then
					Debug.Line(Position, HitPos, 15, Blue, true) -- Blue line for an invalid entity

					Filter[#Filter + 1] = HitEnt -- Filter from traces
					Targets[HitEnt]     = nil -- Remove from list
				end
			else
				-- Not removed from future damage sweeps so as to provide multiple chances to be hit
				Debug.Line(Position, HitPos, 15, White, true) -- White line for a miss.
			end
		end

		Power = math.max(Power - PowerSpent, 0)
	end
end