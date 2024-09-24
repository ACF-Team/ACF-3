include("shared.lua")

function ENT:Update() end

local HideInfo = ACF.HideInfoBubble

local COLOR_Black = Color(0, 0, 0)
local COLOR_Red   = Color(255, 50, 40)
local COLOR_Green = Color(40, 255, 50)

function ENT:DrawGizmos()
    cam.IgnoreZ(true)

    local Pos = self:GetPos()
    local Size = self.Size

    render.SetColorMaterial()
    render.DrawBeam(Pos, self:LocalToWorld(Vector(Size.x / 2, 0, 0)), 2, 0, 1, COLOR_Black)
    render.DrawBeam(Pos, self:LocalToWorld(Vector(Size.x / 2, 0, 0)), 1, 0, 1, COLOR_Red)
    render.DrawBeam(Pos, self:LocalToWorld(Vector(0, -Size.y / 2, 0)), 2, 0, 1, COLOR_Black)
    render.DrawBeam(Pos, self:LocalToWorld(Vector(0, -Size.y / 2, 0)), 1, 0, 1, COLOR_Green)

    cam.IgnoreZ(false)
end

function ENT:Draw()
    -- Partial from base_wire_entity, need the tooltip but without the model drawing since we're drawing our own
    local LocalPlayer = LocalPlayer()
    local Weapon      = LocalPlayer:GetActiveWeapon()
    local LookedAt    = self:BeingLookedAtByLocalPlayer()

    if LookedAt then
        self:DrawEntityOutline()
    end

    self:DrawModel()

    if LookedAt and not HideInfo() then
        self:AddWorldTip()

        if not LocalPlayer:InVehicle() and IsValid(Weapon) and Weapon:GetClass() == "weapon_physgun" then
            self:DrawGizmos()
        end
    end
end

ACF.Classes.Entities.Register()