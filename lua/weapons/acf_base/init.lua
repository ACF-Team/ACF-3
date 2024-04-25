AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

local AmmoTypes = ACF.Classes.AmmoTypes
local Sounds    = ACF.Utilities.Sounds

SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

function SWEP:Initialize()
	local UserData = self.Primary.UserData
	local AmmoType = AmmoTypes.Get(UserData.Type)
	local BulletData

	if SERVER then
		BulletData = AmmoType:ServerConvert(UserData)

		AmmoType:Network(self, BulletData)

		self:SetWeaponHoldType("ar2")
		--self.Owner:GiveAmmo( self.Primary.DefaultClip, self.Primary.Ammo )
	else
		BulletData = AmmoType:ClientConvert(UserData)
	end

	self.Primary.BulletData = BulletData
	self.Primary.RoundData = AmmoType
end

function SWEP:Reload()
	if (self:Clip1() < self.Primary.ClipSize and self:GetOwner():GetAmmoCount(self.Primary.Ammo) > 0) then
		Sounds.SendSound(self, "weapons/AMR/sniper_reload.wav", 70, 110, 1)
		self:DefaultReload(ACT_VM_RELOAD)
	end
end

function SWEP:Think()
	if self.OwnerIsNPC then return end

	if self:GetOwner():KeyDown(IN_USE) then
		self:CrateReload()
	end

	self:NextThink(CurTime() + 0.1)
end

--Server side effect, for external stuff
function SWEP:MuzzleEffect()
	local Owner = self:GetOwner()

	Sounds.SendSound(self, "weapons/AMR/sniper_fire.wav", nil, nil, 1)

	Owner:MuzzleFlash()
	Owner:SetAnimation(PLAYER_ATTACK1)
end

function SWEP:CrateReload()
	local Owner = self:GetOwner()
	local ViewTr = {
		start = Owner:GetShootPos(),
		endpos = Owner:GetShootPos() + Owner:GetAimVector() * 128,
		filter = { Owner, self },
	}

	local ViewRes = util.TraceLine(ViewTr) --Trace to see if it will hit anything

	if SERVER then
		local AmmoEnt = ViewRes.Entity

		if IsValid(AmmoEnt) and AmmoEnt.Ammo > 0 and AmmoEnt.RoundId == self.Primary.UserData["Id"] then
			local CurAmmo = Owner:GetAmmoCount(self.Primary.Ammo)
			local Transfert = math.min(AmmoEnt.Ammo, self.Primary.DefaultClip - CurAmmo)
			local AmmoType = AmmoTypes.Get(AmmoEnt.AmmoType)

			AmmoEnt.Ammo = AmmoEnt.Ammo - Transfert

			Owner:GiveAmmo(Transfert, self.Primary.Ammo)

			self.Primary.BulletData = AmmoEnt.BulletData
			self.Primary.RoundData = AmmoType

			AmmoType:Network(self, self.Primary.BulletData)

			return true
		end
	end
end

function SWEP:StartUp()
	local Owner = self:GetOwner()

	self:SetDTBool(0, false)
	self.LastIrons = 0

	if Owner then
		self.OwnerIsNPC = Owner:IsNPC() -- This ought to be better than getting it every time we fire
	end
end

function SWEP:CleanUp()
end

function SWEP:CreateShell()
	--This gets overwritten by the ammo function
end

function SWEP:NetworkData()
	--This gets overwritten by the ammo function
end

function SWEP:ShouldDropOnDie()
	return true
end

function SWEP:Equip()
	self:StartUp()

	return true
end

function SWEP:OnRestore()
	self:StartUp()

	return true
end

function SWEP:Deploy()
	self:StartUp()

	return true
end

function SWEP:Holster()
	self:CleanUp()

	return true
end

function SWEP:OnRemove()
	self:CleanUp()

	return true
end

function SWEP:OnDrop()
	self:CleanUp()

	return true
end

function SWEP:OwnerChanged()
	self:CleanUp()

	return true
end