include("shared.lua")

language.Add("Cleanup_acf_fueltank", "ACF Fuel Tanks")
language.Add("Cleaned_acf_fueltank", "Cleaned up all ACF Fuel Tanks")
language.Add("SBoxLimit__acf_fueltank", "You've reached the ACF Fuel Tanks limit!")

function ENT:Update()
	self.HitBoxes = {
		Main = {
			Pos = self:OBBCenter(),
			Scale = (self:OBBMaxs() - self:OBBMins()) - Vector(2, 2, 2),
			Angle = Angle(),
			Sensitive = false
		}
	}
end
