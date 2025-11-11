AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

local ACF      		= ACF

function ENT.ACF_OnVerifyClientData(ClientData)
	ClientData.WaterjetSize = math.Clamp(ClientData.WaterjetSize or 1, 0.5, 2)
	ClientData.Size = Vector(ClientData.WaterjetSize,ClientData.WaterjetSize,ClientData.WaterjetSize)
end

function ENT:ACF_PostUpdateEntityData(ClientData)
	self:SetScale(ClientData.Size)
end

function ENT:ACF_PreSpawn(_, _, _, _)
	self:SetScaledModel("models/maxofs2d/hover_propeller.mdl")
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