local ents         = ents
local math         = math
local util         = util
local debugoverlay = debugoverlay
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
	local MaxSphere   = 4 * math.pi * (Radius * 2.54) ^ 2 -- Surface Area of the sphere at maximum radius
	local Fragments   = math.max(math.floor(FillerMass / FragMass * ACF.HEFrag ^ 0.5), 2)
	local FragMass    = FragMass / Fragments
	local BaseFragV   = (Power * 50000 / FragMass / Fragments) ^ 0.5
	local FragArea    = (FragMass / 7.8) ^ 0.33 -- cm2
	local FragCaliber = 20 * (FragMass / math.pi) ^ 0.5 --mm
	local Found       = ents.FindInSphere(Position, Radius)
	local Targets     = {}
	local Loop        = true -- Find more props to damage whenever a prop dies

	if not Filter then Filter = {} end

	debugoverlay.Cross(Position, 15, 15, White, true)
	--debugoverlay.Sphere(Position, Radius, 15, White, true)

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

				if Damage.isValidTarget(HitEnt) and not Damaged[HitEnt] then
					local Distance      = Position:Distance(HitPos)
					local Sphere        = math.max(4 * math.pi * (Distance * 2.54) ^ 2, 1) -- Surface Area of the sphere at the range of that prop
					local EntArea       = HitEnt.ACF.Area
					local Area          = math.min(EntArea / Sphere, 0.5) * MaxSphere -- Project the Area of the prop to the Area of the shadow it projects at the explosion max radius
					local AreaFraction  = Area / MaxSphere
					local PowerFraction = Power * AreaFraction -- How much of the total power goes to that prop
					local BlastResult, FragResult, Losses

					debugoverlay.Line(Position, HitPos, 15, Red, true) -- Red line for a successful hit

					DmgInfo:SetHitPos(HitPos)
					DmgInfo:SetHitGroup(Trace.HitGroup)

					do -- Blast damage
						local Feathering  = 1 - math.min(0.99, Distance / Radius) ^ 0.5 -- 0.5 was ACF.HEFeatherExp
						local BlastArea   = EntArea / ACF.Threshold * Feathering
						local BlastEnergy = PowerFraction ^ 0.3 * BlastArea -- 0.3 was ACF.HEBlastPen
						local BlastPen    = Damage.getBlastPenetration(BlastEnergy, BlastArea)
						local BlastDmg    = Objects.DamageResult(BlastArea, BlastPen, HitEnt.ACF.Armour)

						DmgInfo:SetType(DMG_BLAST)

						BlastResult = Damage.dealDamage(HitEnt, BlastDmg, DmgInfo)
						Losses      = BlastResult.Loss * 0.5
					end

					do -- Fragment damage
						local FragHit = math.floor(Fragments * AreaFraction)

						if FragHit > 0 then
							local Loss    = BaseFragV * Distance / Radius
							local FragVel = math.max(BaseFragV - Loss, 0) * 0.0254
							local FragPen = ACF.Penetration(FragVel, FragMass, FragCaliber)
							local FragDmg = Objects.DamageResult(FragArea, FragPen, HitEnt.ACF.Armour, nil, nil, Fragments)

							DmgInfo:SetType(DMG_BULLET)

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

--[[
do -- Experimental HE code
	local DEBUG_TIME  = 30
	local DEBUG_RED   = Color(255, 0, 0, 15)
	--local DEBUG_GREEN = Color(0, 255, 0)

	local min   = math.min
	local max   = math.max
	local floor = math.floor
	local round = math.Round
	local clamp = math.Clamp

	local function isValidTarget(ent)
		if not IsValid(ent) then return false end
		if ent.Exploding then return false end
		if not ACF.Check(ent) then return false end
		if (ent:IsPlayer() or ent:IsNPC()) and ent:Health() <= 0 then return false end

		return true
	end

	local function getRandomPos(Entity, IsChar)
		if IsChar then
			local Mins, Maxs = Entity:OBBMins() * 0.65, Entity:OBBMaxs() * 0.65 -- Scale down the "hitbox" since most of the character is in the middle
			local Rand		 = Vector(math.Rand(Mins[1], Maxs[1]), math.Rand(Mins[2], Maxs[2]), math.Rand(Mins[3], Maxs[3]))

			return Entity:LocalToWorld(Rand)
		else
			local Mesh = Entity:GetPhysicsObject():GetMesh()

			if not Mesh then -- Is Make-Sphericaled
				local Mins, Maxs = Entity:OBBMins(), Entity:OBBMaxs()
				local Rand		 = Vector(math.Rand(Mins[1], Maxs[1]), math.Rand(Mins[2], Maxs[2]), math.Rand(Mins[3], Maxs[3]))

				return Entity:LocalToWorld(Rand:GetNormalized() * math.Rand(1, Entity:BoundingRadius() * 0.5)) -- Attempt to a random point in the sphere
			else
				local Rand = math.random(3, #Mesh / 3) * 3
				local P    = Vector(0, 0, 0)

				for I = Rand - 2, Rand do P = P + Mesh[I].pos end

				return Entity:LocalToWorld(P / 3) -- Attempt to hit a point on a face of the mesh
			end
		end
	end

	local trace     = ACF.trace
	local traceData = { mask = MASK_SOLID }

	local function doTrace(originalTarget)
		local traceRes  = trace(traceData)
		local hitEntity = traceRes.Entity

		if traceRes.HitNonWorld and hitEntity ~= originalTarget and not isValidTarget(hitEntity) then
			traceData.filter[#traceData.filter + 1] = hitEntity

			return doTrace()
		end

		return traceRes
	end

	local findInSphere = ents.FindInSphere
	local doDamage     = ACF.Damage
	local doShove      = ACF.KEShove
	local doAPKill     = ACF.APKill
	local doHEKill     = ACF.HEKill
	local fakeBullet   = {
		IsFrag   = true,
		Owner    = true,
		Gun      = true,
		Caliber  = true,
		Diameter = true,
		ProjArea = true,
		ProjMass = true,
		Flight   = true,
		Speed    = true,
		GetPenetration = function(self) return self.penetration end
	}

	function ACF.HE(origin, explosiveMass, fragMass, inflictor, filter, gun)
		local totalPower = explosiveMass * ACF.HEPower -- KJ

		local blastRatio       = clamp(explosiveMass / fragMass, 0, 1)
		local blastRadius      = explosiveMass ^ 0.33 * 8 * 39.37 -- in
		local blastSurfaceArea = 4 * 3.1415 * blastRadius ^ 2 -- in^2
		local blastPower       = totalPower * blastRatio -- KJ

		local fragCount   = blastRatio < 1 and max(floor(blastRatio * ACF.HEFrag), 2) or 0
		local fragPower   = totalPower - blastPower -- KJ
		local fragMass    = fragMass / fragCount -- kg
		local fragSpeed   = (2 * (fragPower * 1000 / fragCount) / fragMass) ^ 0.5 -- m/s
		local fragVolume  = fragMass / 0.00794 -- g/mm^3
		local fragCaliber = (6 * fragVolume / 3.1415) ^ 0.3333 -- mm
		local fragArea    = 0.25 * 3.1415 * fragCaliber^2
		local fragPen     = ACF.Penetration(fragSpeed, fragMass, fragCaliber) * 0.25 -- mm

		fakeBullet.Owner    = inflictor or gun
		fakeBullet.Caliber  = fragCaliber
		fakeBullet.Diameter = fragCaliber -- this might not be correct
		fakeBullet.ProjArea = fragArea
		fakeBullet.ProjMass = fragMass
		fakeBullet.Speed    = fragSpeed / 39.37 -- m/s

		local filter       = filter or {}
		local filterCount  = #filter

		traceData.start  = origin
		traceData.filter = filter

		local bogies              = findInSphere(origin, blastRadius)
		--local bogieCount          = #bogies
		local damaged             = {} -- entities that have been damaged and cannot be damaged again
		local penetratedSomething = true

		do -- debug prints
			--print("HE")
			print("  Total Power: " .. round(totalPower, 1) .. " KJ")
			print("  Blast Ratio: " .. round(blastRatio, 2))
			print("  Blast Radius: " .. round(blastRadius / 39.37) .. " m")
			--print("  Blast Energy: " .. round(blastPower, 1) .. " KJ")
			--print("  Blast Surface Area: " .. round(blastSurfaceArea) .. " in^2")
			print("")
			--print("  Frag Energy: " .. round(fragPower / fragCount, 1) .. " KJ")
			print("  Frag Count: " .. fragCount)
			print("  Frag Mass: " .. round(fragMass * 1000, 2) .. " g")
			print("  Frag Speed: " .. round(fragSpeed) .. " m/s")
			--print("  Frag Volume: " .. round(fragVolume, 2) .. " mm^3")
			print("  Frag Caliber: " .. round(fragCaliber, 2) .. " mm")
			print("  Frag Penetration: " .. round(fragPen, 2) .. " mm")
			print("")

			debugoverlay.Sphere(origin, blastRadius, DEBUG_TIME, Color(255, 255, 255, 5))
		end

		while penetratedSomething do
			penetratedSomething = false

			for index, bogie in pairs(bogies) do
				if not isValidTarget(bogie) then
					bogies[index]       = nil
					filterCount         = filterCount + 1
					filter[filterCount] = bogie

					continue
				end

				-- Trace towards the bogie
				-- We'll target any entity that the trace hits so long as it's a valid target and has not been damaged already
				traceData.endpos = getRandomPos(bogie, bogie:IsPlayer() or bogie:IsNPC())

				local traceRes = doTrace(bogie)
				local ent      = traceRes.HitNonWorld and traceRes.Entity

				if ent and not damaged[ent] then
					debugoverlay.Line(origin, traceRes.HitPos, DEBUG_TIME, Color(255, 255, 255, 5))
					print("Target: " .. tostring(ent))

					damaged[ent] = true

					if ent == bogie then bogies[index] = nil end

					-- Project the targets shadow onto the blast sphere
					local targetPos     = ent:GetPos()
					local displacement  = targetPos - origin
					local distance      = displacement:Length()
					local sphereAtRange = 4 * 3.1415 * distance^2
					local circleArea    = ent.ACF.Area / 6.45 / 4 -- Surface area converted to a circle
					local shadowArea    = circleArea / sphereAtRange * blastSurfaceArea

					-- How much power goes to the target
					local areaFraction   = min(shadowArea / blastSurfaceArea, 0.5)
					local powerDelivered = blastPower * areaFraction

					-- Fragmentation damage
					local fragHits = round(fragCount * areaFraction)
					local fragRes

					if fragHits > 0 then
						print("    Frags hitting " .. fragHits)

						fakeBullet.ProjArea    = fragArea * fragHits
						fakeBullet.Mass        = fragMass * fragHits
						fakeBullet.Flight      = displacement:GetNormalized() * fragSpeed
						fakeBullet.penetration = fragPen * (1 - (distance / blastRadius) ^ 2)

						fragRes = doDamage(fakeBullet, traceRes)

					end

					-- Blast damage
					local blastRes

					-- target has not been killed by frag damage and we are delivering at least 0.5 KJ to the target
					-- ~0.5 KJ is a world-class punch or handgun shot
					if not (fragRes and fragRes.Kill) and powerDelivered > 0.5 then
						fakeBullet.ProjArea = ent.ACF.Area
					end

					-- Push on it
					doShove(ent, origin, displacement, powerDelivered)

					print("    Damage: " .. (blastRes and blastRes.Damage or 0) + (fragRes and fragRes.Damage or 0))
					-- Handle killed or penetrated targets
					local targetKilled     = (blastRes and blastRes.Kill) or (fragRes and fragRes.Kill)
					local targetPenetrated = (blastRes and blastRes.Overkill > 0) or (fragRes and fragRes.Overkill > 0)

					if targetKilled or targetPenetrated then
						print("    Target " .. (targetKilled and "killed" or "penetrated"))
						debugoverlay.BoxAngles(ent:GetPos(), ent:OBBMins(), ent:OBBMaxs(), ent:GetAngles(), DEBUG_TIME, DEBUG_RED)

						penetratedSomething = true
						filterCount         = filterCount + 1
						filter[filterCount] = ent

						if targetKilled then
							if fragRes and fragRes.Kill then
								doAPKill(ent, displacement, powerDelivered)
							else
								local debris = doHEKill(ent, displacement, powerDelivered, origin)

								for fireball in pairs(debris) do
									filterCount         = filterCount + 1
									filter[filterCount] = fireball
								end
							end
						end
					end
				end
			end
		end

		-- Explosion effect
		local effect = EffectData()
			effect:SetOrigin(origin)
			effect:SetNormal(Vector(0, 0, -1))
			effect:SetScale(max(explosiveMass ^ 0.33 * 8 * 39.37, 1))

		util.Effect("ACF_Explosion", effect)
	end

	local rounds = {
		["(155mm) M107 HE"] = {
			mass = 43.2, -- kg
			filler = 6.86, -- tnt
		}
		["(76mm) M42A1 HE"] = {
			mass = 5.84,
			filler = 0.39
		},
		["(40mm) L/60 Bofors HE-T"] = {
			mass = 0.93,
			filler = 0.092,
		},
		["(??) M67 Hand Grenade"] = {
			mass = 0.4,
			filler = 0.18,
		}
	}

	function ACF.testHE()
		for name, data in pairs(rounds) do
			print(name)
			ACF.HE(eye().HitPos, data.filler, data.mass - data.filler, me(), {me()}, me())
		end
	end
end
]]
