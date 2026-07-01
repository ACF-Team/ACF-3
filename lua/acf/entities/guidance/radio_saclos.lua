local Classes 	= ACF.Classes
Classes.DefineClass("ACF.Missiles.Guidance.RadioSACLOS", "ACF.Missiles.Guidance.RadioMCLOS", function()
	CLASS.Name = "Radio (SACLOS)"
	if CLIENT then
		CLASS.Description = "This guidance package allows you to control the direction of the missile using a computer's aiming position."
	else
		local ZERO = Vector()

		function CLASS:GetCost()
			return 2
		end

		function CLASS:CheckComputer()
			local Computer = self:GetComputer()

			if not Computer then return end
			if not Computer.IsComputer then return end
			if Computer.HitPos == ZERO then return end

			return Computer.HitPos
		end

		function CLASS:GetGuidance(Missile)
			if not self:CheckLOS(Missile) then return {} end

			local HitPos = self:CheckComputer()

			return { TargetPos = HitPos }
		end
	end
end)