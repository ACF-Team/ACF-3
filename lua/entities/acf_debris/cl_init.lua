include("shared.lua")

function ENT:Initialize()
	self:CreateParticleEffect("burning_gib_01")
	self:SetNoDraw(true)
end

function ENT:OnRemove()
	self:StopAndDestroyParticles()
end