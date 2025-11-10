local ACF = ACF
local Damage = ACF.Damage
local Utilities = ACF.Utilities
local Clock = Utilities.Clock
local Sounds = Utilities.Sounds
local TimerCreate = timer.Create
local TimerRemove = timer.Remove


local function CookoffCrate(Entity)
	if Entity.Amount < 1 or Entity.Damaged < Clock.CurTime then -- Detonate when time is up or crate is out of ammo
		TimerRemove("ACF Crate Cookoff " .. Entity:EntIndex())

		Entity.Damaged = nil

		Entity:Detonate()
	elseif Entity.RoundData then -- Spew bullets out everywhere
		local BulletData = Entity.BulletData
		local VolumeRoll = math.Rand(0, 150) > math.min(BulletData.RoundVolume ^ 0.5, 150 * 0.25) -- The larger the round volume, the less the chance of detonation (25% chance at minimum)
		local AmmoRoll   = math.Rand(0, 1) <= Entity.Amount / math.max(Entity.Capacity, 1) -- The fuller the crate, the greater the chance of detonation

		if VolumeRoll and AmmoRoll then
			local Speed = BulletData.MuzzleVel * 0.5 + math.Rand(0, BulletData.MuzzleVel)
			local Inaccuracy = math.VRand():GetNormalized() * (math.random() ^ 0.5) * (1 - BulletData.FrArea / BulletData.ProjArea)

			BulletData.Owner = Entity.Inflictor
			BulletData.Gun = Entity

			Entity.RoundData:Create(Entity, VectorRand():GetNormalized() + Inaccuracy, Speed)

			Entity:Consume(1)

			Sounds.SendSound(Entity, "ambient/explosions/explode_4.wav", 100, math.Rand(75, 100), ACF.Volume)

			local Effect = EffectData()
			Effect:SetOrigin(Entity:GetPos())
			Effect:SetNormal(VectorRand():GetNormalized())
			Effect:SetScale(math.max(BulletData.RoundVolume ^ 0.5 * 0.5, 1))
			Effect:SetMagnitude(2)

			util.Effect("ACF_Cookoff", Effect)
		end
	end
end


function ENT:ACF_OnDamage(DmgResult, DmgInfo)
	local HitRes = ACF.PropDamage(self, DmgResult, DmgInfo) -- Calling the standard damage prop function

	local Inflictor = DmgInfo.Inflictor
	local Attacker = DmgInfo.Attacker

	-- Cookoff chance
	if self.Damaged then return HitRes end -- Already cooking off

	local Ratio = (HitRes.Damage / self.BulletData.RoundVolume) ^ 0.2

	if (Ratio * self.Capacity / self.Amount) > math.random() then
		local CanBurn = hook.Run("ACF_PreBurnAmmo", self)

		self.Attacker = Attacker
		self.Inflictor = Inflictor

		if CanBurn then
			self.Damaged = Clock.CurTime + (5 - Ratio * 3) -- Time to cook off is 5 - (How filled it is * 3)

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

function ENT:Detonate()
	local Position = self:GetPos()

	local AmmoPower = self.Amount ^ 0.7
	local BulletPower = self.BulletData.FillerMass or 0
	local Explosive = AmmoPower * BulletPower * 0.25

	local FragMass = self.BulletData.ProjMass or 0

	local DmgInfo = {
		Attacker = self.Attacker or self,
		Inflictor = self.Inflictor or self,
	}

	ACF.KillChildProps(self, Position, Explosive)
	Damage.createExplosion(Position, Explosive, FragMass, { self }, DmgInfo)
	Damage.explosionEffect(Position, nil, Explosive)

	constraint.RemoveAll(self)

	self:Remove()
end

