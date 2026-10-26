local ACF       = ACF
ACF.SmokeClouds = ACF.SmokeClouds or {}

local Impacts    = {} -- Kept until their clouds expire, so late joiners can be sent them
local TraceData  = { start = true, endpos = true, mask = MASK_NPCWORLDSTATIC }
local Up         = Vector(0, 0, 1)
local GroundGap  = 24 -- Bursts closer than this to the ground are treated as having landed on it, fits in 5 bits
local CarryShare  = 0.2 -- Share of an airbursting round's velocity its cloud carries
local ImpactShare = 0.05 -- Share of an impacting round's velocity, along the surface it hit, its cloud carries
local MaxCarry    = 16000 -- Stays inside net.WriteVector's coordinate range
local CoastLift   = 32 -- Height above the surface the coast of a cloud is traced at, so bumps in the ground don't stop it
local FloorDepth  = 32768
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

	local Carrying = not Base.Carry:IsZero()

	net.WriteBool(Carrying)
	if Carrying then net.WriteVector(Base.Carry) end

	net.WriteBool(Base.Grounded)

	if Base.Grounded then
		net.WriteUInt(Base.Drop, 5)
		net.WriteNormal(Base.Normal)
	else
		net.WriteFloat(Base.FloorZ)
	end
end

-- Velocity of the round the cloud came from, partly carried over to it: along the surface it hit when HitNormal is
-- given (or the ground it burst right above), all of it for rounds that burst in the air
local function GetCarry(Velocity, Normal, Share)
	local Carry = Velocity * Share

	if Normal then Carry = Carry - Normal * Carry:Dot(Normal) end
	if Carry:Length() > MaxCarry then Carry = Carry:GetNormalized() * MaxCarry end

	return Carry
end

-- Filler masses are in kg. Velocity is the round's, HitNormal the normal of what it hit (nil for airbursts)
function ACF.CreateSmokeScreen(Origin, FillerMass, WPMass, Color, Velocity, HitNormal)
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
	end

	if Velocity then
		local Share = HitNormal and ImpactShare or CarryShare
		local Along = Base.Grounded and Base.Normal or HitNormal
		local Lift  = Along and Along * CoastLift or vector_origin

		Base.Carry = GetCarry(Velocity, Along, Share)

		-- Clouds stop at the first wall in their way, both share how far the slowest settling one would coast
		TraceData.start  = Base.Center + Lift
		TraceData.endpos = TraceData.start + ACF.GetSmokeCarryDistance(Base.Carry)

		local Fraction = util.TraceLine(TraceData).Fraction

		-- Rounded so clients that are sent it move the cloud exactly like the server
		Base.Carry = Base.Carry * math.Round(Fraction, 3)
	end

	if not Base.Grounded then
		-- Ground below where the cloud coasts to a stop, it sinks down to it and no further. WP stops sooner, but both
		-- share the floor
		local Rest = Origin + ACF.GetSmokeCarryDistance(Base.Carry)

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
