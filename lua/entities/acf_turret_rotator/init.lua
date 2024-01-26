include("shared.lua")

ACF.Contraption.AddParentDetour("acf_turret_rotator", "turret")

function ENT:Initialize(turret)
	self.turret = turret or self:GetParent()
end

function ENT:OnRemove()
	if IsValid(self.turret) then
		self.turret:Remove()
	end
end

function ENT:UpdateTransmitState()
	return TRANSMIT_PVS
end