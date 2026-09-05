local Guidances = ACF.Classes.Guidances
local Guidance  = Guidances.Register("Radio (SACLOS)", "Radio (MCLOS)")

-- Shared so the ammo menu can price missile rounds clientside.
function Guidance:GetCost()
	return 5
end

if CLIENT then
	Guidance.Description = "This guidance package allows you to control the direction of the missile using a computer's aiming position."
else
	local ZERO = Vector()

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
