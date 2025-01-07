AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

local ACF      = ACF
local Classes  = ACF.Classes
local Entities = Classes.Entities

ENT.ACF_Limit = 16
ENT.ACF_UserWeighable = true

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

do
    ACF.RegisterLinkSource("acf_baseplate", "prop_vehicle_prisoner_pod")

    ACF.RegisterClassLink("acf_baseplate", "prop_vehicle_prisoner_pod", function(This, Seat, FromChip)
        if This.Seat then return false, "This baseplate is already linked to a seat" end

        This.Seat = Seat

        Seat._IsInvincible = true
        hook.Add("PlayerShouldTakeDamage", "BaseplateSeatInvincibility" .. This:EntIndex(), function(ply, attacker)
            if ply == Seat:GetDriver() then return false end -- Block damage if they're in the seat
        end)

        return true, "Seat linked successfully"
    end)

    ACF.RegisterClassUnlink("acf_baseplate", "prop_vehicle_prisoner_pod", function(This, Seat, FromChip)
        if This.Seat then
            This.Seat = nil

            Seat._IsInvincible = false
            hook.Remove("PlayerShouldTakeDamage", "BaseplateSeatInvincibility" .. This:EntIndex())
            return true, "Seat unlinked successfully"
        end

        return false, "This seat is not linked to this baseplate"
    end)
end

local Text = "Baseplate Size: %.1f x %.1f x %.1f"
function ENT:UpdateOverlayText()
    return Text:format(self.Size[1], self.Size[2], self.Size[3])
end

Entities.Register()