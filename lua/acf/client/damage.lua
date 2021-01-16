local ACF = ACF
local Damaged = {
	CreateMaterial("ACF_Damaged1", "VertexLitGeneric", {
		["$basetexture"] = "damaged/damaged1"
	}),
	CreateMaterial("ACF_Damaged2", "VertexLitGeneric", {
		["$basetexture"] = "damaged/damaged2"
	}),
	CreateMaterial("ACF_Damaged3", "VertexLitGeneric", {
		["$basetexture"] = "damaged/damaged3"
	})
}

hook.Add("PostDrawOpaqueRenderables", "ACF_RenderDamage", function()
	if not ACF_HealthRenderList then return end
	cam.Start3D(EyePos(), EyeAngles())

	for k, ent in pairs(ACF_HealthRenderList) do
		if IsValid(ent) then
			render.ModelMaterialOverride(ent.ACF_Material)
			render.SetBlend(math.Clamp(1 - ent.ACF_HealthPercent, 0, 0.8))
			ent:DrawModel()
		elseif ACF_HealthRenderList then
			table.remove(ACF_HealthRenderList, k)
		end
	end

	render.ModelMaterialOverride()
	render.SetBlend(1)
	cam.End3D()
end)

net.Receive("ACF_RenderDamage", function()
	local Table = net.ReadTable()

	for _, v in ipairs(Table) do
		local ent, Health, MaxHealth = ents.GetByIndex(v.ID), v.Health, v.MaxHealth
		if not IsValid(ent) then return end

		if Health ~= MaxHealth then
			ent.ACF_Health = Health
			ent.ACF_MaxHealth = MaxHealth
			ent.ACF_HealthPercent = Health / MaxHealth

			if ent.ACF_HealthPercent > 0.7 then
				ent.ACF_Material = Damaged[1]
			elseif ent.ACF_HealthPercent > 0.3 then
				ent.ACF_Material = Damaged[2]
			elseif ent.ACF_HealthPercent <= 0.3 then
				ent.ACF_Material = Damaged[3]
			end

			ACF_HealthRenderList = ACF_HealthRenderList or {}
			ACF_HealthRenderList[ent:EntIndex()] = ent
		else
			if ACF_HealthRenderList then
				if #ACF_HealthRenderList <= 1 then
					ACF_HealthRenderList = nil
				else
					table.remove(ACF_HealthRenderList, ent:EntIndex())
				end

				if ent.ACF then
					ent.ACF.Health = nil
					ent.ACF.MaxHealth = nil
				end
			end
		end
	end
end)

do -- Debris Effects ------------------------
	local AllowDebris = GetConVar("acf_debris")
	local CollideAll  = GetConVar("acf_debris_collision")
	local DebrisLife  = GetConVar("acf_debris_lifetime")
	local GibMult     = GetConVar("acf_debris_gibmultiplier")
	local GibLife     = GetConVar("acf_debris_giblifetime")
	local GibModel    = "models/gibs/metal_gib%s.mdl"

	local function Particle(Entity, Effect)
		return CreateParticleSystem(Entity, Effect, PATTACH_ABSORIGIN_FOLLOW)
	end

	local function FadeAway(Entity)
		if not IsValid(Entity) then return end

		local Smoke = Entity.SmokeParticle
		local Ember = Entity.EmberParticle

		Entity:SetRenderMode(RENDERMODE_TRANSCOLOR)
		Entity:SetRenderFX(kRenderFxFadeSlow) -- NOTE: Not synced to CurTime()

		if Smoke then Smoke:StopEmission() end
		if Ember then Ember:StopEmission() end

		timer.Simple(5, function()
			Entity:StopAndDestroyParticles()
			Entity:Remove()
		end)
	end

	local function Ignite(Entity, Lifetime, IsGib)
		if IsGib then
			Particle(Entity, "burning_gib_01")

			timer.Simple(Lifetime * 0.2, function()
				if not IsValid(Entity) then return end

				Entity:StopParticlesNamed("burning_gib_01")
			end)
		else
			Entity.SmokeParticle = Particle(Entity, "smoke_small_01b")

			Particle(Entity, "env_fire_small_smoke")

			timer.Simple(Lifetime * 0.4, function()
				if not IsValid(Entity) then return end

				Entity:StopParticlesNamed("env_fire_small_smoke")
			end)
		end
	end

	local function CreateDebris(Data)
		local Debris = ents.CreateClientProp(Data.Model)

		if not IsValid(Debris) then return end

		local Lifetime = DebrisLife:GetFloat() * math.Rand(0.5, 1)

		Debris:SetPos(Data.Position)
		Debris:SetAngles(Data.Angles)
		Debris:SetColor(Data.Color)
		Debris:SetMaterial(Data.Material)

		if not CollideAll:GetBool() then
			Debris:SetCollisionGroup(COLLISION_GROUP_WORLD)
		end

		Debris:Spawn()

		Debris.EmberParticle = Particle(Debris, "embers_medium_01")

		if Data.Ignite and math.Rand(0, 0.5) < ACF.DebrisIgniteChance then
			Ignite(Debris, Lifetime)
		else
			Debris.SmokeParticle = Particle(Debris, "smoke_exhaust_01a")
		end

		local PhysObj = Debris:GetPhysicsObject()

		if IsValid(PhysObj) then
			PhysObj:ApplyForceOffset(Data.Normal * Data.Power, Data.Position + VectorRand() * 20)
		end

		timer.Simple(Lifetime, function()
			FadeAway(Debris)
		end)

		return Debris
	end

	local function CreateGib(Data, Min, Max)
		local Gib = ents.CreateClientProp(GibModel:format(math.random(1, 5)))

		if not IsValid(Gib) then return end

		local Lifetime = GibLife:GetFloat() * math.Rand(0.5, 1)
		local Offset   = ACF.RandomVector(Min, Max)

		Offset:Rotate(Data.Angles)

		Gib:SetPos(Data.Position + Offset)
		Gib:SetAngles(AngleRand(-180, 180))
		Gib:SetModelScale(math.Rand(0.5, 2))
		Gib:SetMaterial(Data.Material)
		Gib:SetColor(Data.Color)
		Gib:Spawn()

		Gib.SmokeParticle = Particle(Gib, "smoke_gib_01")

		if math.random() < ACF.DebrisIgniteChance then
			Ignite(Gib, Lifetime, true)
		end

		local PhysObj = Gib:GetPhysicsObject()

		if IsValid(PhysObj) then
			PhysObj:ApplyForceOffset(Data.Normal * Data.Power, Gib:GetPos() + VectorRand() * 20)
		end

		timer.Simple(Lifetime, function()
			FadeAway(Gib)
		end)

		return true
	end

	net.Receive("ACF_Debris", function()
		local Data = util.JSONToTable(net.ReadString())

		if not AllowDebris:GetBool() then return end

		local Debris = CreateDebris(Data)

		if IsValid(Debris) then
			local Multiplier = GibMult:GetFloat()
			local Radius     = Debris:BoundingRadius()
			local Min        = Debris:OBBMins()
			local Max        = Debris:OBBMaxs()

			if Data.CanGib and Multiplier > 0 then
				local GibCount = math.Clamp(Radius * 0.1, 1, math.max(10 * Multiplier, 1))

				for _ = 1, GibCount do
					if not CreateGib(Data, Min, Max) then
						break
					end
				end
			end
		end

		local Effect = EffectData()
			Effect:SetOrigin(Data.Position) -- TODO: Change this to the hit vector, but we need to redefine HitVec as HitNorm
			Effect:SetScale(20)
		util.Effect("cball_explode", Effect)
	end)

	game.AddParticles("particles/fire_01.pcf")

	PrecacheParticleSystem("burning_gib_01")
	PrecacheParticleSystem("env_fire_small_smoke")
	PrecacheParticleSystem("smoke_gib_01")
	PrecacheParticleSystem("smoke_exhaust_01a")
	PrecacheParticleSystem("smoke_small_01b")
	PrecacheParticleSystem("embers_medium_01")
end -----------------------------------------