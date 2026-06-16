local Guidances = ACF.Classes.Guidances
local Guidance  = Guidances.Register("Semi-Active Radar", "Anti-missile")

if CLIENT then
	Guidance.Description = "This guidance package uses a radar to detect contraptions and guides the munition towards the most centered one it can find."
else
	Guidance.RadarType = "TGT-Radar"

	function Guidance:GetCost()
		return 5
	end

	-- Semi-actives can't seek targets by themselves
	function Guidance:SeekTarget()
		self.Target  = nil
		self.OnRadar = nil
	end

	function Guidance:UpdateTarget(Missile, Radar)
		if not Radar or Radar.TargetCount == 0 then
			return self:SeekTarget(Missile)
		end

		local Targets    = Radar.Targets
		local Position   = Missile.ACF_Position
		local HighestDot = 0
		local Target, TargetPos

		for Entity, Data in pairs(Targets) do
			local EntPos   = Data.Position
			local Distance = Position:DistToSqr(EntPos)

			if Distance < self.MinDistance then continue end
			if not self:CheckConeLOS(Missile, Position, EntPos, self.ViewConeCos) then continue end

			local CurrentDot = self.GetDirectionDot(Missile, EntPos)

			if CurrentDot > HighestDot then
				HighestDot = CurrentDot
				TargetPos  = EntPos
				Target     = Entity
			end
		end

		self.Target  = Target
		self.OnRadar = true

		return TargetPos
	end
end
