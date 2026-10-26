local ACF = ACF
ACF.SmokeClouds = ACF.SmokeClouds or {}

local Clouds    = ACF.SmokeClouds
local Effects   = ACF.Utilities.Effects
local DebugCol  = Color(255, 0, 255)
local Up        = Vector(0, 0, 1)
local Developer
local Burster   = 0.05 -- Share of the filler mass used to size the purely visual burst explosion
local LateAfter = 0.25 -- Clouds older than this when they reach us are created already bloomed
local Pull      = 1e6 -- Strength of the drift pull, must match PULL in the particle system's generator
local MaxPull   = 1e9 -- Distance to the drift target of clouds that don't drift, far enough to do nothing
local Systems   = { Smoke = "acf_smoke", WP = "acf_smoke_wp" }
-- White phosphorus streamers: how many (acf_smoke_wp_streak0 and up, each its own shape), how far the pellets would fly
-- with no gravity (bloom radii), their drag (1/s), gravity, flight time, share of the cloud's carried velocity they keep
-- and the lowest they're thrown (degrees above the surface for grounded bursts, the horizon for airbursts)
local Streaks       = 24
local StreakReach   = 2.6
local StreakDrag    = 2.2
local StreakGravity = 1100
local StreakTime    = 1.5
local StreakInherit = 1
local StreakLow     = { Ground = 3, Air = -60 }
local StreakHigh    = 88

local function GetSurfaceAngles(Normal)
	local Side = math.abs(Normal.z) < 0.9 and Up or Vector(1, 0, 0)

	return Side:Cross(Normal):GetNormalized():AngleEx(Normal)
end

-- White phosphorus throws burning pellets out in a starburst, each leaving a trail that arcs from the burst to where its
-- pellet ends up, bowed toward the way it was thrown. Every trail is its own effect placed in its middle, so it's drawn
-- in front of or behind the cloud depending on where it is, the cloud being one effect too
local function CreateStreamers(Cloud, Center, Angles, Tint, Target)
	local Phase = math.Rand(0, 360)
	local Floor = (Cloud.Grounded and Cloud.Center.z or Cloud.FloorZ) + 4
	local Low   = StreakLow[Cloud.Grounded and "Ground" or "Air"]
	local Carry = Cloud.Carry * StreakInherit
	local Size  = Vector(Cloud.BloomRadius, 0, 0)
	local Shape = {}

	for I = 1, Streaks do Shape[I] = I - 1 end

	table.Shuffle(Shape)

	for I = 1, Streaks do
		-- Most are thrown in a fountain, a few skim low or go almost straight up
		local Elevation = Low + (StreakHigh - Low) * math.Rand(0, 1) ^ 0.8
		local Yaw       = Phase + (I + math.Rand(-0.5, 0.5)) * 360 / Streaks
		local _, Throw  = LocalToWorld(vector_origin, Angle(-Elevation, Yaw, 0), vector_origin, Angles)
		local Drag      = StreakDrag * math.Rand(0.6, 1.3) -- Pellets of all sizes, the big ones fly far and high
		local Velocity  = Throw:Forward() * (Cloud.BloomRadius * StreakReach * StreakDrag * math.Rand(0.4, 1.4)) + Carry
		local Time      = StreakTime

		-- Where the pellet is after Time seconds of drag and gravity
		local function Flight(At)
			local Spent = (1 - math.exp(-Drag * At)) / Drag

			return Center + Velocity * Spent - Up * (StreakGravity * (At - Spent) / Drag)
		end

		-- Pellets that would fall through the ground stop where they reach it, halving in on the moment they do
		if Flight(Time).z < Floor then
			local Before, After = 0, Time

			for _ = 1, 8 do
				Time = (Before + After) * 0.5

				if Flight(Time).z < Floor then After = Time else Before = Time end
			end

			Time = Before
		end

		local End    = Flight(Time)
		local Length = End:Distance(Center)

		if Length < 1 then continue end

		local Chord = (End - Center) / Length
		local Bow   = Velocity - Chord * Velocity:Dot(Chord)

		Bow = Bow:LengthSqr() > 1e-4 and Bow:GetNormalized() or Up

		local Axis   = Bow:Angle()
		local Effect = CreateParticleSystemNoEntity("acf_smoke_wp_streak" .. Shape[I], (Center + End) * 0.5 + Bow * (Length * 0.15))

		if not Effect then continue end

		Effect:SetControlPoint(1, Center)
		Effect:SetControlPoint(2, End)
		Effect:SetControlPointOrientation(2, Axis:Forward(), Axis:Right(), Axis:Up())
		Effect:SetControlPoint(3, Tint)
		Effect:SetControlPoint(4, Size)
		Effect:SetControlPoint(5, Target)
	end
end

-- The particles reproduce ACF.GetSmokeCloudState on their own: control points set once here are all they need
local function CreateCloudEffect(Cloud)
	local Now     = CurTime()
	local Elapsed = Now - Cloud.Start
	local Life    = Cloud.Life - Elapsed

	if Life <= 0 then return end

	local Late           = Elapsed > LateAfter
	local Center, Radius = ACF.GetSmokeCloudState(Cloud, Now)
	local Name           = Systems[Cloud.Type] .. (Cloud.Grounded and "_ground" or "_air") .. (Late and "_late" or "")
	local Angles         = Cloud.Grounded and GetSurfaceAngles(Cloud.Normal) or angle_zero
	local Effect         = CreateParticleSystemNoEntity(Name, Center, Angles)

	if not Effect then return end

	local Settle = Cloud.Settle
	local Drift  = Cloud.Drift
	local Speed  = Drift:Length()
	-- A falloff 1 pull accelerates by Pull / distance, under drag that settles at the drift speed
	local Target = Speed > 0.01 and Center + Drift / Speed * math.min(Pull * Settle / Speed, MaxPull) or Center + Up * MaxPull
	local Carry  = Late and vector_origin or Cloud.Carry * math.exp(-Elapsed / Settle)
	local Burst  = Cloud.BloomRadius / Settle -- Radial speed that settles out at the bloom radius
	local Tint   = Effects.GetLitColor(Cloud.Color, Center + Up * 32)

	Effect:SetControlPoint(1, Late and Vector(Radius, 0, 0) or Vector(Cloud.BloomRadius, Burst, Burst))
	Effect:SetControlPoint(2, Vector(Life, 1, 0))
	Effect:SetControlPoint(3, Tint)
	Effect:SetControlPoint(4, Carry)
	Effect:SetControlPoint(5, Target)

	if Cloud.Type == "WP" and not Late then
		CreateStreamers(Cloud, Center, Angles, Tint, Target)
	end
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
	local Carry      = net.ReadBool() and net.ReadVector() or Vector()
	local Base       = {
		Origin   = Origin,
		Start    = Start,
		Color    = Color,
		Grounded = net.ReadBool(),
		Center   = Origin,
		Normal   = vector_up,
		Carry    = Carry,
		FloorZ   = Origin.z,
	}

	if Base.Grounded then
		Base.Center = Origin - vector_up * net.ReadUInt(5)
		Base.Normal = net.ReadNormal()
	else
		Base.FloorZ = net.ReadFloat()
	end

	for _, Cloud in ipairs(ACF.AddSmokeClouds(ID, Base, FillerMass, WPMass)) do
		CreateCloudEffect(Cloud)
	end

	if Burst then CreateBurst(Origin, FillerMass + WPMass) end
end)

-- Draws each cloud's blocking sphere while it blocks, when acf_developer is above 0
hook.Add("PostDrawTranslucentRenderables", "ACF Smoke Debug", function(_, Skybox)
	if Skybox or not next(Clouds) then return end

	Developer = Developer or GetConVar("acf_developer")

	local Mode = Developer and Developer:GetInt() or 0

	if Mode < 1 then return end

	local Time = CurTime()

	for _, Cloud in pairs(Clouds) do
		if not ACF.IsSmokeCloudBlocking(Cloud, Time) then continue end

		local Center, Radius = ACF.GetSmokeCloudState(Cloud, Time)

		render.DrawWireframeSphere(Center, Radius, 16, 16, DebugCol, true)
	end
end)
