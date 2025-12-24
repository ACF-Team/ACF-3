AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

local ACF         = ACF
local HookRun     = hook.Run
local TraceLine   = util.TraceLine

function ENT.ACF_OnVerifyClientData(ClientData)
	ClientData.AutoloaderCaliber = math.Clamp(ClientData.AutoloaderCaliber or 1, ACF.MinAutoloaderCaliber, ACF.MaxAutoloaderCaliber)
	ClientData.AutoloaderLength = math.Clamp(ClientData.AutoloaderLength or 1, ACF.MinAutoloaderLength, ACF.MaxAutoloaderLength)
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

ACF.RegisterClassLink("acf_autoloader", "acf_gun", function(This, Gun)
	if This.Gun or Gun.Autoloader then return false, "Autoloader is already linked to that gun." end
	This.Gun = Gun
	Gun.Autoloader = This

	return true, "Autoloader linked successfully."
end)

ACF.RegisterClassUnlink("acf_autoloader", "acf_gun", function(This, Gun)
	if not This.Gun or not Gun.Autoloader then return false, "Autoloader was not linked to that gun." end
	This.Gun = nil
	Gun.Autoloader = nil
	return true, "Autoloader unlinked successfully."
end)

ACF.RegisterClassLink("acf_autoloader", "acf_ammo", function(This, Ammo)
	Ammo.Autoloaders = Ammo.Autoloaders or {}
	if This.AmmoCrates[Ammo] or Ammo.Autoloaders[This] then return false, "Autoloader is already linked to that ammo." end
	This.AmmoCrates[Ammo] = true
	Ammo.Autoloaders[This] = true
	return true, "Autoloader linked successfully."
end)

ACF.RegisterClassUnlink("acf_autoloader", "acf_ammo", function(This, Ammo)
	Ammo.Autoloaders = Ammo.Autoloaders or {}
	if not This.AmmoCrates[Ammo] or not Ammo.Autoloaders[This] then return false, "Autoloader was not linked to that ammo." end
	This.AmmoCrates[Ammo] = nil
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

	-- Require alignment of weapon
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

function ENT:Think()
	local SelfTbl = self:GetTable()

	self:NextThink(CurTime() + 0.1)

	return true
end

function ENT:ACF_UpdateOverlayState(State)
	State:AddNumber("Max Shell Caliber", self:ACF_GetUserVar("AutoloaderCaliber"))
	State:AddNumber("Max Shell Length", self:ACF_GetUserVar("AutoloaderLength"))
	State:AddNumber("Mass (kg)", math.Round(self:GetPhysicsObject():GetMass(), 2))
end

-- Adv Dupe 2 Related
do
	-- Hopefully we can improve this when the codebase is refactored.
	function ENT:PreEntityCopy()
		if IsValid(self.Gun) then
			duplicator.StoreEntityModifier(self, "ACFGun", {self.Gun:EntIndex()})
		end

		if next(self.AmmoCrates) then
			local Entities = {}
			for Ent in pairs(self.AmmoCrates) do Entities[#Entities + 1] = Ent:EntIndex() end
			duplicator.StoreEntityModifier(self, "ACFAmmoCrates", Entities)
		end

		-- Wire dupe info
		self.BaseClass.PreEntityCopy(self)
	end

	function ENT:PostEntityPaste(Player, Ent, CreatedEntities)
		local EntMods = Ent.EntityMods

		if EntMods and EntMods.ACFGun then
			local Gun = CreatedEntities[EntMods.ACFGun[1]]
			if IsValid(Gun) then self:Link(Gun) end
		end

		if EntMods and EntMods.ACFAmmoCrates then
			for _, EntIndex in ipairs(EntMods.ACFAmmoCrates) do
				local Ammo = CreatedEntities[EntIndex]
				if IsValid(Ammo) then self:Link(Ammo) end
			end
		end

		--Wire dupe info
		self.BaseClass.PostEntityPaste(self, Player, Ent, CreatedEntities)
	end

	function ENT:OnRemove()
		HookRun("ACF_OnEntityLast", "acf_controller", self)

		if IsValid(self.Gun) then self:Unlink(self.Gun) end
		for v, _ in pairs(self.AmmoCrates) do self:Unlink(v) end

		WireLib.Remove(self)
	end
end

ACF.Classes.Entities.Register()