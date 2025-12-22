AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

local ACF         = ACF
local Mobility    = ACF.Mobility
local MobilityObj = Mobility.Objects
local Sounds      = ACF.Utilities.Sounds

function ENT.ACF_OnVerifyClientData(ClientData)
	ClientData.AutoloaderCaliber = math.Clamp(ClientData.AutoloaderCaliber or 1, ACF.MinAutoloaderCaliber, ACF.MaxAutoloaderCaliber)
	ClientData.AutoloaderLength = math.Clamp(ClientData.AutoloaderLength or 1, ACF.MinAutoloaderLength, ACF.MaxAutoloaderLength)
	ClientData.Size = Vector(ClientData.AutoloaderLength, ClientData.AutoloaderCaliber, ClientData.AutoloaderCaliber) / (25.4 * 12.312501907349)
end

function ENT:ACF_PreSpawn()
	self:SetScaledModel("models/hunter/blocks/cube025x025x025.mdl")
end

function ENT:ACF_PostUpdateEntityData(ClientData)
	self:SetScale(ClientData.Size)
end

function ENT:ACF_PostMenuSpawn()
	self:DropToFloor()
end

ACF.RegisterClassLink("acf_autoloader", "acf_ammo", function(This, Ammo)
	return true, "Autoloader linked successfully."
end)

ACF.RegisterClassUnlink("acf_autoloader", "acf_ammo", function(This, Ammo)
	return true, "Autoloader unlinked successfully."
end)

ACF.RegisterClassLink("acf_autoloader", "acf_gun", function(This, Gun)
	return true, "Autoloader linked successfully."
end)

ACF.RegisterClassUnlink("acf_autoloader", "acf_gun", function(This, Gun)
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
end

ACF.Classes.Entities.Register()