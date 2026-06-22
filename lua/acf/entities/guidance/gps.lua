local ACF       = ACF
local Classes 	= ACF.Classes
Classes.DefineClass("ACF.Missiles.Guidance.GPSGuided", "ACF.Missiles.Guidance.RadioMCLOS", function()
	local BASE = BASE
	if CLIENT then
		CLASS.Description = "This guidance package allows you to guide the munition to a desired point in the map."
	else
		function CLASS:GetCost()
			return 1
		end

		function CLASS:OnLaunched(Missile)
			BASE.OnLaunched(self, Missile)

			local Computer = self:GetComputer()

			if not Computer then return end
			if not Computer.IsGPS then return end
			if Computer.InputCoords == vector_origin then return end
			if Computer.IsJammed then return end

			self.TarPos = Computer.Coordinates
		end

		function CLASS:GetGuidance()
			if not self.TarPos then return end

			return { TargetPos = self.TarPos }
		end
	end
end)