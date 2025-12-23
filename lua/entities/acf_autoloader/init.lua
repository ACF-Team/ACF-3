AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

local ACF         = ACF
local Mobility    = ACF.Mobility

function ENT.ACF_OnVerifyClientData(ClientData)
	ClientData.AutoloaderCaliber = math.Clamp(ClientData.AutoloaderCaliber or 1, ACF.MinAutoloaderCaliber, ACF.MaxAutoloaderCaliber)
	ClientData.AutoloaderLength = math.Clamp(ClientData.AutoloaderLength or 1, ACF.MinAutoloaderLength, ACF.MaxAutoloaderLength)
	ClientData.AutoloaderSize = Vector(ClientData.AutoloaderLength, ClientData.AutoloaderCaliber, ClientData.AutoloaderCaliber) / (25.4 * 12.312501907349)
end

function ENT:ACF_PreSpawn()
	self:SetScaledModel("models/hunter/blocks/cube025x025x025.mdl")

	self.Ammos = {}
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

ACF.RegisterClassLink("acf_autoloader", "acf_ammo", function(This, Ammo)
	Ammo.Autoloaders = Ammo.Autoloaders or {}
	if This.Ammos[Ammo] or Ammo.Autoloaders[This] then return false, "Autoloader is already linked to that ammo." end
	This.Ammos[Ammo] = true
	Ammo.Autoloaders[This] = true
	return true, "Autoloader linked successfully."
end)

ACF.RegisterClassUnlink("acf_autoloader", "acf_ammo", function(This, Ammo)
	Ammo.Autoloaders = Ammo.Autoloaders or {}
	if not This.Ammos[Ammo] or not Ammo.Autoloaders[This] then return false, "Autoloader was not linked to that ammo." end
	This.Ammos[Ammo] = nil
	Ammo.Autoloaders[This] = nil
	return true, "Autoloader unlinked successfully."
end)

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

function ENT:Think()
	local SelfTbl = self:GetTable()



	self:NextThink(CurTime() + 0.1)

	return true
end

function ENT:ACF_UpdateOverlayState(State)
	State:AddNumber("Shell Caliber", self:ACF_GetUserVar("AutoloaderCaliber"))
	State:AddNumber("Shell Length", self:ACF_GetUserVar("AutoloaderLength"))
	State:AddNumber("Mass (kg)", math.Round(self:GetPhysicsObject():GetMass(), 2))
end

ACF.Classes.Entities.Register()