include("shared.lua")

function ENT:Initialize()
	self:SetNoDraw(true)
	CreateParticleSystem(self, "burning_gib_01", PATTACH_ABSORIGIN_FOLLOW)
end

function ENT:OnRemove()
	self:StopAndDestroyParticles()
end