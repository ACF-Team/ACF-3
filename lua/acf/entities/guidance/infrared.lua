local ACF       = ACF
local Guidances = ACF.Classes.Guidances
local Guidance  = Guidances.Register("Infrared", "Anti-radiation")

if CLIENT then
	Guidance.Description = "This guidance package will detect a contraption in front of itself and guide the munition towards it."
else
	function Guidance:GetCost()
		return 3
	end

	function Guidance:UpdateTarget(Missile)
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

		self.Target = Target

		return TargetPos
	end

	function Guidance:GetTargetPosition()
		local Target = self.Target

		if not IsValid(Target) then return end

		return Target.ACF_Position
	end

	function Guidance:GetGuidance(Missile)
		self:PreGuidance(Missile)

		local Override = self:ApplyOverride(Missile)

		if Override then return Override end

		local TargetPos = self:GetTargetPosition()

		if TargetPos and self:CheckConeLOS(Missile, Missile.ACF_Position, TargetPos, self.ViewConeCos) then
			return { TargetPos = TargetPos, ViewCone = self.ViewCone }
		end

		local NewTarget = self:UpdateTarget(Missile)

		if not NewTarget then return {} end

		return { TargetPos = NewTarget, ViewCone = self.ViewCone }
	end
end
