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
SWEP.PrintName = "ACF Cutting torch"
SWEP.Slot = 0
SWEP.SlotPos = 6
SWEP.IconLetter = "G"
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

function SWEP:Initialize()
	if (SERVER) then
		self:SetWeaponHoldType("pistol") --"357 hold type doesnt exist, it's the generic pistol one" Kaf
	end

	util.PrecacheSound("ambient/energy/NewSpark03.wav")
	util.PrecacheSound("ambient/energy/NewSpark04.wav")
	util.PrecacheSound("ambient/energy/NewSpark05.wav")
	util.PrecacheSound("weapons/physcannon/superphys_small_zap1.wav")
	util.PrecacheSound("weapons/physcannon/superphys_small_zap2.wav")
	util.PrecacheSound("weapons/physcannon/superphys_small_zap3.wav")
	util.PrecacheSound("weapons/physcannon/superphys_small_zap4.wav")
	util.PrecacheSound("items/medshot4.wav")
	self.LastSend = 0
end

function SWEP:Think()
	if SERVER then
		local userid = self.Owner
		local trace = {}
		trace.start = userid:GetShootPos()
		trace.endpos = userid:GetShootPos() + (userid:GetAimVector() * 64)
		trace.filter = userid --Not hitting the owner's feet when aiming down
		local tr = util.TraceLine(trace)
		local ent = tr.Entity

		if ent:IsValid() and self.LastSend < CurTime() and not ent:IsPlayer() and not ent:IsNPC() then
			self.LastSend = CurTime() + 1
			local Valid = ACF_Check(ent)

			if Valid then
				self:SetNWFloat("HP", ent.ACF.Health)
				self:SetNWFloat("Armour", ent.ACF.Armour)
				self:SetNWFloat("MaxHP", ent.ACF.MaxHealth)
				self:SetNWFloat("MaxArmour", ent.ACF.MaxArmour)
			end
		end

		self:NextThink(CurTime() + 0.2)
	end
end

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire(CurTime() + 0.05)
	local userid = self.Owner
	local trace = {}
	trace.start = userid:GetShootPos()
	trace.endpos = userid:GetShootPos() + (userid:GetAimVector() * 64)
	trace.filter = userid --Not hitting the owner's feet when aiming down
	local tr = util.TraceLine(trace)
	if (tr.HitWorld) then return end
	if CLIENT then return end
	local ent = tr.Entity

	if ent:IsValid() then
		if ent:IsPlayer() or ent:IsNPC() then
			local PlayerHealth = ent:Health() --get the health
			local PlayerMaxHealth = ent:GetMaxHealth() --and max health too
			local PlayerArmour = ent:Armor()
			local PlayerMaxArmour = 100
			if (PlayerHealth >= PlayerMaxHealth) then return end --if the player is healthy or somehow dead, move right along.
			PlayerHealth = PlayerHealth + 1 --otherwise add 1 HP
			ent:SetHealth(PlayerHealth) --and boost the player's HP to that.
			self:SetNWFloat("HP", PlayerHealth) --Output to the HUD bar
			self:SetNWFloat("Armour", PlayerArmour)
			self:SetNWFloat("MaxHP", PlayerMaxHealth)
			self:SetNWFloat("MaxArmour", PlayerMaxArmour)
			local effect = EffectData() --then make some pretty effects :D ("Fixed that up a bit so it looks like it's actually emanating from the healing player, well mostly" Kaf)
			local AngPos = userid:GetAttachment(4)
			effect:SetOrigin(AngPos.Pos + userid:GetAimVector() * 10)
			effect:SetNormal(userid:GetAimVector())
			effect:SetEntity(self)
			util.Effect("thruster_ring", effect, true, true) --("The 2 booleans control clientside override, by default it doesn't display it since it'll lag a bit behind inputs in MP, same for sounds" Kaf)
			ent:EmitSound("items/medshot4.wav", true, true) --and play a sound.
		else
			if CPPI and not ent:CPPICanTool(self.Owner, "torch") then return false end
			local Valid = ACF_Check(ent)

			if (Valid and ent.ACF.Health < ent.ACF.MaxHealth) then
				ent.ACF.Health = math.min(ent.ACF.Health + (30 / ent.ACF.MaxArmour), ent.ACF.MaxHealth)
				ent.ACF.Armour = ent.ACF.MaxArmour * (0.5 + ent.ACF.Health / ent.ACF.MaxHealth / 2)
				ent:EmitSound("ambient/energy/NewSpark0" .. tostring(math.random(3, 5)) .. ".wav", true, true) --Welding noise here, gotte figure out how to do a looped sound.
				TeslaSpark(tr.HitPos, 1)
			end

			self:SetNWFloat("HP", ent.ACF.Health)
			self:SetNWFloat("Armour", ent.ACF.Armour)
			self:SetNWFloat("MaxHP", ent.ACF.MaxHealth)
			self:SetNWFloat("MaxArmour", ent.ACF.MaxArmour)
		end
	else
		self:SetNWFloat("HP", 0)
		self:SetNWFloat("Armour", 0)
		self:SetNWFloat("MaxHP", 0)
		self:SetNWFloat("MaxArmour", 0)
	end
end

local Energy = { Kinetic = true, Momentum = 0, Penetration = true }

function SWEP:SecondaryAttack()
	self:SetNextPrimaryFire(CurTime() + 0.05)

	if CLIENT then return end

	local Trace = self.Owner:GetEyeTrace()

	if Trace.HitWorld then return end

	local ent = Trace.Entity

	if ACF_Check(ent) then
		local HitRes = {}

		if ent:IsPlayer() then
			Energy.Penetration = 0.05
			Energy.Kinetic = 0.05

			--We can use the damage function instead of direct access here since no numbers are negative.
			HitRes = ACF_Damage(ent, Energy, 2, 0, self.Owner, 0, self, "Torch")
		else
			if CPPI and not ent:CPPICanTool(self.Owner, "torch") then return false end

			Energy.Penetration = 5
			Energy.Kinetic = 5

			--We can use the damage function instead of direct access here since no numbers are negative.
			HitRes = ACF_Damage(ent, Energy, 2, 0, self.Owner, 0, self, "Torch")
		end

		self:SetNWFloat("HP", ent.ACF.Health)
		self:SetNWFloat("Armour", ent.ACF.Armour)
		self:SetNWFloat("MaxHP", ent.ACF.MaxHealth)
		self:SetNWFloat("MaxArmour", ent.ACF.MaxArmour)

		if HitRes.Kill then
			ACF_APKill(ent, Trace.Normal, 1)
		else
			local effectdata = EffectData()
			effectdata:SetMagnitude(1)
			effectdata:SetRadius(1)
			effectdata:SetScale(1)
			effectdata:SetStart(Trace.HitPos)
			effectdata:SetOrigin(Trace.HitPos)
			util.Effect("Sparks", effectdata, true, true)
			ent:EmitSound("weapons/physcannon/superphys_small_zap" .. math.random(1, 4) .. ".wav") --old annoyinly loud sounds
		end
	else
		self:SetNWFloat("HP", 0)
		self:SetNWFloat("Armour", 0)
		self:SetNWFloat("MaxHP", 0)
		self:SetNWFloat("MaxArmour", 0)
	end
end

function SWEP:Reload()
end

function TeslaSpark(pos, magnitude)
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