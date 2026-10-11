local ACF    = ACF
local Damage = ACF.Damage
local Clamp  = math.Clamp

--===============================================================================================--
-- Damage
--===============================================================================================--
function ENT:UpdateTorqueDamageMult()
	-- Adjusting performance based on damage
	local TorqueMult = Clamp(((1 - self.TorqueScale) / 0.5) * ((self.ACF.Health / self.ACF.MaxHealth) - 1) + 1, self.TorqueScale, 1)
	if self.ACF.Health <= 0 then TorqueMult = 0 end

	self.PeakTorque = self.PeakTorqueHeld * TorqueMult
end

--This function needs to return HitRes
function ENT:ACF_OnDamage(DmgResult, DmgInfo)
	local HitRes = Damage.doPropDamage(self, DmgResult, DmgInfo)

	self:UpdateTorqueDamageMult()

	-- Turn off the engine if it was destroyed
	if self.ACF.Health <= 0 then
		self.IsDestroyed = true
		self:Disable()
	end

	return HitRes
end

function ENT:ACF_OnRepaired()
	self:UpdateTorqueDamageMult()

	-- Restore engine state if it was destroyed
	if self.ACF.Health >= self.ACF.MaxHealth and self.IsDestroyed then
		self.IsDestroyed = false
		self:UpdateOverlay()
	end
end
