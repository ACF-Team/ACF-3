local ACF       = ACF
local Guidances = ACF.Classes.Guidances
local Guidance  = Guidances.Register("Active Radar", "Semi-Active Radar")

if CLIENT then
	Guidance.Description = "This guidance package uses a radar to detect contraptions and guides the munition towards the most centered one it can find."
else
	function Guidance:GetCost()
		return 3
	end

	function Guidance:SeekTarget(Missile)
		local Position   = Missile.ACF_Position
		local Targets    = ACF.GetEntitiesInCone(Position, Missile:GetForward(), self.SeekCone)
		local HighestDot = 0
		local Target, TargetPos

		for Entity in pairs(Targets) do
			local EntPos   = Entity.ACF_Position
			local Distance = Position:DistToSqr(EntPos)

			if Distance < self.MinDistance then continue end
			if not self:CheckConeLOS(Missile, Position, EntPos, self.SeekConeCos) then continue end

			local CurrentDot = self.GetDirectionDot(Missile, EntPos)

			if CurrentDot > HighestDot then
				HighestDot = CurrentDot
				TargetPos  = EntPos
				Target     = Entity
			end
		end

		self.Target  = Target
		self.OnRadar = nil

		return TargetPos
	end
end
