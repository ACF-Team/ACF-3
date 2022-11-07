local ents         = ents
local math         = math
local util         = util
local debugoverlay = debugoverlay
local ACF          = ACF
local Damage       = ACF.TempDamage
local Objects      = Damage.Objects
local White        = Color(255, 255, 255)
local Blue         = Color(0, 0, 255)
local Red          = Color(255, 0, 0)
local TraceData    = {
	start  = true,
	endpos = true,
	filter = true,
	mask   = MASK_SOLID,
}

--- Checks whether an entity can be affected by ACF explosions.
-- @param Entity The entity to be checked.
-- @return True if the entity can be affected by explosions, false otherwise.
function Damage.isValidTarget(Entity)
	local Type = ACF.Check(Entity)

	if not Type then return false end
	if Entity.Exploding then return false end
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

	local Mesh = Entity:GetPhysicsObject():GetMesh()

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
-- See: ACF.Damage.explosionEffect.
-- @param 
function Damage.createExplosion(Position, FillerMass, FragMass, Filter, DmgInfo)
	local Power       = FillerMass * ACF.HEPower -- Power in KJ of the filler mass of TNT
	local Radius      = Damage.getBlastRadius(FillerMass)
	local MaxSphere   = 4 * math.pi * (Radius * 2.54) ^ 2 -- Surface Area of the sphere at maximum radius
	local Fragments   = math.max(math.floor((FillerMass / FragMass) * ACF.HEFrag), 2)
	local FragMass    = FragMass / Fragments
	local BaseFragV   = (Power * 50000 / FragMass / Fragments) ^ 0.5
	local FragArea    = (FragMass / 7.8) ^ 0.33 -- cm2
	local FragCaliber = 20 * (FragMass / math.pi) ^ 0.5 --mm
	local Found       = ents.FindInSphere(Position, Radius)
	local Targets     = {}
	local Loop        = true -- Find more props to damage whenever a prop dies

	if not Filter then Filter = {} end

	TraceData.start  = Position
	TraceData.filter = Filter

	debugoverlay.Cross(Position, 15, 15, White, true)
	debugoverlay.Sphere(Position, Radius, 15, White, true)

	do -- Screen shaking
		local Amp = math.min(Power * 0.0005, 50)

		util.ScreenShake(Position, Amp, Amp, Amp / 15, Radius * 10)
	end

	-- Quickly getting rid of all the entity we can't damage
	for Index, Entity in ipairs(Found) do
		if Damage.isValidTarget(Entity) then
			Targets[Entity] = true
			Found[Index]    = nil
		else
			Filter[#Filter + 1] = Entity
		end
	end

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

				if Damage.isValidTarget(HitEnt) and not Damaged[HitEnt] then
					local Distance      = Position:Distance(HitPos)
					local Sphere        = math.max(4 * math.pi * (Distance * 2.54) ^ 2, 1) -- Surface Area of the sphere at the range of that prop
					local EntArea       = HitEnt.ACF.Area
					local EntArmor      = HitEnt.ACF.Armour
					local Area          = math.min(EntArea / Sphere, 0.5) * MaxSphere -- Project the Area of the prop to the Area of the shadow it projects at the explosion max radius
					local AreaFraction  = Area / MaxSphere
					local PowerFraction = Power * AreaFraction -- How much of the total power goes to that prop
					local BlastResult, FragResult, Losses

					debugoverlay.Line(Position, HitPos, 15, Red, true) -- Red line for a successful hit

					DmgInfo:SetHitGroup(Trace.HitGroup)

					do -- Blast damage
						local Feathering  = 1 - math.min(1, Distance / Radius) ^ 0.5 -- 0.5 was ACF.HEFeatherExp
						local BlastArea   = EntArea / ACF.Threshold * Feathering
						local BlastEnergy = PowerFraction ^ 0.4 * BlastArea -- 0.4 was ACF.HEBlastPen
						local BlastPen    = Damage.getBlastPenetration(BlastEnergy, BlastArea)
						local BlastDmg    = Objects.DamageResult(BlastArea, BlastPen, EntArmor)

						DmgInfo:SetType("Blast")

						BlastResult = Damage.dealDamage(HitEnt, BlastDmg, DmgInfo)
						Losses      = BlastResult.Loss * 0.5
					end

					do -- Fragment damage
						local FragHit = math.floor(Fragments * AreaFraction)

						if FragHit > 0 then
							local Loss    = (Distance / BaseFragV) * BaseFragV ^ 2 * FragMass ^ 0.33 * 0.0001
							local FragVel = math.max(BaseFragV - Loss / ACF.DragDiv, 0) * 0.0254
							local FragPen = ACF.Penetration(FragVel, FragMass, FragCaliber)
							local FragDmg = Objects.DamageResult(FragArea, FragPen, EntArmor, nil, nil, Fragments ^ 0.5)

							DmgInfo:SetType("Fragment")

							FragResult = Damage.dealDamage(HitEnt, FragDmg, DmgInfo)
							Losses     = Losses + FragResult.Loss * 0.5
						end
					end

					Damaged[HitEnt] = true -- This entity can no longer recieve damage from this explosion

					local FragKill = FragResult and FragResult.Kill

					if BlastResult.Kill or FragKill then
						local Min = HitEnt:OBBMins()
						local Max = HitEnt:OBBMaxs()

						debugoverlay.BoxAngles(HitEnt:GetPos(), Min, Max, HitEnt:GetAngles(), 15, Red) -- Red box on destroyed entities

						Filter[#Filter + 1] = HitEnt -- Filter from traces
						Targets[HitEnt]     = nil -- Remove from list

						if FragKill then
							ACF.APKill(HitEnt, Direction, PowerFraction)
						else
							local Debris = ACF.HEKill(HitEnt, Direction, PowerFraction, Position)

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
					debugoverlay.Line(Position, HitPos, 15, Blue, true) -- Blue line for an invalid entity

					Filter[#Filter + 1] = HitEnt -- Filter from traces
					Targets[HitEnt]     = nil -- Remove from list
				end
			else
				-- Not removed from future damage sweeps so as to provide multiple chances to be hit
				debugoverlay.Line(Position, HitPos, 15, White, true) -- White line for a miss.
			end
		end

		Power = math.max(Power - PowerSpent, 0)
	end
end

concommand.Add("acf_boom", function(Player)
	if not IsValid(Player) then return end

	local Filler  = math.random(0.5, 50)
	local DmgInfo = Objects.DamageInfo(Player)
	local HitPos  = Player:GetEyeTrace().HitPos

	print("Creating explosion with " .. Filler .. "kg of filler.")

	Damage.createExplosion(HitPos, Filler, Filler * 0.5, nil, DmgInfo)
	Damage.explosionEffect(HitPos, nil, Filler)
end)
