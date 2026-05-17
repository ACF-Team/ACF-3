local ACF       = ACF
local Guidances = ACF.Classes.Guidances
local Guidance  = Guidances.Register("Anti-radiation", "Laser")

function Guidance:Configure(Missile)
	Guidance.BaseClass.Configure(self, Missile)

	self.SeekCone = Missile.SeekCone or 10
	self.SeekConeCos = math.cos(math.rad(self.SeekCone))
end

function Guidance:WriteDisplayConfig(State)
	State:AddSubKeyValue("Tracking", math.Round(self.SeekCone * 2, 2) .. " degrees")
	State:AddSubKeyValue("Seeking",  math.Round(self.ViewCone * 2, 2) .. " degrees")
end

if CLIENT then
	Guidance.Description = "This guidance package will detect an active radar infront of itself and guide the munition towards it."
else
	local Radars = ACF.ActiveRadars

	Guidance.MinDistance = 38750 -- Squared, ~5 meters

	function Guidance:GetCost()
		return 2
	end

	function Guidance:UpdateTarget(Missile)
		if not next(Radars) then return end

		local Position = Missile.ACF_Position
		local HighestDot = 0
		local Target, TargetPos

		for Radar in pairs(Radars) do
			local RadarPos = Radar:LocalToWorld(Radar.Origin)
			local Distance = Position:DistToSqr(RadarPos)

			if Distance < self.MinDistance then continue end
			if not self:CheckConeLOS(Missile, Position, RadarPos, self.SeekConeCos) then continue end

			local CurrentDot = self.GetDirectionDot(Missile, RadarPos)

			if CurrentDot > HighestDot then
				HighestDot = CurrentDot
				TargetPos  = RadarPos
				Target     = Radar
			end
		end

		self.Target = Target

		return TargetPos
	end

	function Guidance:OnLaunched(Missile)
		self:UpdateTarget(Missile)
	end

	function Guidance:GetTargetPosition()
		local Target = self.Target

		if not IsValid(Target) then return end
		if not Target.Active then return end

		return Target:LocalToWorld(Target.Origin)
	end

	function Guidance:GetGuidance(Missile)
		local TargetPos = self:GetTargetPosition()

		if TargetPos and self:CheckConeLOS(Missile, Missile.ACF_Position, TargetPos, self.ViewConeCos) then
			return { TargetPos = TargetPos, ViewCone = self.ViewCone }
		end

		local NewTarget = self:UpdateTarget(Missile)

		if not NewTarget then return {} end

		return { TargetPos = NewTarget, ViewCone = self.ViewCone }
	end
end
