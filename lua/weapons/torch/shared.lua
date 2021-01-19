AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
--include('shared.lua')
SWEP.Weight = 5
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.AdminSpawnable = true
SWEP.Author = "Lazermaniac"
SWEP.Contact = "lazermaniac@gmail.com"
SWEP.Instructions = "Primary to repair.\nSecondary to damage."
SWEP.Primary.Ammo = "none"
SWEP.Primary.Automatic = true
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Purpose = "Used to clear baricades and repair vehicles."
SWEP.Secondary.Ammo = "none"
SWEP.Secondary.Automatic = true
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Spawnable = true
SWEP.ViewModelFlip = false
SWEP.ViewModelFOV = 55
SWEP.ViewModel = "models/weapons/v_cuttingtorch.mdl"
SWEP.WorldModel = "models/weapons/w_cuttingtorch.mdl"
SWEP.PrintName = "ACF Cutting Torch"
SWEP.Slot = 0
SWEP.SlotPos = 6
SWEP.IconLetter = "G"
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true
SWEP.MaxDistance = 64 * 64 -- Squared distance

local Spark = "ambient/energy/NewSpark0%s.wav"
local Zap   = "weapons/physcannon/superphys_small_zap%s.wav"

local function TeslaSpark(pos, magnitude)
	zap = ents.Create("point_tesla")
	zap:SetKeyValue("targetname", "teslab")
	zap:SetKeyValue("m_SoundName", "null")
	zap:SetKeyValue("texture", "sprites/laser.spr")
	zap:SetKeyValue("m_Color", "200 200 255")
	zap:SetKeyValue("m_flRadius", tostring(magnitude * 10))
	zap:SetKeyValue("beamcount_min", tostring(math.ceil(magnitude)))
	zap:SetKeyValue("beamcount_max", tostring(math.ceil(magnitude)))
	zap:SetKeyValue("thick_min", tostring(magnitude))
	zap:SetKeyValue("thick_max", tostring(magnitude))
	zap:SetKeyValue("lifetime_min", "0.05")
	zap:SetKeyValue("lifetime_max", "0.1")
	zap:SetKeyValue("interval_min", "0.05")
	zap:SetKeyValue("interval_max", "0.08")
	zap:SetPos(pos)
	zap:Spawn()
	zap:Fire("DoSpark", "", 0)
	zap:Fire("kill", "", 0.1)
end

function SWEP:Initialize()
	if SERVER then
		self:SetWeaponHoldType("pistol") --"357 hold type doesnt exist, it's the generic pistol one" Kaf
		self.LastDistance = 0
		self.LastTrace = {}
	end

	util.PrecacheSound("ambient/energy/NewSpark03.wav")
	util.PrecacheSound("ambient/energy/NewSpark04.wav")
	util.PrecacheSound("ambient/energy/NewSpark05.wav")
	util.PrecacheSound("weapons/physcannon/superphys_small_zap1.wav")
	util.PrecacheSound("weapons/physcannon/superphys_small_zap2.wav")
	util.PrecacheSound("weapons/physcannon/superphys_small_zap3.wav")
	util.PrecacheSound("weapons/physcannon/superphys_small_zap4.wav")
	util.PrecacheSound("items/medshot4.wav")
end

function SWEP:Think()
	if CLIENT then return end

	local Health, MaxHealth, Armor, MaxArmor = 0, 0, 0, 0
	local Trace = self:GetOwner():GetEyeTrace()
	local Entity = Trace.Entity

	self.LastDistance = Trace.StartPos:DistToSqr(Trace.HitPos)
	self.LastTrace = Trace

	if ACF.Check(Entity) and self.LastDistance <= self.MaxDistance then
		if Entity:IsPlayer() or Entity:IsNPC() then
			Health = Entity:Health()
			MaxHealth = Entity:GetMaxHealth()

			if isfunction(Entity.Armor) then
				Armor = Entity:Armor()
				MaxArmor = 100
			end
		else
			Health = Entity.ACF.Health
			MaxHealth = Entity.ACF.MaxHealth
			Armor = Entity.ACF.Armour
			MaxArmor = Entity.ACF.MaxArmour
		end
	end

	if Entity ~= self.LastEntity or Health ~= self.LastHealth or Armor ~= self.LastArmor then
		self.LastEntity = Entity
		self.LastHealth = Health
		self.LastArmor = Armor

		self:SetNWFloat("HP", Health)
		self:SetNWFloat("MaxHP", MaxHealth)
		self:SetNWFloat("Armour", Armor)
		self:SetNWFloat("MaxArmour", MaxArmor)
	end

	self:NextThink(ACF.CurTime + 0.05)
end

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire(ACF.CurTime + 0.05)

	if CLIENT then return end

	if self.LastDistance > self.MaxDistance then return end

	local Entity = self.LastEntity
	local Trace = self.LastTrace
	local Owner = self:GetOwner()

	if ACF.Check(Entity) then
		if Entity:IsPlayer() or Entity:IsNPC() then
			local Health = Entity:Health()
			local MaxHealth = Entity:GetMaxHealth()

			if Health <= 0 then return end
			if Health >= MaxHealth then return end

			Health = math.min(Health + 1, MaxHealth)

			Entity:SetHealth(Health)

			local AngPos = Owner:GetAttachment(4)
			local Effect = EffectData()
				Effect:SetOrigin(AngPos.Pos + Trace.Normal * 10)
				Effect:SetNormal(Trace.Normal)
				Effect:SetEntity(self)
			util.Effect("thruster_ring", Effect, true, true)

			Entity:EmitSound("items/medshot4.wav", nil, nil, ACF.Volume)
		else
			if CPPI and not Entity:CPPICanTool(Owner, "torch") then return end

			local OldHealth = Entity.ACF.Health
			local MaxHealth = Entity.ACF.MaxHealth

			if OldHealth >= MaxHealth then return end

			local OldArmor = Entity.ACF.Armour
			local MaxArmor = Entity.ACF.MaxArmour

			local Health = math.min(OldHealth + (30 / MaxArmor), MaxHealth)
			local Armor = MaxArmor * (0.5 + Health / MaxHealth * 0.5)

			Entity.ACF.Health = Health
			Entity.ACF.Armour = Armor

			if Entity.ACF_OnRepaired then
				Entity:ACF_OnRepaired(OldArmor, OldHealth, Armor, Health)
			end

			Entity:EmitSound(Spark:format(math.random(3, 5)), nil, nil, ACF.Volume)
			TeslaSpark(Trace.HitPos, 1)
		end
	end
end

local Energy = { Kinetic = 5, Momentum = 0, Penetration = 5 }

function SWEP:SecondaryAttack()
	self:SetNextPrimaryFire(ACF.CurTime + 0.05)

	if CLIENT then return end

	if self.LastDistance > self.MaxDistance then return end

	local Entity = self.LastEntity
	local Trace = self.LastTrace
	local Owner = self:GetOwner()

	if ACF.Check(Entity) then
		local HitRes = {}

		if Entity:IsPlayer() or Entity:IsNPC() then
			--We can use the damage function instead of direct access here since no numbers are negative.
			HitRes = ACF_Damage(Entity, Energy, 2, 0, Owner, 0, self, "Torch")
		else
			if CPPI and not Entity:CPPICanTool(Owner, "torch") then return end

			--We can use the damage function instead of direct access here since no numbers are negative.
			HitRes = ACF_Damage(Entity, Energy, 2, 0, Owner, 0, self, "Torch")
		end

		if HitRes.Kill then
			ACF_APKill(Entity, Trace.Normal, 1)
		else
			local Effect = EffectData()
				Effect:SetMagnitude(1)
				Effect:SetRadius(1)
				Effect:SetScale(1)
				Effect:SetStart(Trace.HitPos)
				Effect:SetOrigin(Trace.HitPos)
			util.Effect("Sparks", Effect, true, true)

			Entity:EmitSound(Zap:format(math.random(1, 4)), nil, nil, ACF.Volume)
		end
	end
end

function SWEP:Reload()
end
