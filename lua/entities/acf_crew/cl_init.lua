include("shared.lua")

-- Deals with crew linking to non crew entities
net.Receive("ACF_Crew_Links", function()
    local EntIndex1 = net.ReadUInt(16)
    local EntIndex2 = net.ReadUInt(16)
    local State = net.ReadBool()

    local Ent = Entity(EntIndex1)
    Ent.Targets = Ent.Targets or {}

    if Ent.Targets == nil then return end
    if State then Ent.Targets[EntIndex2] = true else Ent.Targets[EntIndex2] = nil end
end)

net.Receive("ACF_Crew_Space", function()
    local Ent = net.ReadEntity()
    local Box = net.ReadVector()
    local Offset = net.ReadVector()

    if not IsValid(Ent) then return end

    Ent.Box = Box + Ent:OBBMaxs() - Ent:OBBMins()
    Ent.Offset = Offset
end)

local green = Color(0, 255, 0, 100)
local purple = Color(255, 0, 255, 100)

function ENT:DrawOverlay()
    if self.Targets then
        for Target in pairs(self.Targets) do
            local Target = Entity(Target)
            if not IsValid(Target) then continue end
            render.DrawWireframeBox(Target:GetPos(), Target:GetAngles(), Target:OBBMins(), Target:OBBMaxs(), green, true)
        end
    end

    if IsValid(self) and self.Box then
        render.DrawWireframeBox(self:LocalToWorld(self.Offset), self:GetAngles(), -self.Box / 2, self.Box / 2, purple, true)
        render.DrawWireframeSphere(self:LocalToWorld(self.Offset), 2, 10, 10, purple, true)
    end
end