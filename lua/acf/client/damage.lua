local RandFloat = math.Rand
local RandInt = math.random
local Clamp = math.Clamp
local MathMax = math.max

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

-- Debris & Burning Debris Effects --

game.AddParticles("particles/fire_01.pcf")
PrecacheParticleSystem("burning_gib_01")
PrecacheParticleSystem("env_fire_small_smoke")
PrecacheParticleSystem("smoke_gib_01")
PrecacheParticleSystem("smoke_exhaust_01a")
PrecacheParticleSystem("smoke_small_01b")
PrecacheParticleSystem("embers_medium_01")

local function Particle(Entity, pEffect)
	return CreateParticleSystem(Entity, pEffect, PATTACH_ABSORIGIN_FOLLOW)
end

local DebrisMasterCVar = CreateClientConVar("acf_debris", "1", true, false,
	"Toggles ACF Debris."
)
local CollisionCVar = CreateClientConVar("acf_debris_collision", "0", true, false,
	"Toggles whether debris created by ACF collides with objects. Disabling can prevent certain types of spam-induced lag & crashes."
)
local GibCVar = CreateClientConVar("acf_debris_gibmultiplier", "1", true, false,
	"The amount of gibs spawned when created by ACF debris."
)
local GibSizeCVar = CreateClientConVar("acf_debris_gibsize", "1", true, false,
	"The size of the gibs created by ACF debris."
)
local CVarGibLife = CreateClientConVar("acf_debris_giblifetime", "60", true, false,
	"How long a gib will live in the world before fading. Default 30 to 60 seconds."
)
local CVarDebrisLife = CreateClientConVar("acf_debris_lifetime", "60", true, false,
	"How long solid debris will live in the world before fading. Default 30 to 60 seconds."
)

local function RandomPos( vecMin, vecMax )
	randomX = RandFloat(vecMin.x, vecMax.x)
	randomY = RandFloat(vecMin.y, vecMax.y)
	randomZ = RandFloat(vecMin.z, vecMax.z)
	return Vector(randomX, randomY, randomZ)
end

local function FadeAway( Ent ) -- local function Entity:FadeAway() is incorrect syntax????????? Am I referencing a hook somehow?
	if not IsValid(Ent) then return end
	Ent:SetRenderMode(RENDERMODE_TRANSCOLOR)
	Ent:SetRenderFX(kRenderFxFadeSlow) -- interestingly, not synced to CurTime().
	local Smk, Emb = Ent.ACFSmokeParticle, Ent.ACFEmberParticle
	if Smk then Smk:StopEmission() end
	if Emb then Emb:StopEmission() end
	timer.Simple(5, function() Ent:StopAndDestroyParticles() Ent:Remove() end)
end

local function IgniteCL( Ent, Lifetime, Gib ) -- Lifetime describes fire life, smoke lasts until the entity is removed.
	if Gib then
		Particle(Ent, "burning_gib_01")
		timer.Simple(Lifetime * 0.2, function()
			if IsValid(Ent) then
				Ent:StopParticlesNamed("burning_gib_01")
			end
		end)
	else
		Particle(Ent, "env_fire_small_smoke")
		Ent.ACFSmokeParticle = Particle(Ent, "smoke_small_01b")
		timer.Simple(Lifetime * 0.4, function()
			if IsValid(Ent) then
				Ent:StopParticlesNamed("env_fire_small_smoke")
			end
		end)
	end
end

net.Receive("ACF_Debris", function()

	if DebrisMasterCVar:GetInt() < 1 then return end

	local HitVec = net.ReadVector()
	local Power = net.ReadFloat()
	local Mass = net.ReadFloat()
	local Mdl = net.ReadString()
	local Mat = net.ReadString()
	local Col = net.ReadColor()
	local Pos = net.ReadVector()
	local Ang = net.ReadAngle()
	local WillGib = net.ReadFloat()
	local WillIgnite = net.ReadFloat()

	local Min, Max = Vector(), Vector()
	local Radius = 1

	local Debris = ents.CreateClientProp(Mdl)
		Debris:SetPos(Pos)
		Debris:SetAngles(Ang)
		Debris:SetColor(Col)
		if Mat then Debris:SetMaterial(Mat) end
		if CollisionCVar:GetInt() < 1 then Debris:SetCollisionGroup(COLLISION_GROUP_WORLD) end
	Debris:Spawn()
	local DebrisLifetime = RandFloat(0.5, 1) * MathMax(CVarDebrisLife:GetFloat(), 1)
	timer.Simple(DebrisLifetime, function() FadeAway(Debris) end)

	if IsValid(Debris) then

		Min, Max = Debris:OBBMins(), Debris:OBBMaxs() --for gibs
		Radius = Debris:BoundingRadius()

		Debris.ACFEmberParticle = Particle(Debris, "embers_medium_01")
		if WillIgnite > 0 and RandFloat(0, 1) * 0.2 < ACF.DebrisIgniteChance then
			IgniteCL(Debris, DebrisLifetime, false)
		else
			Debris.ACFSmokeParticle = Particle(Debris, "smoke_exhaust_01a")
		end
		-- Debris (not gibs) has a 5 times higher chance of igniting since we're already saying that the debris will ignite.

		local Phys = Debris:GetPhysicsObject()
		if IsValid(Phys) then
			Phys:SetMass(Mass * 0.1)
			Phys:ApplyForceOffset(HitVec:GetNormalized() * Power * 70, Debris:GetPos() + VectorRand() * 20)
		end

	end

	if WillGib > 0 and GibCVar:GetFloat() > 0 then
		local GibCount = Clamp(Radius * 0.05, 1, MathMax(20 * GibCVar:GetFloat(), 1))
		for _ = 1, GibCount do -- should we base this on prop volume?

			local Gib = ents.CreateClientProp("models/gibs/metal_gib" .. RandInt(1,5) .. ".mdl")
				if not IsValid(Gib) then break end -- we probably hit edict limit, stop looping
				local RandomBox = RandomPos(Min, Max)
				RandomBox:Rotate(Ang)
				Gib:SetPos(Pos + RandomBox)
				Gib:SetAngles(AngleRand(-180,180))
				Gib:SetModelScale(Clamp(Radius * 0.01 * GibSizeCVar:GetFloat(), 1, 20))
				Gib.ACFSmokeParticle = Particle(Gib, "smoke_gib_01")
			Gib:Spawn()
			Gib:Activate()

			local GibLifetime = RandFloat(0.5, 1) * MathMax(CVarGibLife:GetFloat(), 1)
			timer.Simple(GibLifetime, function() FadeAway(Gib) end)
			if RandFloat(0,1) < ACF.DebrisIgniteChance then IgniteCL(Gib, GibLifetime, true) end -- Gibs always ignite but still follow IgniteChance

			local GibPhys = Gib:GetPhysicsObject()
			GibPhys:ApplyForceOffset(HitVec:GetNormalized() * Power, GibPhys:GetPos() + VectorRand() * 20)

		end
	end

	local BreakEffect = EffectData()
		BreakEffect:SetOrigin(Pos) -- TODO: Change this to the hit vector, but we need to redefine HitVec as HitNorm
		BreakEffect:SetScale(20)
	util.Effect("cball_explode", BreakEffect)

end)