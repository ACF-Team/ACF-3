AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

local ACF      = ACF
local Classes  = ACF.Classes
local Entities = Classes.Entities

ENT.ACF_Limit = 16

function ENT.ACF_OnVerifyClientData(ClientData)
    ClientData.Size = Vector(ClientData.Width, ClientData.Length, ClientData.Thickness)
end
function ENT:ACF_PostUpdateEntityData(ClientData)
    self:SetSize(ClientData.Size)
end

function ENT:ACF_PreSpawn(_, _, _, _)
    self:SetScaledModel("models/holograms/cube.mdl")
    self:SetMaterial("sprops/sprops_grid_12x12")
end

function ENT:ACF_PostSpawn(_, _, _, ClientData)
    local EntMods = ClientData.EntityMods
    if EntMods and EntMods.mass then
        ACF.Contraption.SetMass(self, self.ACF.Mass or 1)
    else
        ACF.Contraption.SetMass(self, 1000)
        print(self:GetPhysicsObject():GetMass())
    end
end

local Text = "Baseplate Size: %dx%dx%d"

function ENT:UpdateOverlayText()
    return Text:format(self.Size[1], self.Size[2], self.Size[3])
end

Entities.Register()