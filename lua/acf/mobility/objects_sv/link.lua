local ACF	= ACF
local Meta	= {}
local String	= "Link [Source = %s, Target = %s, Origin = %s, Axis = %s]"
local Debug		= ACF.Debug
local Objects	= ACF.Mobility.Objects

function Objects.Link(Source, Target)
	local Link	= {
		Vel		= 0,
		ReqTq	= 0,

		Source	= Source,
		Target	= Target,
		Origin		= Vector(),
		TargetPos	= Vector(),
		Axis 		= Vector(1, 0, 0),
		IsGearbox	= Target.IsACFGearbox or false
	}

	setmetatable(Link, Meta)

	return Link
end

local red		= Color(255, 0, 0)
local orange	= Color(255, 127, 0)
function Meta:Transfer( Torque )
	local P1 = self.Source:LocalToWorld(self.Origin)
	local P2 = self.Target:LocalToWorld(self.TargetPos)
	Debug.Line(P1, P2, 0.05, self.IsGearbox and red or orange, true)
	Debug.Text(LerpVector(0.5, P1, P2), math.Round(Torque, 1) .. " Nm", 0.05, false)


end

function Meta:ToString()
	return String:format(self.Source, self.Target, self.Origin, self.Axis)
end

AccessorFunc(Meta, "Source", "Source")
AccessorFunc(Meta, "Target", "Target")
AccessorFunc(Meta, "Origin", "Origin", FORCE_VECTOR)
AccessorFunc(Meta, "Axis", "Axis", FORCE_VECTOR)
AccessorFunc(Meta, "TargetPos", "TargetPos", FORCE_VECTOR)

Meta.__index	= Meta
Meta.__tostring	= Meta.ToString