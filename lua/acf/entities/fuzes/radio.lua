local Classes = ACF.Classes
Classes.DefineClass("ACF.Missiles.Fuze.Radio", "ACF.Missiles.Fuze.Optical", function(CLASS)
	CLASS.Name = "Radio"
	-- Shared so the ammo menu can price missile rounds clientside.
	function CLASS:GetCost()
		return 1
	end

	if CLIENT then
		CLASS.Description = "This fuze tracks the Guidance module's target and detonates when the distance becomes low enough.\nDistance in inches."
	else

		function CLASS:GetDetonate(Missile, Guidance)
			if not self:IsArmed() then return false end

			local Target = Guidance.TargetPos or Guidance:GetGuidance(Missile).TargetPos

			if not Target then return false end

			return Missile.ACF_Position:Distance(Target) <= self.Distance
		end
	end
end)