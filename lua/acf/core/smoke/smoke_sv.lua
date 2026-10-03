local ACF       = ACF
ACF.SmokeClouds = ACF.SmokeClouds or {}

local Impacts    = {} -- Kept until their clouds expire, so late joiners can be sent them
local TraceData  = { start = true, endpos = true, mask = MASK_NPCWORLDSTATIC }
local Up         = Vector(0, 0, 1)
local GroundGap  = 24 -- Bursts closer than this to the ground are treated as having landed on it, fits in 5 bits
local CarryShare = 0.2 -- Share of an airbursting round's velocity its cloud carries
local MaxCarry   = 16000 -- Stays inside net.WriteVector's coordinate range
local FloorDepth = 32768
local ImpactID   = 0

util.AddNetworkString("ACF_SmokeImpact")

-- Only fields that apply to the impact are written, everything else is derived on the client (see ACF.AddSmokeClouds)
local function WriteImpact(ID, Impact, Burst)
	local Base = Impact.Base

	net.WriteUInt(ID, 15)
	net.WriteBool(Burst)
	net.WriteVector(Base.Origin)
	net.WriteFloat(Base.Start)
	net.WriteColor(Base.Color, false)

	net.WriteBool(Impact.FillerMass > 0)
	if Impact.FillerMass > 0 then net.WriteFloat(Impact.FillerMass) end

	net.WriteBool(Impact.WPMass > 0)
	if Impact.WPMass > 0 then net.WriteFloat(Impact.WPMass) end

	net.WriteBool(Base.Grounded)

	if Base.Grounded then
		net.WriteUInt(Base.Drop, 5)
		net.WriteNormal(Base.Normal)
	else
		local Carrying = not Base.Carry:IsZero()

		net.WriteBool(Carrying)
		if Carrying then net.WriteVector(Base.Carry) end

		net.WriteFloat(Base.FloorZ)
	end
end

-- Filler masses are in kg. Velocity is only given for rounds that burst in the air, and is partly carried over to the cloud
function ACF.CreateSmokeScreen(Origin, FillerMass, WPMass, Color, Velocity)
	if FillerMass <= 0 and WPMass <= 0 then return end

	TraceData.start  = Origin
	TraceData.endpos = Origin - Up * GroundGap

	local Ground = util.TraceLine(TraceData)
	local Base   = {
		Origin   = Origin,
		Start    = CurTime(),
		Color    = Color or color_white,
		Grounded = Ground.HitWorld,
		Center   = Origin,
		Normal   = Up,
		Carry    = Vector(),
		FloorZ   = Origin.z,
	}

	if Base.Grounded then
		-- Rounded so the server uses exactly what clients are sent
		Base.Drop   = math.Clamp(math.Round(Origin.z - Ground.HitPos.z), 0, GroundGap)
		Base.Center = Origin - Up * Base.Drop
		Base.Normal = Ground.HitNormal
	else
		if Velocity then
			Base.Carry = Velocity * CarryShare

			if Base.Carry:Length() > MaxCarry then
				Base.Carry = Base.Carry:GetNormalized() * MaxCarry
			end
		end

		-- Ground below where the cloud coasts to a stop, it sinks down to it and no further
		local Rest = Origin + Base.Carry * (ACF.SmokeCarryTime * 0.5)

		TraceData.start  = Rest
		TraceData.endpos = Rest - Up * FloorDepth

		Base.FloorZ = util.TraceLine(TraceData).HitPos.z
	end

	ImpactID = ImpactID % 32767 + 1

	local ID     = ImpactID
	local Impact = { Base = Base, FillerMass = FillerMass, WPMass = WPMass }
	local EndAt  = Base.Start

	for _, Cloud in ipairs(ACF.AddSmokeClouds(ID, Base, FillerMass, WPMass)) do
		EndAt = math.max(EndAt, Cloud.Start + Cloud.Life)
	end

	Impacts[ID] = Impact

	timer.Simple(EndAt - Base.Start, function()
		if Impacts[ID] == Impact then Impacts[ID] = nil end
	end)

	net.Start("ACF_SmokeImpact")
		WriteImpact(ID, Impact, true)
	net.Broadcast()
end

hook.Add("ACF_OnLoadPlayer", "ACF Smoke Cloud Sync", function(Player)
	for ID, Impact in pairs(Impacts) do
		net.Start("ACF_SmokeImpact")
			WriteImpact(ID, Impact, false)
		net.Send(Player)
	end
end)
