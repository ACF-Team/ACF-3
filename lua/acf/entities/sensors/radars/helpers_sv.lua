-- Shared detection-scan helpers used by acf_radar, acf_irst and acf_sensorsync
local ACF = ACF
ACF.RadarHelpers = ACF.RadarHelpers or {}

local RadarHelpers = ACF.RadarHelpers
local TraceData = { start = true, endpos = true, mask = MASK_SOLID_BRUSHONLY, filter = {} }
local Trace = ACF.trace

-- Minimum target size (in inches) detectable at a given distance, given the radar's own MinSizeAtRange
-- (the smallest target it can see at its own max range) and Range. Scales down toward 0 as distance
-- approaches 0, so all radars can see small targets up close, but only larger radars can see
-- small targets far away. Non linear to mimic how realistic detection strength falls off with range.
-- Higher exponent = detection of small targets falls off faster with range (near targets barely change)
local MinSizeExponent = 2

function RadarHelpers.GetMinDetectableSize(Radar, EntDist)
	local MinSizeAtRange = Radar.MinSizeAtRange

	if not MinSizeAtRange or not Radar.Range then return 0 end

	return MinSizeAtRange * (EntDist / Radar.Range) ^ MinSizeExponent
end

-- World only line of sight check between a radar's origin and a candidate's position
function RadarHelpers.CheckLOS(Start, End)
	TraceData.start = Start
	TraceData.endpos = End

	return not Trace(TraceData).Hit
end

-- If radar info is restricted and the radar's owner doesn't have permissions on the target, its name is
-- withheld as Unknown. Otherwise resolves to the target's actual owner name, or World/Unknown if it has none
function RadarHelpers.GetEntityOwner(Owner, Entity)
	if ACF.RestrictRadarInfo and (not IsValid(Owner) or not Entity:CPPICanTool(Owner)) then
		return "Unknown"
	end

	if Entity:IsPlayer() then return Entity:GetName() end

	local EntOwner = Entity:CPPIGetOwner()

	if not IsValid(EntOwner) then
		return EntOwner == game.GetWorld() and "World" or "Unknown"
	end

	return EntOwner:GetName()
end

-- Classifies a detected candidate and measures its size. Missiles are sized by caliber, contraptions and
-- players by their bounding box diagonal. Returns 0, nil for anything else
function RadarHelpers.GetEntSizeAndType(Ent)
	if Ent.IsACFMissile then
		return math.Round((Ent.Caliber or 0) / ACF.InchToMm), "Missile"
	end

	if Ent:IsPlayer() then
		local Mins, Maxs = Ent:OBBMins(), Ent:OBBMaxs()

		return math.Round((Maxs - Mins):Length()), "Player"
	end

	local EntContraption = Ent:CFW_GetContraption()

	if EntContraption then
		local Mins, Maxs = EntContraption:GetAABB()

		return math.Round((Maxs - Mins):Length()), "Contraption"
	end

	return 0, nil
end

function RadarHelpers.GetTargetPos(Ent)
	if Ent:IsPlayer() then return Ent:WorldSpaceCenter() end

	return Ent.ACF_Position or Ent:GetPos()
end

-- Seated players are skipped; the contraption they're riding is what gets detected
function RadarHelpers.GetPlayersInShapes(Shapes, Contraption)
	local Result = {}

	for _, Ply in player.Iterator() do
		if not Ply:Alive() or Ply:InVehicle() then continue end
		if Contraption and Ply:CFW_GetContraption() == Contraption then continue end

		ACF.Countermeasures.MatchShapes(Result, Ply, Ply:WorldSpaceCenter(), Shapes)
	end

	return Result
end
