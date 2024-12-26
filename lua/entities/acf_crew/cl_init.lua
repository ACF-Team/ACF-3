DEFINE_BASECLASS("acf_base_simple")

include("shared.lua")

language.Add("Cleanup_acf_crew", "ACF Crewmates")
language.Add("Cleaned_acf_crew", "Cleaned up all ACF Crewmates")
language.Add("SBoxLimit__acf_crew", "You've reached the ACF Crewmate limit!")

-- Deals with crew linking to non crew entities
net.Receive("ACF_Crew_Links",function()
    local EntIndex1 = net.ReadUInt(16)
    local EntIndex2 = net.ReadUInt(16)
    local State = net.ReadBool()

    local Ent = Entity(EntIndex1)
    Ent.TargetLinks = Ent.TargetLinks or {}

    if State then Ent.TargetLinks[EntIndex2] = true else Ent.TargetLinks[EntIndex2] = nil end
end)

function ENT:Initialize(...)
    BaseClass.Initialize(self, ...)
end

function ENT:Draw(...)
    BaseClass.Draw(self, ...)
end

local green = Color(0,255,0,100)
function ENT:DrawOverlay()
    if self.TargetLinks then
        for k, _ in pairs(self.TargetLinks) do
            local k = Entity(k)
            if not IsValid(k) then continue end
            render.DrawWireframeBox(k:GetPos(), k:GetAngles(), k:OBBMins(), k:OBBMaxs(), green, true)
        end
    end
end