local ACF         = ACF
local LinkFailure = ACF.Mobility.LinkFailure or {}

ACF.Mobility.LinkFailure = LinkFailure

-- Shows the owner why a mobility link was refused, next to the message the link tool prints

local LIFE        = 6 -- Seconds the drawing stays up
local STRAIGHT    = 24 -- Length of the lines showing where each end points, in units
local COLOR_BAD   = Color(255, 50, 50)
local COLOR_GOOD  = Color(50, 255, 50)

--- The two entities are further apart than mobility links reach.
--- @param Source entity
--- @param Target entity
function LinkFailure.Distance(Source, Target)
	ACF.Hints.Flash(Source, LIFE, function(Debug, Life)
		local From, To = Source:GetPos(), Target:GetPos()

		Debug.Line(From, To, Life, COLOR_BAD, true)
		Debug.EntityBox(Target, Life, COLOR_BAD, true)
		Debug.EntityTextAtPosition(LerpVector(0.5, From, To), 0, math.Round(From:Distance(To)) .. " of "
			.. ACF.MobilityLinkDistance .. " units apart", Life, COLOR_BAD)
	end)
end

--- The shaft between the two would bend past the driveshaft angle limit.
--- @param Source entity The entity sending power
--- @param Output table The output plane of the source
--- @param Target entity The entity receiving power
--- @param Input table|nil The input plane of the target, nil for wheels
--- @param Angle number The angle the shaft would have
function LinkFailure.Angle(Source, Output, Target, Input, Angle)
	ACF.Hints.Flash(Source, LIFE, function(Debug, Life)
		local OutPos, OutDir = Output:ApplyTo(Source)
		local InPos = Input and Input:ApplyTo(Target) or Target:GetPos()

		-- Green shows where each end points, red the shaft they would need
		Debug.Line(OutPos, OutPos + OutDir * STRAIGHT, Life, COLOR_GOOD, true)
		Debug.Line(OutPos, InPos, Life, COLOR_BAD, true)

		if Input then
			local _, InDir = Input:ApplyTo(Target)

			Debug.Line(InPos, InPos + InDir * STRAIGHT, Life, COLOR_GOOD, true)
		end

		Debug.EntityTextAtPosition(LerpVector(0.5, OutPos, InPos), 0, math.Round(Angle) .. " of " .. ACF.MaxDriveshaftAngle
			.. " degrees", Life, COLOR_BAD)
	end)
end
