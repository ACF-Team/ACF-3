local ACF             = ACF
local Classes         = ACF.Classes
local Countermeasures = ACF.Classes.Countermeasures
local Trace           = ACF.trace

Classes.DefineClass("ACF.Sensors.Receiver.Warning", "ACF.Sensors.Receiver", function()
	CLASS.Name       = "Warning Receiver"
	CLASS.ID         = "WARN-Receiver"
	CLASS.Entity     = "acf_receiver"
	CLASS.SpawnModel = "icon16/error.png"
end)

do -- Laser Receiver
	local function ReceiveSource(Receiver)
		local Lasers = {}

		local ReceiverOrigin = Receiver:LocalToWorld(Receiver.Origin)

		for k, v in pairs(ACF.ActiveLasers) do
			local Dir = k.Dir or k:GetForward()
			if v.Distance > 0 then Dir = (v.HitPos - v.Origin):GetNormalized() end

			if Dir:Dot((ReceiverOrigin - v.Origin):GetNormalized()) >= Receiver.Cone then Lasers[k] = true end
		end

		-- Wiremod laser pointer, because it's, you know, a laser
		for _, ply in player.Iterator() do
			local Wep = ply:GetWeapon("laserpointer")
			if not IsValid(Wep) then continue end
			if Wep ~= ply:GetActiveWeapon() then continue end

			if Wep.Pointing then
				local Las = {Dir = ply:EyeAngles():Forward(), Position = ply:EyePos(), Player = ply}

				if Las.Dir:Dot((ReceiverOrigin - Las.Position):GetNormalized()) >= Receiver.Cone then Lasers[Las] = true end
			end
		end

		return Lasers
	end

	local TraceData = { start = true, endpos = true, mask = MASK_SOLID }
	local function CheckLOS(Receiver, Source, Start, End)
		TraceData.start = Start
		TraceData.endpos = End
		if IsValid(Source.Player) then
			TraceData.filter = {Receiver, Source.Player}
		else TraceData.filter = {Receiver, Source} end

		return not Trace(TraceData).Hit
	end

	Classes.DefineClass("ACF.Sensors.Receiver.Warning.Laser", "ACF.Sensors.Receiver.Warning", function()
		CLASS.Name        = "Laser Warning Receiver"
		CLASS.ID          = "LAS-Receiver"
		CLASS.Description  = "An optical unit designed to detect laser sources and give a precise direction."
		CLASS.Model       = "models/bluemetaknight/laser_detector.mdl"

		CLASS.Mass        = 25
		CLASS.Health      = 10
		CLASS.Armor       = 10
		CLASS.Offset      = Vector(0, 0, 3)

		CLASS.ThinkDelay  = 0.25
		CLASS.Divisor     = 2.5 -- Divisor (pre-floor) and then multiplier to give a choppy angle
		CLASS.Cone        = math.cos(2.5 / 90)

		CLASS.Detect      = ReceiveSource
		CLASS.CheckLOS    = CheckLOS

		CLASS.Preview     = { FOV = 145 }
	end)
end

do -- Radar Receiver
	-- ACF.ActiveRadars for radars, need to check for direction and range for these
	local ValidMissileRadars = {
		["Active Radar"] = true
	}

	local function ReceiveSource(Receiver)
		local RadarSource = {}

		local ReceiverOrigin = Receiver:LocalToWorld(Receiver.Origin)

		for k in pairs(ACF.ActiveRadars) do -- Radar entities
			if k.EntType ~= "Targeting Radar" then continue end
			local RadarOrigin = k:LocalToWorld(k.Origin)

			if k.Range then -- Spherical
				if RadarOrigin:DistToSqr(ReceiverOrigin) <= (k.Range ^ 2) then RadarSource[k] = true end
			else -- Directional
				if Countermeasures.ConeContainsPos(RadarOrigin, k:GetForward(), k.ConeDegs, ReceiverOrigin) then RadarSource[k] = true end
			end
		end

		for k in pairs(ACF.ActiveMissiles) do -- Missile entities
			if not k.UseGuidance then continue end -- Don't waste time on missiles that don't have functional guidance
			if not ValidMissileRadars[k.Guidance] then continue end -- Further filter for anything without radar on the missile itself

			if Countermeasures.ConeContainsPos(k.ACF_Position, k:GetForward(), k.ViewCone, ReceiverOrigin) then RadarSource[k] = true end
		end

		return RadarSource
	end

	local TraceData = { start = true, endpos = true, mask = MASK_SOLID_BRUSHONLY, filter = {} }

	local function CheckLOS(_, _, Start, End)
		TraceData.start = Start
		TraceData.endpos = End

		return not Trace(TraceData).Hit
	end

	Classes.DefineClass("ACF.Sensors.Receiver.Warning.Radar", "ACF.Sensors.Receiver.Warning", function()
		CLASS.Name        = "Radar Warning Receiver"
		CLASS.ID          = "RAD-Receiver"
		CLASS.Description  = "An unit designed to detect radar sources and give a vague direction."
		CLASS.Model       = "models/jaanus/wiretool/wiretool_siren.mdl"

		CLASS.Mass        = 25
		CLASS.Health      = 10
		CLASS.Armor       = 10
		CLASS.Offset      = Vector(0, 0, 6)

		CLASS.ThinkDelay  = 0.5
		CLASS.Divisor     = 30 -- Divisor (pre-floor) and then multiplier to give a choppy angle

		CLASS.Detect      = ReceiveSource
		CLASS.CheckLOS    = CheckLOS

		CLASS.Preview     = { FOV = 145 }
	end)
end
