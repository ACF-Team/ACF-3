local Classes 	= ACF.Classes
Classes.DefineClass("ACF.Missiles.Guidance.Dumb", "ACF.Missiles.Guidance", function()
	function CLASS:OnLoaded()
		self.Name = self.ID -- Workaround
	end

	function CLASS:Configure() end

	function CLASS:WriteDisplayConfig()

	end

	if CLIENT then
		CLASS.Description = "This guidance package is empty and provides no control."
	else
		local Countermeasures = ACF.Classes.Countermeasures

		function CLASS:GetCost()
			return 0
		end

		function CLASS:OnLaunched() end

		function CLASS:PreGuidance(Missile)
			if not self.AppliedSpawnCountermeasures then
				Countermeasures.ApplySpawnCountermeasures(Missile, self)

				self.AppliedSpawnCountermeasures = true
			end

			Countermeasures.ApplyCountermeasures(Missile, self)
		end

		function CLASS:ApplyOverride(Missile)
			if not self.Override then return end

			local Override = self.Override:GetGuidanceOverride(Missile, self)

			if Override then
				Override.ViewCone = self.ViewCone or 0
				Override.ViewConeRad = math.rad(self.ViewCone)

				return Override
			end
		end

		function CLASS:GetGuidance() return {} end

		function CLASS:OnRemoved() end
	end

end)