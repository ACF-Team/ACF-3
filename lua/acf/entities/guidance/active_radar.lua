local ACF       = ACF
local Classes 	= ACF.Classes
Classes.DefineClass("ACF.Missiles.Guidance.ActiveRadar", "ACF.Missiles.SemiActiveRadar", function()
	if CLIENT then
		CLASS.Description = "This guidance package uses a radar to detect contraptions and guides the munition towards the most centered one it can find."
	else
		function CLASS:GetCost()
			return 3
		end

		function CLASS:SeekTarget(Missile)
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
end)