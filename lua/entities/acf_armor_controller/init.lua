
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

local ACF      		= ACF

function ENT.ACF_OnVerifyClientData(ClientData)
	-- We don't have any client data yet
end

function ENT:ACF_PreSpawn(_, _, _, _)
	self:SetModel("models/hunter/plates/plate025x025.mdl")
end

function ENT:ACF_PostUpdateEntityData(ClientData)
	-- We don't have any entity data yet
end

function ENT:ACF_PostMenuSpawn()
	self:DropToFloor()
	self:SetAngles(self:GetAngles() + Angle(0, 0, 0))
end

local Text = "%s"
function ENT:UpdateOverlayText()
	return Text:format("LOL")
end

ACF.Classes.Entities.Register()