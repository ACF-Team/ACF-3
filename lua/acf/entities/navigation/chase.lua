local Classes = ACF.Classes

Classes.DefineClass("ACF.Missiles.Navigation.Chase", "ACF.Missiles.Navigation", function(CLASS)
	CLASS.Name = "Chase"

	if CLIENT then
		CLASS.Description = "Simply steers itself towards the target. Applicable to anti radiation missiles, and others not needing lead."
	else
		function CLASS:Configure() end

		function CLASS:GetAcceleration(_, TimeToHit, RelPos)
			return 9 / TimeToHit ^ 2 * RelPos
		end
	end
end)
