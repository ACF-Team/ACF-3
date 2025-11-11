AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

local ACF      		= ACF

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