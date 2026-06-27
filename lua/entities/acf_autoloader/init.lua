AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

ENT.ACF_KillableButIndestructible = true

local ACF         = ACF
local TraceLine   = util.TraceLine
local Classes     = ACF.Classes

util.AddNetworkString("ACF_Autoloader_Links")

-- Converts shell scale to model scale
local RefSize = Vector(43.233333587646, 7.2349619865417, 7.2349619865417)

function ENT:ACF_PreUpdateEntityData()
	self.AutoloaderSize = Vector(self:ACF_GetUserVar("AutoloaderLength") / RefSize.x * 10, self:ACF_GetUserVar("AutoloaderCaliber") / RefSize.y, self:ACF_GetUserVar("AutoloaderCaliber") / RefSize.z) / ACF.InchToMm
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

function ENT:ACF_PostUpdateEntityData()
	self:SetScale(self.AutoloaderSize)

	-- Mass is proportional to volume of the shell
	local R, H = self.AutoloaderSize.y, self.AutoloaderSize.x
	local Volume = math.pi * R * R * H
	ACF.Contraption.SetMass(self, Volume * 250)

	-- Share the AmmoCrates LUT with ACF_LiveData so Serialize reads from Instance[Field.Name]
	self.AmmoCrates = self.ACF_LiveData.AmmoCrates
end

local MaxDistance = ACF.LinkDistance * ACF.LinkDistance

local function BroadcastEntity(Name, Entity, Entity2, State)
	net.Start(Name)
	net.WriteUInt(Entity:EntIndex(), 16)
	net.WriteUInt(Entity2:EntIndex(), 16)
	net.WriteBool(State)
	net.Broadcast()
end

-- Arm to gun links
ACF.RegisterClassPreLinkCheck("acf_autoloader", "acf_gun", function(This, Gun)
	if IsValid(This.Gun) or Gun.Autoloader then return false, "Autoloader is already linked to that gun." end
	return true
end)

ACF.RegisterClassLinkCheck("acf_autoloader", "acf_gun", function(This, Gun)
	if Gun:GetPos():DistToSqr(This:GetPos()) > MaxDistance then return false, "This gun is too far from the autoloader." end
	return true
end)

ACF.RegisterClassLink("acf_autoloader", "acf_gun", function(This, Gun)
	This.Gun = Gun
	Gun.Autoloader = This
	if This.ACF_LiveData then This.ACF_LiveData.Gun = Gun end
	BroadcastEntity("ACF_Autoloader_Links", This, Gun, true)
	return true, "Autoloader linked successfully."
end)

ACF.RegisterClassUnlink("acf_autoloader", "acf_gun", function(This, Gun)
	if not IsValid(This.Gun) or not Gun.Autoloader then return false, "Autoloader was not linked to that gun." end
	This.Gun = nil
	Gun.Autoloader = nil
	if This.ACF_LiveData then This.ACF_LiveData.Gun = nil end
	BroadcastEntity("ACF_Autoloader_Links", This, Gun, false)
	return true, "Autoloader unlinked successfully."
end)

-- Arm to rack links (missile compatibility)
ACF.RegisterClassPreLinkCheck("acf_autoloader", "acf_rack", function(This, Rack)
	if IsValid(This.Gun) or Rack.Autoloader then return false, "Autoloader is already linked to that rack." end
	return true
end)

ACF.RegisterClassLinkCheck("acf_autoloader", "acf_rack", function(This, Rack)
	if Rack:GetPos():DistToSqr(This:GetPos()) > MaxDistance then return false, "This rack is too far from the autoloader." end
	return true
end)

ACF.RegisterClassLink("acf_autoloader", "acf_rack", function(This, Rack)
	This.Gun = Rack
	Rack.Autoloader = This
	if This.ACF_LiveData then This.ACF_LiveData.Gun = Rack end
	return true, "Autoloader linked successfully."
end)

ACF.RegisterClassUnlink("acf_autoloader", "acf_rack", function(This, Rack)
	if not IsValid(This.Gun) or not Rack.Autoloader then return false, "Autoloader was not linked to that rack." end
	This.Gun = nil
	Rack.Autoloader = nil
	if This.ACF_LiveData then This.ACF_LiveData.Gun = nil end
	return true, "Autoloader unlinked successfully."
end)

-- Arm to ammo links
ACF.RegisterClassPreLinkCheck("acf_autoloader", "acf_ammo", function(This, Ammo)
	Ammo.Autoloaders = Ammo.Autoloaders or {}
	if This.AmmoCrates[Ammo] or Ammo.Autoloaders[This] then return false, "Autoloader is already linked to that ammo." end

	return true
end)

ACF.RegisterClassLinkCheck("acf_autoloader", "acf_ammo", function(This, Ammo)
	if Ammo:GetPos():DistToSqr(This:GetPos()) > MaxDistance then return false, "This crate is too far from the autoloader." end
	if not ACF.AllowArbitraryParents and Ammo:GetParent() ~= This:GetParent() then return false, "Autoloader and ammo must share the same parent." end

	local BulletData = Ammo.BulletData
	local Caliber = BulletData.Caliber
	local Length = BulletData.ProjLength + BulletData.PropLength
	if Ammo.IsMissileAmmo then
		local Weapon    = Classes.GetSubtypeByName("ACF.Missiles.BaseMissile", BulletData.WeaponType)
		local Round 	= Weapon and Weapon.Round
		if Round then Length = Round.ActualLength * ACF.InchToCm end
	end

	if BulletData and (Caliber - 0.01) > This:ACF_GetUserVar("AutoloaderCaliber") / 10 then return false, "Ammo is too wide for this autoloader." end
	if BulletData and (Length - 0.01) > This:ACF_GetUserVar("AutoloaderLength") then return false, "Ammo is too long for this autoloader." end
	return true
end)

ACF.RegisterClassLink("acf_autoloader", "acf_ammo", function(This, Ammo)
	This.AmmoCrates[Ammo] = true
	Ammo.Autoloaders[This] = true
	return true, "Autoloader linked successfully."
end)

ACF.RegisterClassUnlink("acf_autoloader", "acf_ammo", function(This, Ammo)
	Ammo.Autoloaders = Ammo.Autoloaders or {}
	if not This.AmmoCrates[Ammo] or not Ammo.Autoloaders[This] then return false, "Autoloader was not linked to that ammo." end -- TODO: refactor when link API is refactored
	This.AmmoCrates[Ammo] = nil
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
	local DiffNorm = (BreechPos - AutoloaderPos):GetNormalized()
	local GunDiffAngle = math.deg(math.acos(DiffNorm:Dot(BreechAng:Forward())))
	local ALDiffAngle = math.deg(math.acos(DiffNorm:Dot(self:GetForward())))
	local GunArmAngle = GunDiffAngle + ALDiffAngle
	local GunArmAngleAligned = GunArmAngle < ACF.AutoloaderMaxAngleDiff
	self.OverlayWarnings.GunArmAlignment = not GunArmAngleAligned and "Autoloader is not aligned\nWith the breech of: " .. (tostring(Gun) or "<INVALID ENTITY???>") .. "\nDeviation: " .. math.Round(GunArmAngle, 2) .. ", Acceptable: " .. ACF.AutoloaderMaxAngleDiff or nil
	self:UpdateOverlay()
	if not GunArmAngleAligned then return 0.000001 end

	TraceConfig.filter = function(x) return not (x == self or x == Gun or x == Ammo or x == self:GetParent() or x.noradius or x:GetOwner() ~= self:GetOwner() or x:IsPlayer() or x.IsACFMissile or ACF.GlobalFilter[x:GetClass()]) end

	-- Check LOS from arm to breech is unobstructed
	TraceConfig.start = AutoloaderPos
	TraceConfig.endpos = BreechPos
	local TraceResult = TraceLine(TraceConfig)
	self.OverlayErrors.ArmBreechLOS = TraceResult.Hit and "Autoloader cannot see the breech\nOf: " .. (tostring(Gun) or "<INVALID ENTITY???>") .. "\nBlocked by " .. (tostring(TraceResult.Entity) or "<INVALID ENTITY???>") or nil
	self:UpdateOverlay()
	if TraceResult.Hit then return 0.000001 end

	-- Check LOS from arm to ammo is unobstructed
	TraceConfig.start = AutoloaderPos
	TraceConfig.endpos = AmmoPos
	TraceResult = TraceLine(TraceConfig)
	self.OverlayErrors.ArmAmmoLOS = TraceResult.Hit and "Autoloader cannot see the ammo\nOf: " .. (tostring(Ammo) or "<INVALID ENTITY???>") .. "\nBlocked by " .. (tostring(TraceResult.Entity) or "<INVALID ENTITY???>") or nil
	self:UpdateOverlay()
	if TraceResult.Hit then return 0.000001 end

	self.OverlayErrors.MountPoint = Gun.IsACFRack and table.Count(Gun.MountPoints) ~= 1 and "Autoloader is linked to a rack with\nMultiple mount points, which is unsupported." or nil

	-- Gun to arm
	local GunMoveOffset = self:WorldToLocal(BreechPos)

	-- Gun to ammo
	local AmmoMoveOffset = self:WorldToLocal(Ammo:GetPos())
	local AmmoDirection = Ammo:LocalToWorldAngles(Ammo.ExtraData.LocalAng):Forward()
	local AmmoAngleDiff = math.deg(math.acos(self:GetForward():Dot(AmmoDirection)))

	local HorizontalScore = ACF.Normalize(math.abs(GunMoveOffset.x) + math.abs(AmmoMoveOffset.x) + math.abs(GunMoveOffset.y) + math.abs(AmmoMoveOffset.y), ACF.AutoloaderWorstDistHorizontal, ACF.AutoloaderBestDistHorizontal)
	local VerticalScore = ACF.Normalize(math.abs(GunMoveOffset.z) + math.abs(AmmoMoveOffset.z), ACF.AutoloaderWorstDistVertical, ACF.AutoloaderBestDistVertical)
	local AngularScore = ACF.Normalize(AmmoAngleDiff, ACF.AutoloaderWorstDistAngular, ACF.AutoloaderBestDistAngular)

	if AngularScore <= 0 then self.OverlayWarnings.AngularScore = "Autoloader or ammo are probably backwards or greatly misaligned." end

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

function ENT:GetCost()
	local AutoloaderSize = self:GetScale()

	local R, H = AutoloaderSize.y, AutoloaderSize.x
	local Volume = math.pi * R * R * H

	return Volume * 2
end

function ENT:Think()
	local Gun = self.Gun
	local AmmoCrate = next(self.AmmoCrates)
	local LinkedToGun = Gun and IsValid(Gun)
	local LinkedToCrate = AmmoCrate and IsValid(AmmoCrate)

	if LinkedToGun and LinkedToCrate then
		self.EstimatedEfficiency = self:GetReloadEffAuto(Gun, AmmoCrate, true)
		self.EstimatedReload = ACF.CalcReloadTime(Gun.Caliber, Gun.ClassData, Gun.WeaponData, AmmoCrate.BulletData, Gun) / self.EstimatedEfficiency
		self.EstimatedReloadMag = ACF.CalcReloadTimeMag(Gun.Caliber, Gun.ClassData, Gun.WeaponData, AmmoCrate.BulletData, Gun) / self.EstimatedEfficiency
	end

	self.OverlayErrors.LinkedToGun = not LinkedToGun and "Not linked to a weapon!" or nil
	self.OverlayErrors.LinkedToCrate = not LinkedToCrate and "Not linked to an ammo crate!" or nil
	self:UpdateOverlay()

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
	State:AddNumber("Estimated Reload (s)", math.Round(self.EstimatedReload or 0, 4))
	State:AddNumber("Estimated Magazine Reload (s)", math.Round(self.EstimatedReloadMag or 0, 4))
end

function ENT:OnRemove()
	if IsValid(self.Gun) then self:Unlink(self.Gun) end
	for Ammo in pairs(self.AmmoCrates) do self:Unlink(Ammo) end
end