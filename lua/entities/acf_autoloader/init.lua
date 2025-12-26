AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

ENT.ACF_KillableButIndestructible = true

local ACF         = ACF
local TraceLine   = util.TraceLine

function ENT.ACF_OnVerifyClientData(ClientData)
	ClientData.AutoloaderSize = Vector(ClientData.AutoloaderLength / 43.233333587646 * 10, ClientData.AutoloaderCaliber / 7.2349619865417, ClientData.AutoloaderCaliber / 7.2349619865417) / 25.4
end

function ENT:ACF_PreSpawn()
	self:SetScaledModel("models/acf/autoloader_tractorbeam.mdl")

	-- Linked entities
	self.Gun = nil
	self.AmmoCrates = {}

	-- State variables
	self.AutoloaderGunBaseReloadTime = nil
	self.AutoloaderAmmoBaseReloadTime = {}

	self.OverlayErrors = {}
	self.OverlayWarnings = {}
end

function ENT:ACF_PostUpdateEntityData(ClientData)
	self:SetScale(ClientData.AutoloaderSize)

	-- Mass is proportional to volume of the shell
	local R, H = ClientData.AutoloaderSize.y, ClientData.AutoloaderSize.x
	local Volume = math.pi * R * R * H
	ACF.Contraption.SetMass(self, Volume * 250)
end

function ENT:ACF_PostMenuSpawn()
	self:DropToFloor()
end

local MaxDistance = ACF.LinkDistance * ACF.LinkDistance

-- Arm to gun links
ACF.RegisterClassPreLinkCheck("acf_autoloader", "acf_gun", function(This, Gun)
	if IsValid(This:ACF_GetUserVar("Gun")) or Gun.Autoloader then return false, "Autoloader is already linked to that gun." end
	return true
end)

ACF.RegisterClassLinkCheck("acf_autoloader", "acf_gun", function(This, Gun)
	if Gun:GetPos():DistToSqr(This:GetPos()) > MaxDistance then return false, "This gun is too far from the autoloader." end
	return true
end)

ACF.RegisterClassLink("acf_autoloader", "acf_gun", function(This, Gun)
	This:ACF_SetUserVar("Gun", Gun)
	Gun.Autoloader = This
	return true, "Autoloader linked successfully."
end)

ACF.RegisterClassUnlink("acf_autoloader", "acf_gun", function(This, Gun)
	if not IsValid(This:ACF_GetUserVar("Gun")) or not Gun.Autoloader then return false, "Autoloader was not linked to that gun." end
	This:ACF_SetUserVar("Gun", nil)
	Gun.Autoloader = nil
	return true, "Autoloader unlinked successfully."
end)

-- Arm to ammo links
ACF.RegisterClassPreLinkCheck("acf_autoloader", "acf_ammo", function(This, Ammo)
	Ammo.Autoloaders = Ammo.Autoloaders or {}
	if This:ACF_GetUserVar("AmmoCrates")[Ammo] or Ammo.Autoloaders[This] then return false, "Autoloader is already linked to that ammo." end

	return true
end)

ACF.RegisterClassLinkCheck("acf_autoloader", "acf_ammo", function(This, Ammo)
	if Ammo:GetPos():DistToSqr(This:GetPos()) > MaxDistance then return false, "This crate is too far from the autoloader." end
	if Ammo:GetParent() ~= This:GetParent() then return false, "Autoloader and ammo must share the same parent" end

	local BulletData = Ammo.BulletData
	if BulletData and (BulletData.Caliber - 0.01) > This:ACF_GetUserVar("AutoloaderCaliber") / 10 then return false, "Ammo is too wide for this autoloader." end
	if BulletData and (BulletData.ProjLength + BulletData.PropLength - 0.01) > This:ACF_GetUserVar("AutoloaderLength") then return false, "Ammo is too long for this autoloader." end
	return true
end)

ACF.RegisterClassLink("acf_autoloader", "acf_ammo", function(This, Ammo)
	This:ACF_GetUserVar("AmmoCrates")[Ammo] = true
	Ammo.Autoloaders[This] = true
	return true, "Autoloader linked successfully."
end)

ACF.RegisterClassUnlink("acf_autoloader", "acf_ammo", function(This, Ammo)
	Ammo.Autoloaders = Ammo.Autoloaders or {}
	if not This:ACF_GetUserVar("AmmoCrates")[Ammo] or not Ammo.Autoloaders[This] then return false, "Autoloader was not linked to that ammo." end -- TODO: refactor when link API is refactored
	This:ACF_GetUserVar("AmmoCrates")[Ammo] = nil
	Ammo.Autoloaders[This] = nil
	return true, "Autoloader unlinked successfully."
end)

local TraceConfig = {start = Vector(), endpos = Vector(), filter = nil}

function ENT:GetReloadEffAuto(Gun, Ammo)
	if not IsValid(Gun) or not IsValid(Ammo) then return 0.0000001 end

	local BreechPos = Gun:LocalToWorld(Gun.BreechPos)
	local BreechAng = Gun:LocalToWorldAngles(Gun.BreechAng)
	-- debugoverlay.Cross(BreechPos, 5, 5, Color(255, 0, 0), true)
	-- debugoverlay.Cross(BreechPos + BreechAng:Forward() * 10, 5, 5, Color(255, 0, 0), true)

	local AutoloaderPos = self:GetPos()
	local AmmoPos = Ammo:GetPos()

	-- TODO: maybe check position too later?
	local GunArmAngle = math.deg(math.acos(self:GetForward():Dot(BreechAng:Forward())))
	local GunArmAngleAligned = GunArmAngle < ACF.AutoloaderMaxAngleDiff
	self.OverlayWarnings.GunArmAlignment = not GunArmAngleAligned and "Autoloader is not aligned\nWith the breech of: " .. (tostring(Gun) or "<INVALID ENTITY???>") .. "\nDeviation: " .. math.Round(GunArmAngle, 2) .. ", Acceptable: " .. ACF.AutoloaderMaxAngleDiff or nil
	self:UpdateOverlay()
	if not GunArmAngleAligned then return 0.000001 end

	-- Check LOS from arm to breech is unobstructed
	TraceConfig.start = AutoloaderPos
	TraceConfig.endpos = BreechPos
	TraceConfig.filter = {self, Gun, Ammo}
	local TraceResult = TraceLine(TraceConfig)
	self.OverlayErrors.ArmBreechLOS = TraceResult.Hit and "Autoloader cannot see the breech\nOf: " .. (tostring(Gun) or "<INVALID ENTITY???>") .. "\nBlocked by " .. (tostring(TraceResult.Entity) or "<INVALID ENTITY???>") or nil
	self:UpdateOverlay()
	if TraceResult.Hit then return 0.000001 end

	-- Check LOS from arm to ammo is unobstructed
	TraceConfig.start = AutoloaderPos
	TraceConfig.endpos = AmmoPos
	TraceConfig.filter = {self, Gun, Ammo}
	TraceResult = TraceLine(TraceConfig)
	self.OverlayErrors.ArmAmmoLOS = TraceResult.Hit and "Autoloader cannot see the ammo\nOf: " .. (tostring(Ammo) or "<INVALID ENTITY???>") .. "\nBlocked by " .. (tostring(TraceResult.Entity) or "<INVALID ENTITY???>") or nil
	self:UpdateOverlay()
	if TraceResult.Hit then return 0.000001 end

	-- Gun to arm
	local GunMoveOffset = self:WorldToLocal(BreechPos)

	-- Gun to ammo
	local AmmoMoveOffset = self:WorldToLocal(Ammo:GetPos())
	local AmmoDirection = Ammo:LocalToWorldAngles(Ammo.ExtraData.LocalAng):Forward()
	local AmmoAngleDiff = math.deg(math.acos(self:GetForward():Dot(AmmoDirection)))

	local HorizontalScore = ACF.Normalize(math.abs(GunMoveOffset.x) + math.abs(AmmoMoveOffset.x) + math.abs(GunMoveOffset.y) + math.abs(AmmoMoveOffset.y), ACF.AutoloaderWorstDistHorizontal, ACF.AutoloaderBestDistHorizontal)
	local VerticalScore = ACF.Normalize(math.abs(GunMoveOffset.z) + math.abs(AmmoMoveOffset.z), ACF.AutoloaderWorstDistVertical, ACF.AutoloaderBestDistVertical)
	local AngularScore = ACF.Normalize(AmmoAngleDiff, ACF.AutoloaderWorstDistAngular, ACF.AutoloaderBestDistAngular)

	local HealthScore = self.ACF.Health / self.ACF.MaxHealth
	return 2 * HorizontalScore * VerticalScore * AngularScore * HealthScore
end

function ENT:ACF_Activate(Recalc)
	local PhysObj	= self.ACF.PhysObj
	local Area		= PhysObj:GetSurfaceArea() * ACF.InchToCmSq
	local Armour	= 1
	local Health	= (Area / ACF.Threshold) * 0.5
	local Percent	= 1

	if Recalc and self.ACF.Health and self.ACF.MaxHealth then
		Percent = self.ACF.Health / self.ACF.MaxHealth
	end

	self.ACF.Area		= Area
	self.ACF.Health		= Health * Percent
	self.ACF.MaxHealth	= Health
	self.ACF.Armour		= Armour * Percent
	self.ACF.MaxArmour	= Armour
	self.ACF.Type		= "Prop"
end

function ENT:Think()
	local Gun = self:ACF_GetUserVar("Gun")
	local AmmoCrate = next(self:ACF_GetUserVar("AmmoCrates"))
	if Gun and AmmoCrate and IsValid(Gun) and IsValid(AmmoCrate) then
		self.EstimatedEfficiency = self:GetReloadEffAuto(Gun, AmmoCrate, true)
		self.EstimatedReload = ACF.CalcReloadTime(Gun.Caliber, Gun.ClassData, Gun.WeaponData, AmmoCrate.BulletData, Gun) / self.EstimatedEfficiency
		self.EstimatedReloadMag = ACF.CalcReloadTimeMag(Gun.Caliber, Gun.ClassData, Gun.WeaponData, AmmoCrate.BulletData, Gun) / self.EstimatedEfficiency
		self:UpdateOverlay()
	end

	self:NextThink(CurTime() + 5)

	return true
end

function ENT:ACF_UpdateOverlayState(State)
	if next(self.OverlayErrors) then
		for _, Error in pairs(self.OverlayErrors) do State:AddError(Error) end
	end
	if next(self.OverlayWarnings) then
		for _, Warning in pairs(self.OverlayWarnings) do State:AddWarning(Warning) end
	end
	State:AddNumber("Max Shell Caliber (mm)", self:ACF_GetUserVar("AutoloaderCaliber"))
	State:AddNumber("Max Shell Length (cm)", self:ACF_GetUserVar("AutoloaderLength"))
	State:AddNumber("Mass (kg)", math.Round(self:GetPhysicsObject():GetMass(), 2))
	State:AddNumber("Reload (s)", math.Round(self.EstimatedReload or 0, 4))
	State:AddNumber("Mag Reload (s)", math.Round(self.EstimatedReloadMag or 0, 4))
end

ACF.Classes.Entities.Register()