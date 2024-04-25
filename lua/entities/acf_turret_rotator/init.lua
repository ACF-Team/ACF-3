include("shared.lua")

ACF.Contraption.AddParentDetour("acf_turret_rotator", "Turret")

-- One can't exist without the other
function ENT:OnRemove()
	if IsValid(self.Turret) then
		self.Turret:Remove()
	end
end

-- This shouldn't be called usually due to parent detouring, but in the offchance that this is ever directly unparented from the turret ring, destroy it and the turret entity since it is no longer a valid turret
function ENT:ACF_OnParented(Entity, Connected)
	if not IsValid(Entity) then return end

	if Connected == false and Entity == self.Turret then self:Remove() end
end

function ENT:UpdateTransmitState()
	return TRANSMIT_PVS
end