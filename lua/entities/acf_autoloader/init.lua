AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

local ACF         = ACF
local TraceLine   = util.TraceLine

function ENT.ACF_OnVerifyClientData(ClientData)
	ClientData.AutoloaderSize = Vector(ClientData.AutoloaderLength, ClientData.AutoloaderCaliber, ClientData.AutoloaderCaliber) / (25.4 * 12.312501907349)
end

function ENT:ACF_PreSpawn()
	self:SetScaledModel("models/hunter/blocks/cube025x025x025.mdl")

	-- Linked entities
	self.Gun = nil
	self.AmmoCrates = {}

	-- State variables
	self.AutoloaderGunBaseReloadTime = nil
	self.AutoloaderAmmoBaseReloadTime = {}
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
	if This:ACF_GetUserVar("Gun") or Gun:ACF_GetUserVar("Autoloader") then return false, "Autoloader is already linked to that gun." end

	return true
end)

ACF.RegisterClassLinkCheck("acf_autoloader", "acf_gun", function(This, Gun)
	if Gun:GetPos():DistToSqr(This:GetPos()) > MaxDistance then return false, "This gun is too far from the autoloader." end
	return true
end)

ACF.RegisterClassLink("acf_autoloader", "acf_gun", function(This, Gun)
	This:ACF_SetUserVar("Gun", Gun)
	Gun:ACF_SetUserVar("Autoloader", This)

	return true, "Autoloader linked successfully."
end)

ACF.RegisterClassUnlink("acf_autoloader", "acf_gun", function(This, Gun)
	if not This:ACF_GetUserVar("Gun") or not Gun:ACF_GetUserVar("Autoloader") then return false, "Autoloader was not linked to that gun." end
	This:ACF_SetUserVar("Gun", nil)
	Gun:ACF_SetUserVar("Autoloader", nil)
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
	if BulletData and (BulletData.ProjLength + BulletData.PropLength - 0.01) > This:ACF_GetUserVar("AutoloaderLength") / 10 then return false, "Ammo is too long for this autoloader." end
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

-- TODO: abstract this better after autoloaders are implemented... Not my proudest.
local TraceConfig = {start = Vector(), endpos = Vector(), filter = nil}

function ENT:GetReloadEffAuto(Gun, Ammo)
	if not IsValid(Gun) or not IsValid(Ammo) then return 0.0000001 end

	local BreechPos = Gun:LocalToWorld(Gun.BreechPos)
	local AutoloaderPos = self:GetPos()
	local AmmoPos = Ammo:GetPos()

	local GunArmAngleAligned = self:GetForward():Dot(Gun:GetForward()) > 0.99

	if not GunArmAngleAligned then return 0.000001 end

	-- Check LOS from arm to breech is unobstructed
	TraceConfig.start = AutoloaderPos
	TraceConfig.endpos = BreechPos
	TraceConfig.filter = {self, Gun, Ammo}
	local TraceResult = TraceLine(TraceConfig)
	if TraceResult.Hit then return 0.000001 end

	-- Check LOS from arm to ammo is unobstructed
	TraceConfig.start = AutoloaderPos
	TraceConfig.endpos = AmmoPos
	TraceConfig.filter = {self, Gun, Ammo}
	TraceResult = TraceLine(TraceConfig)
	if TraceResult.Hit then return 0.000001 end

	-- Gun to arm
	local BreechPos = Gun:LocalToWorld(Gun.BreechPos)
	local GunMoveOffset = self:WorldToLocal(BreechPos)

	-- Gun to ammo
	local AmmoMoveOffset = self:WorldToLocal(Ammo:GetPos())
	local AmmoAngleDiff = math.deg(math.acos(self:GetForward():Dot(Ammo:GetForward())))

	local HorizontalScore = ACF.Normalize(math.abs(GunMoveOffset.x) + math.abs(AmmoMoveOffset.x) + math.abs(GunMoveOffset.y) + math.abs(AmmoMoveOffset.y), ACF.AutoloaderWorstDistHorizontal, ACF.AutoloaderBestDistHorizontal)
	local VerticalScore = ACF.Normalize(math.abs(GunMoveOffset.z) + math.abs(AmmoMoveOffset.z), ACF.AutoloaderWorstDistVertical, ACF.AutoloaderBestDistVertical)
	local AngularScore = ACF.Normalize(AmmoAngleDiff, ACF.AutoloaderWorstDistAngular, ACF.AutoloaderBestDistAngular)

	return 2 * HorizontalScore * VerticalScore * AngularScore
end

function ENT:ACF_UpdateOverlayState(State)
	State:AddNumber("Max Shell Caliber", self:ACF_GetUserVar("AutoloaderCaliber"))
	State:AddNumber("Max Shell Length", self:ACF_GetUserVar("AutoloaderLength"))
	State:AddNumber("Mass (kg)", math.Round(self:GetPhysicsObject():GetMass(), 2))
end

ACF.Classes.Entities.Register()