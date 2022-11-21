AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

local ACF     = ACF
local Clock   = ACF.Utilities.Clock
local Damage  = ACF.Damage
local Objects = Damage.Objects
local Spark   = "ambient/energy/NewSpark0%s.wav"
local Zap     = "weapons/physcannon/superphys_small_zap%s.wav"

SWEP.Author = "Lazermaniac"
SWEP.Contact = "lazermaniac@gmail.com"
SWEP.Instructions = "Primary to repair.\nSecondary to damage."
SWEP.Purpose = "Used to clear barricades and repair vehicles."

SWEP.Weight = 5
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.AdminSpawnable = true
SWEP.Primary.Ammo = "none"
SWEP.Primary.Automatic = true
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Secondary.Ammo = "none"
SWEP.Secondary.Automatic = true
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Spawnable = true
SWEP.UseHands = true
SWEP.ViewModelFlip = false
SWEP.ViewModelFOV = 55
SWEP.ViewModel = "models/weapons/c_cuttingtorch.mdl"
SWEP.WorldModel = "models/weapons/w_cuttingtorch.mdl"
SWEP.PrintName = "ACF Cutting Torch"
SWEP.Slot = 0
SWEP.SlotPos = 6
SWEP.IconLetter = "G"
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true
SWEP.DrawWeaponInfoBox = false
SWEP.BounceWeaponIcon = false
SWEP.MaxDistance = 64 * 64 -- Squared distance


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

function SWEP:SetupDataTables()
	self:NetworkVar("Float", 0, "AnimationTime")
	self:NetworkVar("Int", 1, "AnimPriority")
	self:NetworkVar("String", 0, "CurrentAnim")
end

function SWEP:Initialize()
	util.PrecacheSound("ambient/energy/NewSpark03.wav")
	util.PrecacheSound("ambient/energy/NewSpark04.wav")
	util.PrecacheSound("ambient/energy/NewSpark05.wav")
	util.PrecacheSound("weapons/physcannon/superphys_small_zap1.wav")
	util.PrecacheSound("weapons/physcannon/superphys_small_zap2.wav")
	util.PrecacheSound("weapons/physcannon/superphys_small_zap3.wav")
	util.PrecacheSound("weapons/physcannon/superphys_small_zap4.wav")
	util.PrecacheSound("items/medshot4.wav")
	util.PrecacheSound("ambient/energy/zap2.wav")

	if CLIENT then return end

	self:SetWeaponHoldType("pistol") -- "357 hold type doesn't exist, it's the generic pistol one" Kaf

	self.LastDistance = 0
	self.LastTrace    = {}
	self.DamageResult = Objects.DamageResult(math.pi * 0.5 ^ 2, 10)
	self.DamageInfo   = Objects.DamageInfo(self, self:GetOwner(), "Torch")
end

function SWEP:SetAnim(anim, forceplay, animpriority)
	local IsIdle = self:GetCurrentAnim() == "idle01" or self:GetAnimationTime() < CurTime()
	if forceplay == nil then
		forceplay = false
	end
	if animpriority == nil then
		animpriority = 0
	end

	if IsIdle or (forceplay and self:GetAnimPriority() <= animpriority) then
		local vm = self:GetOwner():GetViewModel()
		self:SetCurrentAnim(anim)
		vm:SendViewModelMatchingSequence(vm:LookupSequence(anim))
		self:SetAnimationTime(CurTime() + vm:SequenceDuration() / vm:GetPlaybackRate())
		self:SetAnimPriority(animpriority)
	end
end

function SWEP:Deploy()
	self:SetCurrentAnim("none") -- Prevents nil anim value
	self:EmitSound("ambient/energy/zap2.wav", nil, nil, ACF.Volume)
	return true
end

function SWEP:Holster()
	self:SetAnim("holster", true, 1)
	return true
end

function SWEP:Think()
	local Owner = self:GetOwner()
	local PlyVel = Owner:GetVelocity():Length()
	local IsMoving = Owner:KeyDown(IN_FORWARD or IN_BACK or IN_MOVELEFT or IN_MOVERIGHT)

	if self:GetAnimationTime() ~= 0 and self:GetAnimationTime() < CurTime() then
		self:SetAnimationTime(0)
		self:SetAnimPriority(0)
	end

	if CLIENT and not IsMoving then return end
	if CLIENT and Owner:WaterLevel() >= 2 then return end

	if Owner:OnGround() and PlyVel > Owner:GetRunSpeed() * 0.9 then
		if self:GetCurrentAnim() ~= "sprint" then
			self:SetAnim("sprint", true)
		end
	elseif Owner:OnGround() and PlyVel > Owner:GetWalkSpeed() * 0.9 then
		if self:GetCurrentAnim() ~= "walk" then
			self:SetAnim("walk", true)
		end
	else
		local force = false

		-- Force if we were previously walking
		if self:GetCurrentAnim() ~= "sprint" or self:GetCurrentAnim() ~= "walk" then
			force = true
		end

		if self:GetCurrentAnim() ~= "idle01" then
			self:SetAnim("idle01", force)
		end
	end

	if CLIENT then return end

	local Health, MaxHealth, Armor, MaxArmor = 0, 0, 0, 0
	local Trace = Owner:GetEyeTrace()
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

	self:NextThink(Clock.CurTime + 0.05)
end

function SWEP:PrimaryAttack()
	local Owner = self:GetOwner()

	if Owner:KeyPressed(IN_ATTACK) then
		self:SetAnim("fire_windup", true, 3)
	end
	self:SetAnim("fire_loop", true, 2)
	self:EmitSound(Zap:format(math.random(1, 3)), nil, 115, ACF.Volume)
	self:SetNextPrimaryFire(Clock.CurTime + 0.05)

	if CLIENT then return end
	if self.LastDistance > self.MaxDistance then return end

	local Entity = self.LastEntity
	local Trace = self.LastTrace

	if not ACF.Check(Entity) then return end

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

function SWEP:SecondaryAttack()
	local Owner = self:GetOwner()

	if Owner:KeyPressed(IN_ATTACK2) then
		self:SetAnim("fire_windup", true, 3)
	end
	self:SetAnim("fire_loop", true, 2)
	self:EmitSound(Zap:format(math.random(1, 2)), nil, nil, ACF.Volume)
	self:SetNextPrimaryFire(Clock.CurTime + 0.05)

	if CLIENT then return end
	if self.LastDistance > self.MaxDistance then return end

	local Entity = self.LastEntity
	local Trace = self.LastTrace

	if not ACF.Check(Entity) then return end

	local DmgResult = self.DamageResult
	local DmgInfo   = self.DamageInfo
	local HitPos    = Trace.HitPos

	DmgResult:SetThickness(Entity.ACF.Armour)

	DmgInfo:SetOrigin(Trace.StartPos)
	DmgInfo:SetHitPos(HitPos)
	DmgInfo:SetHitGroup(Trace.HitGroup)

	local HitRes = Damage.dealDamage(Entity, DmgResult, self.DamageInfo)

	if HitRes.Kill then
		ACF.APKill(Entity, Trace.Normal, 1)
	else
		local Effect = EffectData()
		Effect:SetMagnitude(1)
		Effect:SetRadius(1)
		Effect:SetScale(1)
		Effect:SetStart(HitPos)
		Effect:SetOrigin(HitPos)

		util.Effect("Sparks", Effect, true, true)

		Entity:EmitSound(Zap:format(math.random(1, 4)), nil, nil, ACF.Volume)
	end
end