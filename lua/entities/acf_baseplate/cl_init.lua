include("shared.lua")

function ENT:Update() end

local HideInfo = ACF.HideInfoBubble

local ColorBlack = Color(0, 0, 0)
local ColorRed   = Color(255, 96, 87)
local ColorGreen = Color(119, 255, 92)
local ColorBlue  = Color(108, 184, 255)
local VectorZ    = Vector(0, 0, 16)

function ENT:DrawGizmos()
    cam.IgnoreZ(true)

    local Pos = self:GetPos()
    local Size = self.Size

    render.SetColorMaterial()

    render.DrawBeam(Pos, self:LocalToWorld(Vector(Size.x / 2, 0, 0)), 1.25, 0, 1, ColorBlack)
    render.DrawBeam(Pos, self:LocalToWorld(Vector(Size.x / 2, 0, 0)), .5, 0, 1, ColorRed)

    render.DrawBeam(Pos, self:LocalToWorld(Vector(0, -Size.y / 2, 0)), 1.25, 0, 1, ColorBlack)
    render.DrawBeam(Pos, self:LocalToWorld(Vector(0, -Size.y / 2, 0)), .5, 0, 1, ColorGreen)

    render.DrawBeam(Pos, self:LocalToWorld(VectorZ), 1.25, 0, 1, ColorBlack)
    render.DrawBeam(Pos, self:LocalToWorld(VectorZ), .5, 0, 1, ColorBlue)

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

    if not LookedAt then return end
    if HideInfo() then return end

    self:AddWorldTip()

    if LocalPlayer:InVehicle() then return end
    if not IsValid(Weapon) then return end

    local class = Weapon:GetClass()
    if class ~= "weapon_physgun" and (class ~= "gmod_tool" or Weapon.current_mode ~= "acf_menu") then return end

    self:DrawGizmos()
end

ACF.Classes.Entities.Register()