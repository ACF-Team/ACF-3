include("shared.lua")

function ENT:Initialize()
	self:SetNoDraw(true)
end

function ENT:OnRemove()
	self:StopAndDestroyParticles()
end