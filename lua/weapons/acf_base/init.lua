
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

SWEP.AutoSwitchTo		= false
SWEP.AutoSwitchFrom		= false

function SWEP:Initialize()
	
	self.Primary.BulletData	= {}
	self.ConvertData = ACF.RoundTypes[self.Primary.UserData["Type"]]["convert"]		--Call the correct function for this round type to convert user input data into ballistics data
	self.Primary.BulletData = self:ConvertData( self.Primary.UserData )				--Put the results into the BulletData table
	
	self.NetworkData = ACF.RoundTypes[self.Primary.UserData["Type"]]["network"]
	self:NetworkData( self.Primary.BulletData )

	if ( SERVER ) then 
		self:SetWeaponHoldType("ar2")
		--self.Owner:GiveAmmo( self.Primary.DefaultClip, self.Primary.Ammo )	
	end

end

function SWEP:Reload()
	
	if  ( self.Weapon:Clip1() < self.Primary.ClipSize && self.Owner:GetAmmoCount( self.Primary.Ammo ) > 0 ) then
	
		self.Weapon:EmitSound("weapons/AMR/sniper_reload.wav",350,110)
		self.Weapon:DefaultReload(ACT_VM_RELOAD)
		
	end
	
end

function SWEP:Think()

	if self.OwnerIsNPC then return end	

	if self.Owner:KeyDown(IN_USE) then
		self:CrateReload()
	end
		
	self:NextThink( CurTime()+0.1 )
	
end

function SWEP:MuzzleEffect()	--Server side effect, for external stuff
	
 	self:EmitSound("weapons/AMR/sniper_fire.wav")
	self.Owner:MuzzleFlash()
	self.Owner:SetAnimation( PLAYER_ATTACK1 )
	
end

function SWEP:CrateReload()

	local ViewTr = { }
		ViewTr.start = self.Owner:GetShootPos()
		ViewTr.endpos = self.Owner:GetShootPos() + self.Owner:GetAimVector()*128
		ViewTr.filter = {self.Owner, self.Weapon}
	local ViewRes = util.TraceLine(ViewTr)					--Trace to see if it will hit anything
	
	if SERVER then	
		local AmmoEnt = ViewRes.Entity
		if AmmoEnt and AmmoEnt:IsValid() and AmmoEnt.Ammo > 0 and AmmoEnt.RoundId == self.Primary.UserData["Id"] then
			local CurAmmo = self.Owner:GetAmmoCount( self.Primary.Ammo )
			local Transfert = math.min(AmmoEnt.Ammo, self.Primary.DefaultClip-CurAmmo)
			AmmoEnt.Ammo = AmmoEnt.Ammo - Transfert
			self.Owner:GiveAmmo( Transfert, self.Primary.Ammo )
			
			self.Primary.BulletData = AmmoEnt.BulletData
			
			self.NetworkData = ACF.RoundTypes[AmmoEnt.RoundType]["network"]
			self:NetworkData( self.Primary.BulletData )
			
			return true	
		end
	end
	
end

function SWEP:StartUp()
	
	self:SetDTBool(0,false )
	self.LastIrons = 0
	
	if self.Owner then
		self.OwnerIsNPC = self.Owner:IsNPC() -- This ought to be better than getting it every time we fire
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

function SWEP:ShouldDropOnDie() return true end

function SWEP:Equip() 			self:StartUp() return true end
function SWEP:OnRestore() 		self:StartUp() return true end
function SWEP:Deploy() 			self:StartUp() return true end

function SWEP:Holster() 		self:CleanUp() return true end
function SWEP:OnRemove() 		self:CleanUp() return true end
function SWEP:OnDrop() 			self:CleanUp() return true end
function SWEP:OwnerChanged() 	self:CleanUp() return true end



