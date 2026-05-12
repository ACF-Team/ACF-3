local Guidances = ACF.Classes.Guidances
local Guidance  = Guidances.Register("Radio (SACLOS)", "Radio (MCLOS)")

if CLIENT then
	Guidance.Description = "This guidance package allows you to control the direction of the missile using a computer's aiming position."
else
	local ZERO = Vector()

	function Guidance:GetCost()
		return 2
	end

	function Guidance:CheckComputer()
		local Computer = self:GetComputer()

		if not Computer then return end
		if not Computer.IsComputer then return end
		if Computer.HitPos == ZERO then return end

		return Computer.HitPos
	end

	function Guidance:GetGuidance(Missile)
		if not self:CheckLOS(Missile) then return {} end

		local HitPos = self:CheckComputer()

		return { TargetPos = HitPos }
	end
end
