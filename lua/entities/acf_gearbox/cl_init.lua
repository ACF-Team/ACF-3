include("shared.lua")

language.Add("Cleanup_acf_gearbox", "ACF Gearboxes")
language.Add("Cleaned_acf_gearbox", "Cleaned up all ACF Gearboxes")
language.Add("SBoxLimit__acf_gearbox", "You've reached the ACF Gearboxes limit!")

function ENT:Update()
	self.HitBoxes = ACF.GetHitboxes(self:GetModel())
end
