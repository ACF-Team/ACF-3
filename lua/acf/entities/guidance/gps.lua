local ACF       = ACF
local Guidances = ACF.Classes.Guidances
local Guidance  = Guidances.Register("GPS Guided", "Radio (MCLOS)")

if CLIENT then
	Guidance.Description = "This guidance package allows you to guide the munition to a desired point in the map."
else
	function Guidance:GetCost()
		return 1
	end

	function Guidance:OnLaunched(Missile)
		Guidance.BaseClass.OnLaunched(self, Missile)

		local Computer = self:GetComputer()

		if not Computer then return end
		if not Computer.IsGPS then return end
		if Computer.InputCoords == vector_origin then return end
		if Computer.IsJammed then return end

		self.TarPos = Computer.Coordinates
	end

	function Guidance:GetGuidance()
		if not self.TarPos then return end

		return { TargetPos = self.TarPos }
	end
end
