local ACF       = ACF
ACF.SmokeClouds = ACF.SmokeClouds or {}

local Clouds     = ACF.SmokeClouds
local TraceData  = { start = true, endpos = true, mask = MASK_NPCWORLDSTATIC }
local Up         = Vector(0, 0, 1)
local WindDrift  = Vector(0.5, 0, 0) -- Inches per second per point of SmokeWind
local MaxLife    = 30
local GroundGap  = 24 -- Bursts closer than this to the ground are treated as having landed on it
local Burster    = 0.05 -- Share of the filler mass used to size the purely visual burst explosion
local CarryShare = 0.2 -- Share of an airbursting round's velocity its cloud carries
local FloorDepth = 32768
local CloudID    = 0

util.AddNetworkString("ACF_SmokeCloud")

local function WriteCloud(Cloud)
	net.WriteUInt(Cloud.ID, 16)
	net.WriteVector(Cloud.Center)
	net.WriteVector(Cloud.Drift)
	net.WriteNormal(Cloud.Normal)
	net.WriteBool(Cloud.Grounded)
	net.WriteVector(Cloud.Carry)
	net.WriteFloat(Cloud.FloorZ)
	net.WriteFloat(Cloud.Start)
	net.WriteFloat(Cloud.Life)
	net.WriteFloat(Cloud.Deploy)
	net.WriteFloat(Cloud.MinRadius)
	net.WriteFloat(Cloud.MaxRadius)
	net.WriteColor(Cloud.Color, false)
end

local function CreateCloud(Base, Color, Radius, MinScale, Life, Deploy)
	CloudID = CloudID % 65535 + 1

	local Cloud = {
		ID        = CloudID,
		Center    = Base.Center,
		Drift     = WindDrift * (ACF.SmokeWind or 0),
		Normal    = Base.Normal,
		Grounded  = Base.Grounded,
		Carry     = Base.Carry,
		FloorZ    = Base.FloorZ,
		Start     = CurTime(),
		Life      = math.Clamp(Life, 1, MaxLife),
		Deploy    = Deploy,
		MinRadius = Radius * MinScale,
		MaxRadius = Radius,
		Color     = Color,
	}

	Clouds[CloudID] = Cloud

	timer.Simple(Cloud.Life, function()
		if Clouds[Cloud.ID] == Cloud then Clouds[Cloud.ID] = nil end
	end)

	net.Start("ACF_SmokeCloud")
		WriteCloud(Cloud)
	net.Broadcast()
end

-- Filler masses are in kg, same scaling the smoke round's display data uses. Velocity is only given for
-- rounds that burst in the air, and is partly carried over to the cloud
function ACF.CreateSmokeScreen(Origin, FillerMass, WPMass, Color, Velocity)
	local Filler   = ACF.GetSmokeFiller(FillerMass)
	local WPFiller = ACF.GetSmokeFiller(WPMass)

	if Filler + WPFiller <= 0 then return end

	local Sparks = math.Clamp((FillerMass + WPMass) * 2, 1, 8)

	ACF.Damage.explosionEffect(Origin, nil, (FillerMass + WPMass) * Burster)
	ACF.Utilities.Effects.CreateEffect("Sparks", {
		Origin    = Origin,
		Normal    = Up,
		Magnitude = Sparks,
		Radius    = Sparks,
		Scale     = Sparks,
	})

	TraceData.start  = Origin
	TraceData.endpos = Origin - Up * GroundGap

	local Ground = util.TraceLine(TraceData)
	local Base   = {
		Center   = Origin,
		Normal   = Up,
		Grounded = Ground.HitWorld,
		Carry    = Vector(),
		FloorZ   = Origin.z,
	}

	if Base.Grounded then
		Base.Center = Ground.HitPos
		Base.Normal = Ground.HitNormal
	else
		if Velocity then Base.Carry = Velocity * CarryShare end

		-- Ground below where the cloud coasts to a stop, it sinks down to it and no further
		local Rest = Origin + Base.Carry * (ACF.SmokeCarryTime * 0.5)

		TraceData.start  = Rest
		TraceData.endpos = Rest - Up * FloorDepth

		Base.FloorZ = util.TraceLine(TraceData).HitPos.z
	end

	Color = Color or color_white

	if Filler > 0 then
		CreateCloud(Base, Color, ACF.GetSmokeRadius(FillerMass), 0.075, 5 + Filler * 0.125, 1.5) -- Slow build but long lasting
	end

	if WPFiller > 0 then
		CreateCloud(Base, Color, ACF.GetSmokeRadius(WPMass), 0.5, 2.5 + WPFiller * 0.05, 0.5) -- Quick build and dissipate
	end
end

hook.Add("ACF_OnLoadPlayer", "ACF Smoke Cloud Sync", function(Player)
	local Time = CurTime()

	for ID, Cloud in pairs(Clouds) do
		if Time > Cloud.Start + Cloud.Life then
			Clouds[ID] = nil

			continue
		end

		net.Start("ACF_SmokeCloud")
			WriteCloud(Cloud)
		net.Send(Player)
	end
end)
