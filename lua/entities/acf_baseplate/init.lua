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

-- Might be a good idea to put this somewhere else later
ACF.ActiveBaseplatesTable = ACF.ActiveBaseplatesTable or {}

function ENT.ACF_OnVerifyClientData(ClientData)
    ClientData.Size = Vector(ClientData.Length, ClientData.Width, ClientData.Thickness)
end

function ENT:ACF_PostUpdateEntityData(ClientData)
    self.BaseplateClass = ACF.Classes.BaseplateTypes.Get(ClientData.BaseplateType)
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

    ACF.ActiveBaseplatesTable[self] = true
    self:CallOnRemove("ACF_RemoveBaseplateTableIndex", function(ent) ACF.ActiveBaseplatesTable[ent] = nil end)
end

function ENT:CFW_OnParentedTo(_, NewEntity)
    if IsValid(NewEntity) then
        ACF.SendNotify(self:CPPIGetOwner(), false, "Cannot parent an ACF baseplate to another entity.")
    end

    return false
end

local Text = "%s Baseplate\n\nBaseplate Size: %.1f x %.1f x %.1f\nBaseplate Health: %.1f%%"
function ENT:UpdateOverlayText()
    local h, mh = self.ACF.Health, self.ACF.MaxHealth
    return Text:format(self.BaseplateClass.Name, self.Size[1], self.Size[2], self.Size[3], (h / mh) * 100)
end

function ENT:Think()
    self:BaseplateRepulsion()
end

local function GetBaseplateProperties(Ent, Self, SelfPos, SelfRadius)
    if Ent == Self then return false end

    if Ent:GetClass() ~= "acf_baseplate" then return false end
    if not Ent.Size then return false end
    if Ent:IsPlayerHolding() then return false end

    local Physics     = Ent:GetPhysicsObject()
    if not IsValid(Physics) then return false end

    local Pos         = Physics:GetPos()
    local Radius      = math.sqrt((Ent.Size[1] / 2) ^ 2 + (Ent.Size[2] / 2) ^ 2)

    if Self and not util.IsSphereIntersectingSphere(SelfPos, SelfRadius, Pos, Radius) then
        return false
    end

    local Vel         = Physics:GetVelocity()
    local Contraption = Ent:GetContraption()
    local Mass        = Contraption == nil and Ent:GetPhysicsObject():GetMass() or Contraption.totalMass

    return true, Physics, Pos, Vel, Contraption, Mass, Radius
end

local function CalculateSphereIntersection(SelfPos, SelfRadius, VictimPos, VictimRadius)
    local Dir = SelfPos - VictimPos
    Dir:Normalize()

    local Intersection = ((VictimPos + (Dir * VictimRadius)) - (SelfPos + (-Dir * SelfRadius))):Length()
    return Intersection, Dir, SelfPos + (Dir * (SelfRadius + (Intersection / 2)))
end

function ENT:BaseplateRepulsion()
    if not self.Size then return end
    if self:IsPlayerHolding() then return end
    local SelfValid, _, SelfPos, SelfVel, SelfContraption, SelfMass, SelfRadius = GetBaseplateProperties(self)
    if not SelfValid then return end

    for Victim in pairs(ACF.ActiveBaseplatesTable) do
        local VictimValid, VictimPhysics, VictimPos, _, VictimContraption, VictimMass, VictimRadius = GetBaseplateProperties(Victim, self, SelfPos, SelfRadius)
        if not VictimValid then continue end

        -- This is already blocked by the CFW detour, so this is just in case
        -- that breaks for whatever reason
        if SelfContraption == VictimContraption then continue end

        local IntersectionDistance, IntersectionDirection, IntersectionCenter = CalculateSphereIntersection(SelfPos, SelfRadius, VictimPos, VictimRadius)
        local MassRatio = math.Clamp(SelfMass / VictimMass, 0, .9)
        local LinImpulse, AngImpulse = VictimPhysics:CalculateForceOffset(((SelfVel / 4) + (-IntersectionDirection * IntersectionDistance * 150)) * MassRatio * 100, IntersectionCenter)

        VictimPhysics:ApplyForceCenter(LinImpulse)
        VictimPhysics:ApplyTorqueCenter(VictimPhysics:LocalToWorldVector(AngImpulse * 2))
        self:PlayBaseplateRepulsionSound(SelfVel)
        Victim:PlayBaseplateRepulsionSound(SelfVel)
    end
end

function ENT:PlayBaseplateRepulsionSound(Vel)
    local Hard = Vel:Length() > 500 and true or false
    local Now  = CurTime()
    local Prev = self.LastPlayRepulsionSound
    if Prev and Now - Prev < 0.75 then return end

    self.LastPlayRepulsionSound = Now
    self:EmitSound(Hard and "MetalVehicle.ImpactHard" or "MetalVehicle.ImpactSoft", 150, math.Rand(0.92, 1.05), 1, CHAN_AUTO, 0, 0)
end

Entities.Register()