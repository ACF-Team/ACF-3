local Classes = ACF.Classes
Classes.DefineClass("ACF.Missiles.Fuze.Radio", "ACF.Missiles.Fuze.Optical", function()
	if CLIENT then
		CLASS.Description = "This fuze tracks the Guidance module's target and detonates when the distance becomes low enough.\nDistance in inches."
	else
		function CLASS:GetCost()
			return 1
		end

		function CLASS:GetDetonate(Missile, Guidance)
			if not self:IsArmed() then return false end

			local Target = Guidance.TargetPos or Guidance:GetGuidance(Missile).TargetPos

			if not Target then return false end

			return Missile.ACF_Position:Distance(Target) <= self.Distance
		end
	end
end)