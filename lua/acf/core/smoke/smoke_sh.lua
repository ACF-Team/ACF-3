local ACF = ACF

ACF.SmokeClouds = ACF.SmokeClouds or {}

local Clouds = ACF.SmokeClouds

ACF.SmokeBlockShare = 0.85 -- Portion of a cloud's visual lifetime it blocks for, its particles thin out after that

local MaxRadius = 800 -- Inches, ~20 m

-- Drives lifetime, which flattens out quickly with mass
function ACF.GetSmokeFiller(Mass)
	return math.min(math.log(1 + Mass * 8 * ACF.MeterToInch) * 43.42, 350)
end

-- Max cloud radius in inches. The filler curve flattens out past ~1 kg, so heavier rounds switch to cube root
-- scaling (matched at 1 kg) to keep growing with filler
function ACF.GetSmokeRadius(Mass)
	if Mass <= 0 then return 0 end

	local LogRadius  = ACF.GetSmokeFiller(Mass) * 1.25
	local CubeRadius = ACF.GetSmokeFiller(1) * 1.25 * Mass ^ (1 / 3)

	return math.min(math.max(LogRadius, CubeRadius), MaxRadius)
end

function ACF.IsSmokeCloudBlocking(Cloud, Time)
	return Time <= Cloud.Start + Cloud.Life * ACF.SmokeBlockShare
end

-- Velocity carried over from an airbursting round winds down linearly to zero over this many seconds
ACF.SmokeCarryTime = 1.5
ACF.SmokeFallRate  = 20 -- Inches per second airborne clouds sink at until they reach the ground

-- Bursts out from the center to MinRadius with an ease out over Deploy, then grows linearly to MaxRadius.
-- Airborne clouds coast to a stop on their carried velocity, and sink until they reach FloorZ
function ACF.GetSmokeCloudState(Cloud, Time)
	local Elapsed = math.Clamp(Time - Cloud.Start, 0, Cloud.Life)
	local Deploy  = Cloud.Deploy
	local Center  = Cloud.Center + Cloud.Drift * Elapsed
	local Radius

	if Elapsed < Deploy then
		local Remaining = 1 - Elapsed / Deploy

		Radius = Cloud.MinRadius * (1 - Remaining * Remaining)
	else
		Radius = Lerp((Elapsed - Deploy) / (Cloud.Life - Deploy), Cloud.MinRadius, Cloud.MaxRadius)
	end

	if not Cloud.Grounded then
		local CarryTime = ACF.SmokeCarryTime
		local Remaining = 1 - math.min(Elapsed / CarryTime, 1)

		Center   = Center + Cloud.Carry * (CarryTime * 0.5 * (1 - Remaining * Remaining))
		Center.z = math.max(Center.z - ACF.SmokeFallRate * Elapsed, Cloud.FloorZ)
	end

	return Center, Radius
end

--- Seconds after its creation an airborne cloud settles onto the ground, or nil if it never moves vertically.
--- Only valid once its carried velocity has run out, which is when anything needs to know.
function ACF.GetSmokeLandTime(Cloud)
	if Cloud.Grounded then return end

	local Height = Cloud.Center.z + Cloud.Carry.z * ACF.SmokeCarryTime * 0.5 - Cloud.FloorZ

	return math.max(Height / ACF.SmokeFallRate, 0)
end

--- Returns the fraction along Start -> End where the segment first enters a smoke cloud, or nil if it never does.
--- A segment starting inside a cloud returns 0.
function ACF.TraceSmoke(Start, End)
	if not next(Clouds) then return end

	local Time  = CurTime()
	local Delta = End - Start
	local A     = Delta:Dot(Delta)
	local Best

	if A == 0 then return end

	for ID, Cloud in pairs(Clouds) do
		if not ACF.IsSmokeCloudBlocking(Cloud, Time) then
			if Time > Cloud.Start + Cloud.Life then Clouds[ID] = nil end

			continue
		end

		local Center, Radius = ACF.GetSmokeCloudState(Cloud, Time)
		local Offset = Start - Center
		local C      = Offset:Dot(Offset) - Radius * Radius

		if C <= 0 then return 0 end

		local B    = 2 * Offset:Dot(Delta)
		local Disc = B * B - 4 * A * C

		if Disc < 0 then continue end

		local Fraction = (-B - math.sqrt(Disc)) / (2 * A)

		if Fraction >= 0 and Fraction <= 1 and (not Best or Fraction < Best) then
			Best = Fraction
		end
	end

	return Best
end

--- Shortens a finished trace result so it stops at the first smoke cloud between Start and its hit position.
function ACF.ClipTraceToSmoke(Start, Result)
	local Fraction = ACF.TraceSmoke(Start, Result.HitPos)

	if not Fraction then return Result end

	Result.HitPos      = LerpVector(Fraction, Start, Result.HitPos)
	Result.Fraction    = Result.Fraction * Fraction
	Result.Hit         = true
	Result.HitWorld    = false
	Result.HitNonWorld = false
	Result.Entity      = NULL
	Result.HitSmoke    = true

	return Result
end
