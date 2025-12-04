local ACF         = ACF
local Damage      = ACF.Damage
local Objects     = ACF.Damage.Objects
local Utilities   = ACF.Utilities
local Clock       = Utilities.Clock
local Sounds      = Utilities.Sounds
local TimerCreate = timer.Create

local function CookoffCrate(Entity)
	if Entity.Ammo < 1 or Entity.Burning < Clock.CurTime then -- Detonate when time is up or crate is out of ammo
		timer.Remove("ACF Crate Cookoff " .. Entity:EntIndex())

		Entity.Burning = nil

		Entity:Detonate()
	elseif Entity.BulletData.Type ~= "Refill" and Entity.RoundData then -- Spew bullets out everywhere
		local BulletData = Entity.BulletData
		local VolumeRoll = math.Rand(0, 150) > math.min(BulletData.RoundVolume ^ 0.5, 150 * 0.25) -- The larger the round volume, the less the chance of detonation (25% chance at minimum)
		local AmmoRoll   = math.Rand(0, 1) <= Entity.Ammo / math.max(Entity.Capacity, 1) -- The fuller the crate, the greater the chance of detonation

		if VolumeRoll and AmmoRoll then
			local Speed = ACF.MuzzleVelocity(BulletData.PropMass * 0.5, BulletData.ProjMass, BulletData.Efficiency) -- Half propellant projectile
			local Pitch = math.max(255 - BulletData.PropMass * 100, 60) -- Pitch based on propellant mass

			Sounds.SendSound(Entity, "ambient/explosions/explode_4.wav", 140, Pitch, 1)

			BulletData.Pos       = Entity:LocalToWorld(Entity:OBBCenter() + VectorRand() * Entity:GetSize() * 0.5) -- Random position in the ammo crate
			BulletData.Flight    = VectorRand():GetNormalized() * Speed * ACF.MeterToInch + Entity:GetAncestor():GetVelocity() -- Random direction including baseplate speed
			BulletData.IsCookOff = true

			BulletData.Owner  = Entity.Inflictor or Entity.Owner
			BulletData.Gun    = Entity
			BulletData.Crate  = Entity:EntIndex()

			Entity.RoundData:Create(Entity, BulletData)

			Entity:Consume()
		end
	end
end


function ENT:ACF_OnDamage(DmgResult, DmgInfo)
	local HitRes = Damage.doPropDamage(self, DmgResult, DmgInfo) -- Calling the standard damage prop function

	if self.Exploding then return HitRes end

	local Inflictor, Attacker = DmgInfo.Inflictor, DmgInfo.Attacker

	-- If killed: detonate immediately
	if HitRes.Kill then
		self.Attacker  = Attacker
		self.Inflictor = Inflictor

		if self.Amount > 0 then
			self:Detonate()
		end

		return HitRes
	end

	-- If not killed: Roll dice to cook off
	if self.Burning then return HitRes end -- Already cooking off

	local Ratio = (HitRes.Damage / self.BulletData.RoundVolume) ^ 0.2

	if (Ratio * self.Capacity / self.Amount) > math.random() then
		local CanBurn = hook.Run("ACF_PreBurnAmmo", self)

		self.Attacker = Attacker
		self.Inflictor = Inflictor

		if CanBurn then
			self.Burning = Clock.CurTime + (5 - Ratio * 3) -- Time to cook off is 5 - (How filled it is * 3)

			local Interval = 0.01 + self.BulletData.RoundVolume ^ 0.5 / 100

			TimerCreate("ACF Crate Cookoff " .. self:EntIndex(), Interval, 0, function()
				if not IsValid(self) then return end

				CookoffCrate(self)
			end)
		else
			self:Detonate()
		end
	end

	return HitRes
end

function ENT:Detonate(VisualOnly)
	if self.Exploding then return end

	local CanExplode = hook.Run("ACF_PreExplodeAmmo", self)

	if not CanExplode then return end

	self.Exploding = true

	local Position   = self:LocalToWorld(self:OBBCenter() + VectorRand() * self:GetSize() * 0.5) -- Random position within the crate
	local BulletData = self.BulletData
	local Filler     = BulletData.FillerMass or 0
	local Propellant = BulletData.PropMass or 0
	local AmmoPower  = self.Ammo ^ 0.7 -- Arbitrary exponent to reduce ammo-based explosive power
	local Explosive  = (Filler + Propellant * (ACF.PropImpetus / ACF.HEPower)) * AmmoPower
	local FragMass   = BulletData.ProjMass or Explosive * 0.5
	local DmgInfo    = Objects.DamageInfo(self.Attacker or self, self.Inflictor)

	ACF.KillChildProps(self, Position, Explosive)

	if not VisualOnly then
		Damage.createExplosion(Position, Explosive, FragMass, { self }, DmgInfo)
	end

	Damage.explosionEffect(Position, nil, Explosive)

	constraint.RemoveAll(self)

	self:Remove()
end