local hook = hook
local util = util
local ACF  = ACF

ACF.Squishies = ACF.Squishies or {}

local Squishies = ACF.Squishies


-- InVehicle and GetVehicle are only for players, we have NPCs too!
local function GetVehicle(Entity)
	if not IsValid(Entity) then return end

	local Parent = Entity:GetParent()

	if not Parent:IsVehicle() then return end

	return Parent
end

local function CanSee(Target, Data)
	local R = ACF.trace(Data)

	return R.Entity == Target or not R.Hit or R.Entity == GetVehicle(Target)
end

function ACF.Overpressure(Origin, Energy, Inflictor, Source, Forward, Angle)
	local Radius = Energy ^ 0.33 * 0.025 * 39.37 -- Radius in meters (Completely arbitrary stuff, scaled to have 120s have a radius of about 20m)
	local Data = { start = Origin, endpos = true, mask = MASK_SHOT }

	if Source then -- Filter out guns
		if Source.BarrelFilter then
			Data.filter = {}

			for K, V in pairs(Source.BarrelFilter) do Data.filter[K] = V end -- Quick copy of gun barrel filter
		else
			Data.filter = { Source }
		end
	end

	util.ScreenShake(Origin, Energy, 1, 0.25, Radius * 3 * 39.37 )

	if Forward and Angle then -- Blast direction and angle are specified
		Angle = math.rad(Angle * 0.5) -- Convert deg to rads

		for V in pairs(Squishies) do
			local Position = V:EyePos()

			if math.acos(Forward:Dot((Position - Origin):GetNormalized())) < Angle then
				local D = Position:Distance(Origin)

				if D / 39.37 <= Radius then

					Data.endpos = Position + VectorRand() * 5

					if CanSee(V, Data) then
						local Damage = Energy * 175000 * (1 / D^3)

						V:TakeDamage(Damage, Inflictor, Source)
					end
				end
			end
		end
	else -- Spherical blast
		for V in pairs(Squishies) do
			local Position = V:EyePos()

			if CanSee(Origin, V) then
				local D = Position:Distance(Origin)

				if D / 39.37 <= Radius then

					Data.endpos = Position + VectorRand() * 5

					if CanSee(V, Data) then
						local Damage = Energy * 150000 * (1 / D^3)

						V:TakeDamage(Damage, Inflictor, Source)
					end
				end
			end
		end
	end
end

hook.Add("PlayerSpawnedNPC", "ACF Squishies", function(_, Ent)
	Squishies[Ent] = true
end)

hook.Add("OnNPCKilled", "ACF Squishies", function(Ent)
	Squishies[Ent] = nil
end)

hook.Add("PlayerSpawn", "ACF Squishies", function(Ent)
	Squishies[Ent] = true
end)

hook.Add("PostPlayerDeath", "ACF Squishies", function(Ent)
	Squishies[Ent] = nil
end)

hook.Add("EntityRemoved", "ACF Squishies", function(Ent)
	Squishies[Ent] = nil
end)
