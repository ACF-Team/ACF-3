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
        hook.Add("PlayerEnteredVehicle", "ACFBaseplateSeatEnter" .. This:EntIndex(), function(ply, veh, role)
            if veh == Seat then ply:GodEnable() end -- Block damage if they're in the seat
        end)
        hook.Add("PlayerLeaveVehicle", "ACFBaseplateSeatExit" .. This:EntIndex(), function(ply, veh)
            if veh == Seat then ply:GodDisable() end -- Block damage if they're in the seat
        end)

        return true, "Seat linked successfully"
    end)

    ACF.RegisterClassUnlink("acf_baseplate", "prop_vehicle_prisoner_pod", function(This, Seat, FromChip)
        if This.Seat then
            This.Seat = nil

            Seat._IsInvincible = false
            hook.Remove("PlayerEnteredVehicle", "ACFBaseplateSeatEnter" .. This:EntIndex())
            hook.Remove("PlayerLeaveVehicle", "ACFBaseplateSeatExit" .. This:EntIndex())
            This:CPPIGetOwner():GodDisable()

            return true, "Seat unlinked successfully"
        end

        return false, "This seat is not linked to this baseplate"
    end)

    local Clock       = ACF.Utilities.Clock
    function ENT:Think()
        if IsValid(self) and IsValid(self.Seat) and self:GetContraption() ~= self.Seat:GetContraption() then self:Unlink(self.Seat) end

        self:NextThink(Clock.CurTime + 0.5 + math.random())
        return true
    end
end

local Text = "Baseplate Size: %.1f x %.1f x %.1f"
function ENT:UpdateOverlayText()
    return Text:format(self.Size[1], self.Size[2], self.Size[3])
end

Entities.Register()