local ACF       = ACF
local Classes 	= ACF.Classes
Classes.DefineClass("ACF.Missiles.Guidance.AntiMissile", "ACF.Missiles.AntiRadiation", function()
	local BASE = BASE

	if CLIENT then
		CLASS.Description = "This guidance package uses a radar to detect missiles and guides the munition towards the most centered one it can find."
	else
		local Countermeasures = ACF.Classes.Countermeasures
		CLASS.RadarType = "AM-Radar"

		function CLASS:GetCost()
			return 1
		end

		function CLASS:GetRadar()
			if not IsValid(self.Source) then return end

			local Radar = self.Source.Radar

			if not IsValid(Radar) then return end
			if not Radar.Scanning then return end
			if Radar.ClassType ~= self.RadarType then return end

			return Radar
		end

		function CLASS:SeekTarget(Missile)
			local Position   = Missile.ACF_Position
			local Targets    = Countermeasures.GetMissilesInCone(Position, Missile:GetForward(), self.SeekCone)
			local HighestDot = 0
			local Target, TargetPos

			for Entity in pairs(Targets) do
				if Missile == Entity then continue end
				if Entity.IsAntiMissile then continue end

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

		function CLASS:UpdateTarget(Missile, Radar)
			if not Radar or Radar.TargetCount == 0 then
				return self:SeekTarget(Missile)
			end

			local Targets    = Radar.Targets
			local Position   = Missile.ACF_Position
			local HighestDot = 0
			local Target, TargetPos

			for Entity, Data in pairs(Targets) do
				if Missile == Entity then continue end
				if Entity.IsAntiMissile then continue end

				local EntPos   = Data.Position
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
			self.OnRadar = true

			return TargetPos
		end

		function CLASS:OnLaunched(Missile)
			Missile.IsAntiMissile = true

			self:UpdateTarget(Missile, self:GetRadar())
		end

		function CLASS:GetTargetPosition(Radar)
			local Target = self.Target

			if not IsValid(Target) then return end

			local Position = Target.ACF_Position

			if self.OnRadar then
				if not Radar then return end

				local Data = Radar.Targets[Target]

				if not Data then return end

				Position = Position + Data.Spread
			end

			return Position
		end

		function CLASS:GetGuidance(Missile)
			local Radar     = self:GetRadar()
			local TargetPos = self:GetTargetPosition(Radar)

			if TargetPos and self:CheckConeLOS(Missile, Missile.ACF_Position, TargetPos, self.ViewConeCos) then
				return { TargetPos = TargetPos, ViewCone = self.ViewCone }
			end

			local NewTarget = self:UpdateTarget(Missile, Radar)

			if not NewTarget then return {} end

			return { TargetPos = NewTarget, ViewCone = self.ViewCone }
		end

		function CLASS:OnRemoved(Missile)
			BASE.OnRemoved(self, Missile)

			Missile.IsAntiMissile = nil
		end
	end

end)