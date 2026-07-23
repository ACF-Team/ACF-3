local Guidances = ACF.Classes.Guidances
local Guidance  = Guidances.Register("Radio (MCLOS)", "Dumb")

function Guidance:Configure(Missile)
	self.Source = Missile.Launcher
end

if CLIENT then
	Guidance.Description = "This guidance package allows you to manually control the direction of the missile."
else
	local TraceData = { start = true, endpos = true, mask = MASK_SOLID_BRUSHONLY }
	local Trace     = ACF.trace

	function Guidance:GetCost()
		return 3
	end

	function Guidance:OnLaunched(Missile)
		self.InPos = Missile.MountPoint.Position
		self.OutPos = Missile.ExhaustPos
	end

	function Guidance:GetComputer()
		local Source = self.Source

		if not IsValid(Source) then return end

		local Computer = Source.Computer

		if not IsValid(Computer) then return end
		if Computer.Disabled then return end

		return Computer
	end

	function Guidance:CheckComputer()
		local Computer = self:GetComputer()

		if not Computer then return end
		if not Computer.IsJoystick then return end

		local Pitch = Computer.Pitch or 0
		local Yaw = Computer.Yaw or 0

		return -Pitch, -Yaw
	end

	function Guidance:CheckLOS(Missile)
		if not IsValid(self.Source) then return end
		TraceData.start = self.Source:LocalToWorld(self.InPos)
		TraceData.endpos = Missile:LocalToWorld(self.OutPos)

		local Result = Trace(TraceData)

		return not Result.Hit
	end

	function Guidance:GetGuidance(Missile)
		if not self:CheckLOS(Missile) then return {} end

		local Pitch, Yaw = self:CheckComputer()

		if not Pitch then return {} end
		if Pitch == 0 and Yaw == 0 then return {} end

		local Direction = Angle(Pitch, Yaw):Forward() * 12000

		return { TargetPos = Missile:LocalToWorld(Direction) }
	end
end
