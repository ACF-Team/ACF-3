AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

local ACF      = ACF
local Classes  = ACF.Classes
local Entities = Classes.Entities

ENT.ACF_Limit                     = 16
ENT.ACF_UserWeighable             = true
ENT.ACF_KillableButIndestructible = true
ENT.ACF_HealthUpdatesWireOverlay  = true

function ENT.ACF_OnVerifyClientData(ClientData)
    ClientData.Size = Vector(ClientData.Length, ClientData.Width, ClientData.Thickness)
end

function ENT:ACF_PostUpdateEntityData(ClientData)
    self:SetSize(ClientData.Size)
end

function ENT:ACF_PreSpawn(_, _, _, _)
    self:SetScaledModel("models/holograms/cube.mdl")
    self:SetMaterial("hunter/myplastic")
end

function ENT:ACF_PostSpawn(_, _, _, ClientData)
    local EntMods = ClientData.EntityMods
    if EntMods and EntMods.mass then
        ACF.Contraption.SetMass(self, self.ACF.Mass or 1)
    else
        ACF.Contraption.SetMass(self, 1000)
    end
end

function ENT:CFW_OnParentedTo(_, NewEntity)
    if IsValid(NewEntity) then
        ACF.SendNotify(self:CPPIGetOwner(), false, "Cannot parent an ACF baseplate to another entity.")
    end

    return false
end

local Text = "Baseplate Size: %.1f x %.1f x %.1f\nBaseplate Health: %.1f%%"
function ENT:UpdateOverlayText()
    local h, mh = self.ACF.Health, self.ACF.MaxHealth
    return Text:format(self.Size[1], self.Size[2], self.Size[3], (h / mh) * 100)
end

Entities.Register()