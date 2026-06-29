local Fuzes = ACF.Classes.Fuzes
local Fuze  = Fuzes.Register("Radio", "Optical")

if CLIENT then
	Fuze.Description = "This fuze tracks the Guidance module's target and detonates when the distance becomes low enough.\nDistance in inches."
else
	function Fuze:GetCost()
		return 1
	end

	function Fuze:GetDetonate(Missile, Guidance)
		if not self:IsArmed() then return false end

		local Target = Guidance.TargetPos or Guidance:GetGuidance(Missile).TargetPos

		if not Target then return false end

		return Missile.ACF_Position:Distance(Target) <= self.Distance
	end
end
