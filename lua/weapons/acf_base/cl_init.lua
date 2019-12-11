
include('shared.lua')

SWEP.PrintName			= "ACF SWEP Base"			
SWEP.Slot				= 1
SWEP.SlotPos			= 1
SWEP.DrawAmmo			= false
SWEP.DrawCrosshair		= false

SWEP.ScreenFactor = {}
SWEP.ScreenFactor.w = surface.ScreenWidth()
SWEP.ScreenFactor.h = surface.ScreenHeight()
SWEP.FloatingAim = {}
	SWEP.FloatingAim.bounds = 0.3
	
function SWEP:Initialize()
	
	self:StartUp()

end

function SWEP:Think()	
	
	self:ApplyRecoil(0)
		
	self:NextThink( CurTime()+0.1 )
	
end
	
function SWEP:GetViewModelPosition(Pos, Ang)
	
	local Mul = 1
	local ModPos = Vector(0,0,0)
	if self:GetDTBool(0) then
		ModPos = self.IronSightsPos
	end
	
	local Right 	= Ang:Right()
	local Up 		= Ang:Up()
	local Forward 	= Ang:Forward()
	
	Pos = Pos + ModPos.x * Right * Mul
	Pos = Pos + ModPos.y * Forward * Mul
	Pos = Pos + ModPos.z * Up * Mul

	return Pos, Ang
end

function SWEP:CalcView( Player, Origin, Angles, FOV )

	if self.FloatingAim then
	
		if not (self.FloatingAim.lastaim) then --If this the first time we are called, set the current value for the view and exit. The process will start next frame
			self.FloatingAim.lastaim = Angles:Forward()
			return Origin, Angles, FOV 
		end	
		
		local AimVec = Angles:Forward()
		local DeltaAim = AimVec - self.FloatingAim.lastaim
		local DeltaLength = DeltaAim:Length()
		
		if DeltaLength > self.FloatingAim.bounds then
			AimVec = self.FloatingAim.lastaim + DeltaAim:GetNormalized()* (DeltaLength - self.FloatingAim.bounds)
		else
			AimVec = self.FloatingAim.lastaim
		end
		
		
		Angles = AimVec:Angle()
		self.FloatingAim.lastaim = AimVec
	end
	
	return Origin, Angles, FOV
end

function SWEP:ApplyRecoil( Recoil )

	local RecoilAng = Angle( Recoil*math.Rand(-1,-0.25), Recoil*math.Rand(-0.25,0.25), 0)
	self.Owner:ViewPunch( RecoilAng )
	
end

function SWEP:MuzzleEffect()	--Clientside effect, for Viewmodel stuff
	
	self.Weapon:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
	self.Owner:MuzzleFlash()
	
end

function SWEP:StartUp()
	
	print("Starting Client")
	self.FOV = self.Owner:GetFOV()
	self.ViewModelFOV = self.FOV
	self.LastIrons = 0
		
	--hook.Add("InputMouseApply","ACF_SWEPFloatingCrosshair",ACF_SWEPFloatingCrosshair)
	
end

function SWEP:CleanUp()

	--print("Stopping Client")
	--hook.Remove("InputMouseApply","ACF_SWEPFloatingCrosshair")
	
end

function SWEP:OnRestore() 		self:StartUp() return true end

function SWEP:OnRemove() 		self:CleanUp() return true end
function SWEP:OwnerChanged() 	self:CleanUp() return true end

-- function ACF_SWEPFloatingCrosshair( Command, MouseX, MouseY, Angles )
	
	-- print("Hooked !")
	-- local Weapon = LocalPlayer():GetActiveWeapon()
	-- if Weapon.FloatingAim then
		-- if not ( Weapon.FloatingAim.aim ) then
			-- Weapon.FloatingAim.aim = Angles
		-- end
		
		-- MouseX = -MouseX/30
		-- MouseY = MouseY/30
		
		-- Weapon.FloatingAim.aim = Angle(math.Clamp(Weapon.FloatingAim.aim.p + MouseY,-89.9,89.9), math.NormalizeAngle(Weapon.FloatingAim.aim.y + MouseX), 0)
		
		-- local BoundsAngle = Weapon.FOV * Weapon.FloatingAim.bounds	
		
		-- if Weapon.FloatingAim.aim.p > (Angles.p + BoundsAngle) then
			-- Angles.p = math.NormalizeAngle(Weapon.FloatingAim.aim.p - BoundsAngle)
			-- Command:SetViewAngles( Angles )
		-- elseif Weapon.FloatingAim.aim.p < (Angles.p - BoundsAngle) then
			-- Angles.p = math.NormalizeAngle(Weapon.FloatingAim.aim.p + BoundsAngle)
			-- Command:SetViewAngles( Angles )
		-- end

		-- if Weapon.FloatingAim.aim.y > (Angles.y + BoundsAngle) then
			-- Angles.y = math.NormalizeAngle(Weapon.FloatingAim.aim.y - BoundsAngle)
			-- Command:SetViewAngles( Angles )
		-- elseif Weapon.FloatingAim.aim.y < (Angles.y - BoundsAngle) then
			-- Angles.y = math.NormalizeAngle(Weapon.FloatingAim.aim.y + BoundsAngle)
			-- Command:SetViewAngles( Angles )
		-- end
			
		-- print(Weapon.FloatingAim.aim.p)
		-- print(PitchBounds)
		-- print(Angles.p)
		
	-- else
		--print("Hasty hook remove !")
		--hook.Remove("InputMouseApply","ACF_SWEPFloatingCrosshair")
		-- return		
	-- end
	
	-- return true
	
-- end

-- function SWEP:GetViewModelPosition(Pos, Ang)
	
	-- local Mul = 1
	-- local ModPos = Vector(0,0,0)
	-- if self:GetDTBool(0) then
		-- ModPos = self.IronSightsPos
	-- end
		
	-- local Right 	= Ang:Right()
	-- local Up 		= Ang:Up()
	-- local Forward 	= Ang:Forward()
	
	-- Pos = Pos + ModPos.x * Right * Mul
	-- Pos = Pos + ModPos.y * Forward * Mul
	-- Pos = Pos + ModPos.z * Up * Mul

	-- return Pos, self.FloatingAim.aim
-- end

