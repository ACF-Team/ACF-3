local ACF = ACF
local Damage = ACF.Damage
local Objects = Damage.Objects
local Utilities = ACF.Utilities
local Clock = Utilities.Clock
local Clamp = math.Clamp
local HookRun = hook.Run

--- Handles damage to fuel tanks
--- Determines if tank should explode or leak based on damage
function ENT:ACF_OnDamage(DmgResult, DmgInfo)
	local HitRes    = Damage.doPropDamage(self, DmgResult, DmgInfo)
	local Inflictor = DmgInfo:GetInflictor()
	local NoExplode = self.FuelType == "Diesel"

	if self.Exploding or NoExplode or not self.IsExplosive then return HitRes end

	local Attacker  = DmgInfo:GetAttacker()

	if HitRes.Kill then
		local CanExplode = HookRun("ACF_PreExplodeFuel", self)

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

	local Ratio = (HitRes.Damage / self.ACF.Health) ^ 0.75 -- Chance to explode from sheer damage, small shots = small chance
	local ExplodeChance = (1 - (self.Amount / self.Capacity)) ^ 0.75 -- Chance to explode from fumes in tank, less fuel = more explodey

	-- It's gonna blow
	if math.random() < (ExplodeChance + Ratio) then
		local CanExplode = HookRun("ACF_PreExplodeFuel", self)

		if not CanExplode then return HitRes end

		self.Attacker = Attacker
		self.Inflictor = Inflictor

		self:Detonate()
	else -- Spray some fuel around
		self.Leaking = self.Leaking + self.Amount * ((HitRes.Damage / self.ACF.Health) ^ 1.5) * 0.25

		WireLib.TriggerOutput(self, "Leaking", self.Leaking > 0 and 1 or 0)

		self:NextThink(Clock.CurTime + 0.1)
	end

	return HitRes
end

--- Detonates the fuel tank, creating an explosion
function ENT:Detonate()
	if self.Exploding then return end

	self.Exploding = true -- Prevent multiple explosions

	local Position  = self:LocalToWorld(self:OBBCenter() + VectorRand() * (self:OBBMaxs() - self:OBBMins()) / 2)
	local Explosive = (math.max(self.Amount, self.Capacity * 0.0025) / self.FuelDensity) * 0.1
	local DmgInfo   = Objects.DamageInfo(self.Attacker or self, self.Inflictor)

	ACF.KillChildProps(self, Position, Explosive)

	Damage.createExplosion(Position, Explosive, Explosive * 0.5, { self }, DmgInfo)
	Damage.explosionEffect(Position, nil, Explosive)

	constraint.RemoveAll(self)
	self:Remove()
end

--- Only runs when the tank is leaking
function ENT:Think()
	local Leaking = self.Leaking

	if Leaking > 0 then
		self:Consume(Leaking)

		local Amount = self.Amount

		Leaking = Clamp(Leaking - (1 / math.max(Amount, 1)) ^ 0.5, 0, Amount) -- Fuel tanks are self healing

		self.Leaking = Leaking

		WireLib.TriggerOutput(self, "Leaking", Leaking > 0 and 1 or 0)

		self.LastThink = Clock.CurTime

		if Leaking > 0 then
			self:NextThink(Clock.CurTime + 0.25)
			return true
		end
	end

	-- Stop thinking when not leaking
	return false
end



