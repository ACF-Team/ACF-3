local ACF    = ACF
local Damage = ACF.Damage
local Clamp  = math.Clamp

--===============================================================================================--
-- Damage
--===============================================================================================--
function ENT:UpdateTorqueDamageMult()
	-- Adjusting performance based on damage
	local HealthMult = Clamp(((1 - self.TorqueScale) / 0.5) * ((self.ACF.Health / self.ACF.MaxHealth) - 1) + 1, self.TorqueScale, 1)
	if ACF.IsDestroyed(self) then HealthMult = 0 end -- Destroyed engines produce no power. This concerns the overlay more than the engine itself.

	self.PeakTorque = self.PeakTorqueHeld * HealthMult
	self.PeakPower  = self.PeakPowerHeld * HealthMult
end

-- This function needs to return HitRes
function ENT:ACF_OnDamage(DmgResult, DmgInfo)
	local HitRes = Damage.doPropDamage(self, DmgResult, DmgInfo)

	self:UpdateTorqueDamageMult()

	-- Turn off the engine if it was destroyed
	if ACF.IsDestroyed(self) then self:Disable() end

	return HitRes
end

function ENT:ACF_OnRepaired()
	-- Update the overlay once it was repaired
	self:UpdateTorqueDamageMult()
	self:UpdateOverlay()
end
