local Classes = ACF.Classes

Classes.DefineClass("ACF.Missiles.Navigation.APN", "ACF.Missiles.Navigation", function(CLASS)
	CLASS.Name = "APN"

	if CLIENT then
		CLASS.Description = "Augmented proportional navigation. Takes the relative position, velocity and acceleration into account. Applicable to most modern missiles."
	else
		function CLASS:Configure() end

		function CLASS:GetAcceleration(_, TimeToHit, RelPos, RelVel, RelAcc)
			return 9 / TimeToHit ^ 2 * (RelPos + RelVel * TimeToHit + RelAcc * TimeToHit ^ 2 * 0.5)
		end
	end
end)
