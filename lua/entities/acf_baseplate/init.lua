AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

local ACF      = ACF
local Classes  = ACF.Classes
local Entities = Classes.Entities

ENT.ACF_Limit = 16
ENT.ACF_Weighable = true

function ENT.ACF_OnVerifyClientData(ClientData)
    ClientData.Size = Vector(ClientData.Width, ClientData.Length, ClientData.Thickness)
end
function ENT:ACF_PostUpdateEntityData(ClientData)
    self:SetSize(ClientData.Size)
end

function ENT:ACF_PreSpawn(_, _, _, _)
    self:SetScaledModel("models/holograms/cube.mdl")
    self:SetMaterial("hunter/myplastic")
end

function ENT:ACF_OnMassChange(_, NewMass)
end

local Text = "Baseplate Size: %dx%dx%d"

function ENT:UpdateOverlayText()
    return Text:format(self.Size[1], self.Size[2], self.Size[3])
end

Entities.Register()