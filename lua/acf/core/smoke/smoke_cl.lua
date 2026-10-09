local ACF = ACF
ACF.SmokeClouds = ACF.SmokeClouds or {}

local Clouds      = ACF.SmokeClouds
local DebugCol    = Color(255, 0, 255)
local Developer
local FadeShare   = 0.15 -- Last portion of a cloud's life spent fading out
local Burster     = 0.05 -- Share of the filler mass used to size the purely visual burst explosion
local GoldenAng   = math.pi * (3 - math.sqrt(5))
-- Fractions of the cloud radius. Sprites only visibly fill about half their size, so a central core plus an
-- evenly spaced shell of overlapping sprites covers the whole sphere
local CoreSize    = 1.3
local ShellSize   = 0.9
local ShellOffset = 0.55
local ShellCount  = 24 -- Over a full sphere, grounded clouds use half as many over their upper hemisphere
local Sprites     = {
	"particle/smokesprites_0001",
	"particle/smokesprites_0002",
	"particle/smokesprites_0003",
	"particle/smokesprites_0004",
	"particle/smokesprites_0005",
	"particle/smokesprites_0006",
	"particle/smokesprites_0008"
}

-- Seeded by cloud ID so every client builds the same layout
local function Random(Cloud, Key, Min, Max)
	return util.SharedRandom("ACF_Smoke" .. Key, Min, Max, Cloud.ID)
end

-- Golden angle spiral, so shell sprites are evenly spread no matter how many there are
local function GetShellDirections(Cloud)
	local Axis   = Cloud.Grounded and Cloud.Normal or vector_up
	local Basis  = Axis:Angle()
	local SideA  = Basis:Right()
	local SideB  = Basis:Up()
	local Phase  = Random(Cloud, "Phase", 0, math.pi * 2)
	local Count  = Cloud.Grounded and ShellCount / 2 or ShellCount
	local Result = {}

	for I = 0, Count - 1 do
		-- Grounded clouds keep their particles above the surface they landed on
		local Z     = Cloud.Grounded and 1 - (I + 0.5) / Count or 1 - (2 * I + 1) / Count
		local Ring  = math.sqrt(1 - Z * Z)
		local Theta = I * GoldenAng + Phase

		Result[I + 1] = Axis * Z + SideA * (Ring * math.cos(Theta)) + SideB * (Ring * math.sin(Theta))
	end

	return Result
end

-- Follows the cloud every frame while it bursts out and coasts, then hands off to constant velocity and linear
-- growth so the engine moves it. After that it only thinks once to stop sinking when landed, and once to hand
-- the fade out to the engine
local function GetParticleThink(Cloud, Dir, Offset, Size, Alpha)
	local Start       = Cloud.Start
	local DeployAt    = Start + Cloud.Deploy
	local FollowUntil = Cloud.Grounded and DeployAt or math.max(DeployAt, Start + ACF.SmokeCarryTime)
	local LandTime    = ACF.GetSmokeLandTime(Cloud)
	local LandAt      = LandTime and Start + LandTime
	local DieAt       = Start + Cloud.Life
	local FadeTime    = Cloud.Life * FadeShare
	local FadeStart   = DieAt - FadeTime
	local Growth      = (Cloud.MaxRadius - Cloud.MinRadius) / (Cloud.Life - Cloud.Deploy)
	local HandedOff   = false
	local Falling     = false
	local Fading      = false

	local function SetMotion(Particle, Now)
		local Center, Radius = ACF.GetSmokeCloudState(Cloud, Now)
		local Velocity       = Cloud.Drift + Dir * Offset * Growth

		if Falling then Velocity.z = Velocity.z - ACF.SmokeFallRate end

		Particle:SetPos(Center + Dir * Offset * Radius)
		Particle:SetVelocity(Velocity)
	end

	return function(Particle)
		local Now = CurTime()

		if Now < FollowUntil then
			local Center, Radius = ACF.GetSmokeCloudState(Cloud, Now)

			Particle:SetPos(Center + Dir * Offset * Radius)
			Particle:SetStartSize(Size * Radius)
			Particle:SetEndSize(Size * Radius)
			Particle:SetNextThink(Now)

			return
		end

		if not HandedOff then
			HandedOff = true
			Falling   = LandAt ~= nil and Now < LandAt

			-- Lifetime is rebased to the end of the burst so the engine's size lerp matches the linear growth
			Particle:SetLifeTime(Now - DeployAt)
			Particle:SetDieTime(DieAt - DeployAt)
			Particle:SetStartSize(Size * Cloud.MinRadius)
			Particle:SetEndSize(Size * Cloud.MaxRadius)

			SetMotion(Particle, Now)
		end

		if Falling and Now >= LandAt then
			Falling = false

			SetMotion(Particle, Now)
		end

		if not Fading and Now >= FadeStart then
			local _, Radius = ACF.GetSmokeCloudState(Cloud, Now)
			local Remaining = DieAt - Now

			Fading = true

			-- Lifetime is rebased again so the engine lerps alpha down to zero while size keeps growing linearly
			Particle:SetLifeTime(0)
			Particle:SetDieTime(Remaining)
			Particle:SetStartAlpha(Alpha * math.Clamp(Remaining / FadeTime, 0, 1))
			Particle:SetEndAlpha(0)
			Particle:SetStartSize(Size * Radius)
			Particle:SetEndSize(Size * Cloud.MaxRadius)
		end

		local Next = Fading and DieAt + 1 or FadeStart -- Past its death once nothing is left to do

		if Falling then Next = math.min(Next, LandAt) end

		Particle:SetNextThink(Next)
	end
end

local function CreateParticles(Cloud)
	local Now     = CurTime()
	local Elapsed = Now - Cloud.Start
	local Life    = Cloud.Life

	if Elapsed >= Life then return end

	local Emitter = ParticleEmitter(Cloud.Center)

	if not IsValid(Emitter) then return end

	local Center, Radius = ACF.GetSmokeCloudState(Cloud, Now)
	local Layout = { { Dir = vector_origin, Offset = 0, Size = CoreSize } }

	for _, Dir in ipairs(GetShellDirections(Cloud)) do
		Layout[#Layout + 1] = { Dir = Dir, Offset = ShellOffset, Size = ShellSize }
	end

	for I, Entry in ipairs(Layout) do
		local Dir    = Entry.Dir
		local Offset = Entry.Offset + Random(Cloud, "O" .. I, -0.05, 0.05)
		local Size   = Entry.Size * Random(Cloud, "S" .. I, 0.95, 1.05)
		local Alpha  = Random(Cloud, "A" .. I, 200, 255)
		local Smoke  = Emitter:Add(Sprites[math.floor(Random(Cloud, "M" .. I, 1, #Sprites + 0.999))], Center + Dir * Offset * Radius)

		if not Smoke then continue end

		local Think = GetParticleThink(Cloud, Dir, Offset, Size, Alpha)

		Smoke:SetLifeTime(Elapsed)
		Smoke:SetDieTime(Life)
		Smoke:SetStartAlpha(Alpha)
		Smoke:SetEndAlpha(Alpha)
		Smoke:SetStartSize(Size * Radius)
		Smoke:SetEndSize(Size * Radius)
		Smoke:SetRoll(Random(Cloud, "R" .. I, 0, 360))
		Smoke:SetRollDelta(Random(Cloud, "D" .. I, -0.2, 0.2))
		Smoke:SetAirResistance(0)
		Smoke:SetGravity(vector_origin)
		Smoke:SetCollide(false)
		Smoke:SetColor(Cloud.Color.r, Cloud.Color.g, Cloud.Color.b)
		Smoke:SetThinkFunction(Think)

		Think(Smoke)
	end

	Emitter:Finish()
end

local function CreateBurst(Origin, Mass)
	local Sparks = math.Clamp(Mass * 2, 1, 8)

	ACF.Damage.explosionEffect(Origin, nil, Mass * Burster)
	ACF.Utilities.Effects.CreateEffect("Sparks", {
		Origin    = Origin,
		Normal    = vector_up,
		Magnitude = Sparks,
		Radius    = Sparks,
		Scale     = Sparks,
	})
end

net.Receive("ACF_SmokeImpact", function()
	-- Read in order, table constructor fields have no guaranteed evaluation order
	local ID         = net.ReadUInt(15)
	local Burst      = net.ReadBool()
	local Origin     = net.ReadVector()
	local Start      = net.ReadFloat()
	local Color      = net.ReadColor(false)
	local FillerMass = net.ReadBool() and net.ReadFloat() or 0
	local WPMass     = net.ReadBool() and net.ReadFloat() or 0
	local Base       = {
		Origin   = Origin,
		Start    = Start,
		Color    = Color,
		Grounded = net.ReadBool(),
		Center   = Origin,
		Normal   = vector_up,
		Carry    = Vector(),
		FloorZ   = Origin.z,
	}

	if Base.Grounded then
		Base.Center = Origin - vector_up * net.ReadUInt(5)
		Base.Normal = net.ReadNormal()
	else
		if net.ReadBool() then Base.Carry = net.ReadVector() end

		Base.FloorZ = net.ReadFloat()
	end

	for _, Cloud in ipairs(ACF.AddSmokeClouds(ID, Base, FillerMass, WPMass)) do
		CreateParticles(Cloud)
	end

	if Burst then CreateBurst(Origin, FillerMass + WPMass) end
end)

-- Draws each cloud's blocking sphere while it blocks, for acf_developer modes that include the client
hook.Add("PostDrawTranslucentRenderables", "ACF Smoke Debug", function(_, Skybox)
	if Skybox or not next(Clouds) then return end

	Developer = Developer or GetConVar("acf_developer")

	local Mode = Developer and Developer:GetInt() or 0

	if Mode ~= 1 and Mode ~= 3 then return end

	local Time = CurTime()

	for _, Cloud in pairs(Clouds) do
		if not ACF.IsSmokeCloudBlocking(Cloud, Time) then continue end

		local Center, Radius = ACF.GetSmokeCloudState(Cloud, Time)

		render.DrawWireframeSphere(Center, Radius, 16, 16, DebugCol, true)
	end
end)
