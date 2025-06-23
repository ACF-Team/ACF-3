local ACF	= ACF
local Meta	= {}
local String	= "Link [Source = %s, Target = %s, Origin = %s, Axis = %s]"
local Debug		= ACF.Debug
local Objects	= ACF.Mobility.Objects
local deg		= math.deg
local Clamp		= math.Clamp

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

do
	local red		= Color(255, 0, 0)
	local orange	= Color(255, 127, 0)

	-- Function used to apply torque to a wheel or other entity
	-- Previously was a part of acf_gearbox init.lua
	local function ActWheel(Link, Wheel, Torque, DeltaTime)
		local Phys = Wheel:GetPhysicsObject()

		if not Phys:IsMotionEnabled() then return end -- skipping entirely if its frozen

		local TorqueAxis = Phys:LocalToWorldVector(Link.Axis)

		Phys:ApplyTorqueCenter(TorqueAxis * Clamp(deg(-Torque * ACF.TorqueMult) * DeltaTime, -500000, 500000))
	end

	-- Used to transfer torque from one gearbox to another
	function Meta:TransferGearbox( Gearbox, Torque, DeltaTime, MassRatio )
		local P1 = self.Source:LocalToWorld(self.Origin)
		local P2 = self.Target:LocalToWorld(self.TargetPos)
		Debug.Line(P1, P2, 0.05, red, true)
		Debug.Text(LerpVector(0.5, P1, P2), math.Round(Torque, 1) .. " Nm", 0.05, false)

		Gearbox:Act(Torque, DeltaTime, MassRatio)
	end

	-- Used to transfer torque from a gearbox to a wheel or other entity
	function Meta:TransferWheel( Entity, Torque, DeltaTime )
		local P1 = self.Source:LocalToWorld(self.Origin)
		local P2 = self.Target:LocalToWorld(self.TargetPos)
		Debug.Line(P1, P2, 0.05, orange, true)
		Debug.Text(LerpVector(0.5, P1, P2), math.Round(Torque, 1) .. " Nm", 0.05, false)

		ActWheel(self, Entity, Torque, DeltaTime)
	end
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