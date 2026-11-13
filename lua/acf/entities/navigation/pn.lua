local Classes = ACF.Classes

Classes.DefineClass("ACF.Missiles.Navigation.PN", "ACF.Missiles.Navigation", function(CLASS)
	CLASS.Name = "PN"

	if CLIENT then
		CLASS.Description = "Proportional navigation. Takes the relative position and velocity into account. Applicable to early generation missiles."
	else
		function CLASS:Configure() end

		function CLASS:GetAcceleration(_, TimeToHit, RelPos, RelVel)
			return 9 / TimeToHit ^ 2 * (RelPos + RelVel * TimeToHit)
		end
	end
end)
