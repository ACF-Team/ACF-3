local Guidances = ACF.Classes.Guidances
local Guidance  = Guidances.Register("Dumb")

function Guidance:OnLoaded()
	self.Name = self.ID -- Workaround
end

function Guidance:Configure() end

function Guidance:WriteDisplayConfig()

end

if CLIENT then
	Guidance.Description = "This guidance package is empty and provides no control."
else
	local Countermeasures = ACF.Classes.Countermeasures

	function Guidance:GetCost()
		return 0
	end

	function Guidance:OnLaunched() end

	function Guidance:PreGuidance(Missile)
		if not self.AppliedSpawnCountermeasures then
			Countermeasures.ApplySpawnCountermeasures(Missile, self)

			self.AppliedSpawnCountermeasures = true
		end

		Countermeasures.ApplyCountermeasures(Missile, self)
	end

	function Guidance:ApplyOverride(Missile)
		if not self.Override then return end

		local Override = self.Override:GetGuidanceOverride(Missile, self)

		if Override then
			Override.ViewCone = self.ViewCone or 0
			Override.ViewConeRad = math.rad(self.ViewCone)

			return Override
		end
	end

	function Guidance:GetGuidance() return {} end

	function Guidance:OnRemoved() end
end
