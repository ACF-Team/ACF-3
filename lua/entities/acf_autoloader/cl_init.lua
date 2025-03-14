include("shared.lua")

local green = Color(0, 255, 0, 100)
local purple = Color(255, 0, 255, 100)

function ENT:DrawOverlay()
    render.DrawWireframeBox(self:GetPos(), self:GetAngles(), self:OBBMins(), self:OBBMaxs(), green, true)
end