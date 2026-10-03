local ACF = ACF

ACF.SmokeClouds = ACF.SmokeClouds or {}

local Clouds = ACF.SmokeClouds

ACF.SmokeBlockShare = 0.85 -- Portion of a cloud's visual lifetime it blocks for, its particles thin out after that

local MaxRadius = 800 -- Inches, ~20 m
local MaxLife   = 30
local WindDrift = Vector(0.5, 0, 0) -- Inches per second per point of SmokeWind
local Types     = {
	Smoke = { Offset = 0, MinScale = 0.075, Deploy = 1.5, BaseLife = 5, LifeScale = 0.125 }, -- Slow build but long lasting
	WP    = { Offset = 1, MinScale = 0.5, Deploy = 0.5, BaseLife = 2.5, LifeScale = 0.05 }, -- Quick build and dissipate
}

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

--- Returns the min radius, max radius, lifetime and burst duration of a cloud of the given filler type ("Smoke" or "WP").
function ACF.GetSmokeCloudStats(Mass, Type)
	local Data   = Types[Type]
	local Radius = ACF.GetSmokeRadius(Mass)
	local Life   = math.Clamp(Data.BaseLife + ACF.GetSmokeFiller(Mass) * Data.LifeScale, 1, MaxLife)

	return Radius * Data.MinScale, Radius, Life, Data.Deploy
end

--- Builds and registers the clouds of one smoke impact. Runs identically on the server and every client from the
--- same impact data, so only that data needs networking. Base holds Start, Color, Center, Normal, Grounded, Carry
--- and FloorZ.
function ACF.AddSmokeClouds(ImpactID, Base, FillerMass, WPMass)
	local Result = {}
	local Drift  = WindDrift * (ACF.SmokeWind or 0)

	for Type, Mass in pairs({ Smoke = FillerMass, WP = WPMass }) do
		if Mass <= 0 then continue end

		local MinRadius, MaxRadius, Life, Deploy = ACF.GetSmokeCloudStats(Mass, Type)
		local ID = ImpactID * 2 + Types[Type].Offset

		local Cloud = {
			ID        = ID,
			Center    = Base.Center,
			Normal    = Base.Normal,
			Grounded  = Base.Grounded,
			Carry     = Base.Carry,
			FloorZ    = Base.FloorZ,
			Start     = Base.Start,
			Color     = Base.Color,
			Drift     = Drift,
			Life      = Life,
			Deploy    = Deploy,
			MinRadius = MinRadius,
			MaxRadius = MaxRadius,
		}

		Clouds[ID]          = Cloud
		Result[#Result + 1] = Cloud

		timer.Simple(math.max(Cloud.Start + Life - CurTime(), 0), function()
			if Clouds[ID] == Cloud then Clouds[ID] = nil end
		end)
	end

	return Result
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

	local Delta = End - Start

	if Delta:IsZero() then return end

	local Time = CurTime()
	local Best

	for ID, Cloud in pairs(Clouds) do
		if not ACF.IsSmokeCloudBlocking(Cloud, Time) then
			if Time > Cloud.Start + Cloud.Life then Clouds[ID] = nil end

			continue
		end

		local Center, Radius = ACF.GetSmokeCloudState(Cloud, Time)
		local Enter, Exit    = util.IntersectRayWithSphere(Start, Delta, Center, Radius)

		if not Enter or Exit < 0 or Enter > 1 then continue end
		if Enter <= 0 then return 0 end -- Starts inside the cloud

		if not Best or Enter < Best then
			Best = Enter
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
