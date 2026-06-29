local ACF       = ACF
local Damage    = ACF.Damage
local Objects   = Damage.Objects
local Utilities = ACF.Utilities
local Clock     = Utilities.Clock
local WireLib   = WireLib
local Clamp     = math.Clamp
local HookRun   = hook.Run

local BaseThink = ENT.Think


function ENT:ACF_OnDamage(DmgResult, DmgInfo)
	local HitRes = Damage.doPropDamage(self, DmgResult, DmgInfo)

	if self.Exploding then return HitRes end

	local Inflictor = DmgInfo:GetInflictor()
	local Attacker  = DmgInfo:GetAttacker()

	if HitRes.Kill then
		local CanExplode = HookRun("ACF_PreExplodeSupply", self)

		if not CanExplode then return HitRes end

		if IsValid(Attacker) and Attacker:IsPlayer() then
			self.Attacker = Attacker
		end

		if IsValid(Inflictor) and Inflictor:IsPlayer() then
			self.Inflictor = Inflictor
		end

		self:Detonate()

		return HitRes
	end

	local Ratio = (HitRes.Damage / self.ACF.Health) ^ 0.75

	if math.random() < Ratio then
		local CanExplode = HookRun("ACF_PreExplodeSupply", self)

		if not CanExplode then return HitRes end

		self.Attacker  = Attacker
		self.Inflictor = Inflictor

		self:Detonate()
	else
		self.Leaking = (self.Leaking or 0) + self.Amount * ((HitRes.Damage / self.ACF.Health) ^ 1.5) * 0.25

		WireLib.TriggerOutput(self, "Leaking", 1)

		self:NextThink(Clock.CurTime + 0.1)
	end

	return HitRes
end

function ENT:Detonate()
	if self.Exploding then return end

	self.Exploding = true

	local Position  = self:LocalToWorld(self:OBBCenter() + VectorRand() * (self:OBBMaxs() - self:OBBMins()) / 2)
	local Explosive = math.max(self.Amount, self.Capacity * 0.0025) * 0.1
	local DmgInfo   = Objects.DamageInfo(self.Attacker or self, self.Inflictor)

	ACF.KillChildProps(self, Position, Explosive)

	Damage.createExplosion(Position, Explosive, Explosive * 0.5, { self }, DmgInfo)
	Damage.explosionEffect(Position, nil, Explosive)

	constraint.RemoveAll(self)
	self:Remove()
end

function ENT:Think()
	local Leaking = self.Leaking

	if Leaking and Leaking > 0 then
		self:Consume(Leaking)

		local Amount = self.Amount
		Leaking = Clamp(Leaking - (1 / math.max(Amount, 1)) ^ 0.5, 0, Amount)
		self.Leaking = Leaking

		WireLib.TriggerOutput(self, "Leaking", Leaking > 0 and 1 or 0)
	end

	local Result = BaseThink(self)

	if Leaking and Leaking > 0 then
		self:NextThink(Clock.CurTime + 0.25)
		return true
	end

	return Result
end
