local ACF       = ACF
local Network   = ACF.Networking
local Damaged   = {}
local Materials = {
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

local RenderDamage
do
	local EyePos = EyePos
	local EyeAngles = EyeAngles
	local cam_End3D = cam.End3D
	local cam_Start3D = cam.Start3D
	local render_SetBlend = render.SetBlend
	local render_ModelMaterialOverride = render.ModelMaterialOverride

	RenderDamage = function(bDrawingDepth, _, isDraw3DSkybox)
		if bDrawingDepth or isDraw3DSkybox then return end
		cam_Start3D(EyePos(), EyeAngles())

		for Entity, EntityTable in pairs(Damaged) do
			if IsValid(Entity) then
				render_ModelMaterialOverride(EntityTable.ACF_Material)
				render_SetBlend(EntityTable.ACF_BlendAmount)

				Entity:DrawModel()
			end
		end

		render_ModelMaterialOverride()
		render_SetBlend(1)
		cam_End3D()
	end
end

local function Remove(Entity)
	Entity:RemoveCallOnRemove("ACF_RenderDamage")

	Damaged[Entity] = nil

	if not next(Damaged) then
		hook.Remove("PostDrawOpaqueRenderables", "ACF_RenderDamage")
	end
end

local function Add(Entity)
	if not next(Damaged) then
		hook.Add("PostDrawOpaqueRenderables", "ACF_RenderDamage", RenderDamage)
	end

	Damaged[Entity] = Entity:GetTable()

	Entity:CallOnRemove("ACF_RenderDamage", function()
		Remove(Entity)
	end)
end

do
	local IsValid = IsValid
	local math_Clamp = math.Clamp

	Network.CreateReceiver("ACF_Damage", function(Data)
		for Index, Percent in pairs(Data) do
			local Entity = ents.GetByIndex(Index)

			if not IsValid(Entity) then continue end

			if Percent < 1 then
				Entity.ACF_HealthPercent = Percent
				Entity.ACF_BlendAmount = math_Clamp(1 - Percent, 0, 0.8)

				if Percent > 0.7 then
					Entity.ACF_Material = Materials[1]
				elseif Percent > 0.3 then
					Entity.ACF_Material = Materials[2]
				else
					Entity.ACF_Material = Materials[3]
				end

				Add(Entity)
			else
				Remove(Entity)

				Entity.ACF_HealthPercent = nil
				Entity.ACF_Material      = nil
				Entity.ACF_BlendAmount   = nil
			end
		end
	end)
end

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
		Entity:CallOnRemove("ACF_Debris_Fade", function()
			Entity:StopAndDestroyParticles()
		end)

		if IsValid(Smoke) then Smoke:StopEmission() end
		if IsValid(Ember) then Ember:StopEmission() end

		timer.Simple(5, function()
			if not IsValid(Entity) then return end

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
