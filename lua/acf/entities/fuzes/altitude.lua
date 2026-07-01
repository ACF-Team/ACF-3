local ACF     = ACF
local Classes = ACF.Classes
Classes.DefineClass("ACF.Missiles.Fuze.Altitude", "ACF.Missiles.Fuze.Contact", function()
	CLASS.Name = "Altitude"
	if CLIENT then
		CLASS.Description = "This fuze tracks the guidance module's target and detonates once it crosses the altitude of the target position."
	else
		function CLASS:GetCost()
			return 0.1
		end

		function CLASS:GetDetonate(Missile, Guidance)
			if not self:IsArmed() or not Guidance then return false end

			local GuidanceResult = Guidance:GetGuidance(Missile)
			local Target = Guidance.TargetPos or (GuidanceResult and GuidanceResult.TargetPos)
			if not Target then return false end

			local TargetElevation = Target.z
			local MissileElevation = Missile:GetPos().z

			return MissileElevation >= TargetElevation
		end
	end
end)