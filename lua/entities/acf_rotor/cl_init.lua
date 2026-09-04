include("shared.lua")

DEFINE_BASECLASS("acf_base_scalable")

function ENT:Update()
	self.HitBoxes = ACF.GetHitboxes(self:GetModel())
end

function ENT:Draw()
	BaseClass.Draw(self)
end
