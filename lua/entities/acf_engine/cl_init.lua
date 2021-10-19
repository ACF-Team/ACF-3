include("shared.lua")

language.Add("Cleanup_acf_engine", "ACF Engines")
language.Add("Cleaned_acf_engine", "Cleaned up all ACF Engines")
language.Add("SBoxLimit__acf_engine", "You've reached the ACF Engines limit!")

function ENT:Update()
	self.HitBoxes = ACF.GetHitboxes(self:GetModel())
end
