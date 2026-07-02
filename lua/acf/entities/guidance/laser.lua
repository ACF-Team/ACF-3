local ACF       = ACF
local Guidances = ACF.Classes.Guidances
local Guidance  = Guidances.Register("Laser", "Radio (MCLOS)")

function Guidance:Configure(Missile)
	Guidance.BaseClass.Configure(self, Missile)

	self.ViewCone = Missile.ViewCone or 20
	self.ViewConeCos = math.cos(math.rad(self.ViewCone))
end

function Guidance:WriteDisplayConfig(State)
	State:AddSubKeyValue("Tracking", math.Round(self.ViewCone * 2, 2) .. " deg")
end

if CLIENT then
	Guidance.Description = "This guidance package reads a target-position from the launcher and guides the munition towards it."
else
	local TraceData = { start = true, endpos = true, mask = MASK_SOLID_BRUSHONLY, filter = {} }
	local Trace     = ACF.trace
	local Lasers    = ACF.ActiveLasers

	function Guidance:GetCost()
		return 5
	end

	function Guidance.GetDirectionDot(Missile, TargetPos)
		local Position = Missile.ACF_Position
		local Forward = Missile:GetForward()
		local Direction = (TargetPos - Position):GetNormalized()

		return Direction:Dot(Forward)
	end

	function Guidance:CheckConeLOS(Missile, Position, TargetPos, ConeCos)
		if self.GetDirectionDot(Missile, TargetPos) < ConeCos then return end

		TraceData.start = Position
		TraceData.endpos = TargetPos

		return not Trace(TraceData).Hit
	end

	function Guidance:CheckComputer(Missile)
		local Computer = self:GetComputer()

		if not Computer then return end
		if not Computer.IsLaserSource then return end
		if not Computer.Lasing then return end

		local Position = Missile.ACF_Position
		local HitPos = Computer.HitPos

		if not self:CheckConeLOS(Missile, Position, HitPos, self.ViewConeCos) then return end

		return HitPos
	end

	function Guidance:GetGuidance(Missile)
		if not next(Lasers) then return {} end

		local HitPos = self:CheckComputer(Missile)

		if HitPos then return { TargetPos = HitPos } end

		local Position = Missile.ACF_Position
		local HighestDot = 0
		local CurrentDot

		for _, Laser in pairs(Lasers) do
			local LaserPos = Laser.HitPos

			if self:CheckConeLOS(Missile, Position, LaserPos, self.ViewConeCos) then
				CurrentDot = self.GetDirectionDot(Missile, LaserPos)

				if CurrentDot > HighestDot then
					HighestDot = CurrentDot
					HitPos = LaserPos
				end
			end
		end

		return { TargetPos = HitPos }
	end
end
