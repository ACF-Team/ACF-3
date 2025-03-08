AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

local ACF     = ACF
local Clock   = ACF.Utilities.Clock
local Sounds  = ACF.Utilities.Sounds
local Effects = ACF.Utilities.Effects
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
SWEP.PrintName = "#acf.torch"
SWEP.Slot = 0
SWEP.SlotPos = 6
SWEP.IconLetter = "G"
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true
SWEP.DrawWeaponInfoBox = false
SWEP.BounceWeaponIcon = false
SWEP.MaxDistance = 64 * 64 -- Squared distance


local function TeslaSpark(pos, magnitude)
	local zap = ents.Create("point_tesla")
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

	self:SetHoldType("pistol") -- "357 hold type doesn't exist, it's the generic pistol one" Kaf

	if CLIENT then return end

	self.LastDistance = 0
	self.LastTrace    = {}
	self.DamageResult = Objects.DamageResult(math.pi * 2 ^ 2, 1)
	self.DamageInfo   = Objects.DamageInfo(self, nil, DMG_PLASMA)
end

function SWEP:SetAnim(anim, forceplay, animpriority)
	if CLIENT then return end

	local ViewModel = self:GetOwner():GetViewModel()

	if not IsValid(ViewModel) then return end -- TODO: Figure out why this could be happening
	if not animpriority then animpriority = 0 end

	local Now    = Clock.CurTime
	local IsIdle = self:GetCurrentAnim() == "idle01" or self:GetAnimationTime() < Now

	if IsIdle or (forceplay and self:GetAnimPriority() <= animpriority) then
		self:SetCurrentAnim(anim)

		ViewModel:SendViewModelMatchingSequence(ViewModel:LookupSequence(anim))

		self:SetAnimationTime(Now + ViewModel:SequenceDuration() / ViewModel:GetPlaybackRate())
		self:SetAnimPriority(animpriority)
	end
end

function SWEP:Deploy()
	self:SetCurrentAnim("none") -- Prevents nil anim value

	if CLIENT then
		Sounds.PlaySound(self, "ambient/energy/zap2.wav", nil, nil, 1)
	end

	return true
end

--[[
-- Temporarily commented out as it's apparently causing errors on some setups.
function SWEP:Holster()
	self:SetAnim("holster", true, 1)
	return true
end
]]

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
	--local Trace = Owner:GetEyeTrace()
	local TraceData = {start = Owner:GetShootPos(), endpos = Owner:GetShootPos() + Owner:GetAimVector() * 64, mask = MASK_SOLID, filter = {Owner}}
	local Trace = util.TraceLine(TraceData)
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
	self:SetNextPrimaryFire(Clock.CurTime + 0.05)

	if CLIENT then
		Sounds.PlaySound(self, Zap:format(math.random(1, 3)), nil, 115, 1)

		return
	end

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
		local EffectTable = {
			Origin = AngPos.Pos + Trace.Normal * 10,
			Normal = Trace.Normal,
			Entity = self,
		}

		Effects.CreateEffect("thruster_ring", EffectTable, true, true)

		-- Sound ratelimiting
		local Time = CurTime()
		self.SoundTimer = self.SoundTimer or Time

		if self.SoundTimer <= Time then
			Sounds.SendSound(self, "items/medshot4.wav", nil, nil, 1)
			self.SoundTimer = Time + 0.1
		end
	else
		local OldHealth = Entity.ACF.Health
		local MaxHealth = Entity.ACF.MaxHealth

		local Now = CurTime()
		if Now - (self.LastUpdate or 0) > 0.5 then
			self.LastUpdate = Now
			if Entity.ACF_HealthUpdatesWireOverlay then
				Entity:UpdateOverlay()
			end
		end

		if OldHealth >= MaxHealth then return end

		local OldArmor = Entity.ACF.Armour
		local MaxArmor = Entity.ACF.MaxArmour

		local Health = math.min(OldHealth + (30 / MaxArmor), MaxHealth)
		local Armor = MaxArmor * (0.5 + Health / MaxHealth * 0.5)

		Entity.ACF.Health = Health
		Entity.ACF.Armour = Armor

		Damage.Network(Entity, _, Health, MaxHealth) -- purely to update the damage material on props

		if Entity.ACF_OnRepaired then
			Entity:ACF_OnRepaired(OldArmor, OldHealth, Armor, Health)
		end

		Sounds.SendSound(self, Spark:format(math.random(3, 5)), nil, nil, 1)
		TeslaSpark(Trace.HitPos, 1)

		-- Sound ratelimiting
		local Time = CurTime()
		self.SoundTimer = self.SoundTimer or Time

		if self.SoundTimer <= Time then
			Sounds.SendSound(self, Spark:format(math.random(3, 5)), nil, nil, 1)
			self.SoundTimer = Time + 0.1
		end
	end
end

function SWEP:SecondaryAttack()
	local Owner = self:GetOwner()

	if Owner:KeyPressed(IN_ATTACK2) then
		self:SetAnim("fire_windup", true, 3)
	end
	self:SetAnim("fire_loop", true, 2)
	self:SetNextPrimaryFire(Clock.CurTime + 0.05)

	if CLIENT then
		Sounds.PlaySound(self, Zap:format(math.random(1, 2)), nil, nil, 1)

		return
	end

	if self.LastDistance > self.MaxDistance then return end

	local Entity = self.LastEntity
	local Trace = self.LastTrace

	if not ACF.Check(Entity) then return end

	if Entity:IsPlayer() or Entity:IsNPC() then
		local damageInfo = DamageInfo()
		damageInfo:SetDamage(1)
		damageInfo:SetAttacker(Owner)
		damageInfo:SetInflictor(self)
		damageInfo:SetDamageType(DMG_DISSOLVE) -- Applies combine ball death effect
		damageInfo:SetDamagePosition(Trace.HitPos)
		Entity:TakeDamageInfo(damageInfo)

		local EffectTable = {
			Origin = Trace.HitPos,
			Normal = Trace.Normal,
			Entity = self,
		}

		Effects.CreateEffect("BloodImpact", EffectTable, true, true)
	else
		local DmgResult = self.DamageResult
		local DmgInfo   = self.DamageInfo
		local HitPos    = Trace.HitPos

		DmgResult:SetThickness(Entity.ACF.Armour)

		DmgInfo:SetAttacker(Owner)
		DmgInfo:SetInflictor(self)
		DmgInfo:SetOrigin(Trace.StartPos)
		DmgInfo:SetHitPos(HitPos)
		DmgInfo:SetHitGroup(Trace.HitGroup)

		local HitRes = Damage.dealDamage(Entity, DmgResult, self.DamageInfo)

		if HitRes.Kill then
			ACF.APKill(Entity, Trace.Normal, 1, DmgInfo)
		else
			local EffectTable = {
				Magnitude = 1,
				Radius = 1,
				Scale = 1,
				Start = HitPos,
				Origin = HitPos,
			}

			Effects.CreateEffect("Sparks", EffectTable, true, true)

			-- Sound ratelimiting
			local Time = CurTime()
			self.SoundTimer = self.SoundTimer or Time

			if self.SoundTimer <= Time then
				Sounds.SendSound(Entity, Zap:format(math.random(1, 4)), nil, nil, 1)
				self.SoundTimer = Time + 0.1
			end
		end
	end
end
