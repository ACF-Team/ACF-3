local LoadingRadius, ReceivingRadius = include("shared.lua")

function ENT:Update() end

local HideInfo = ACF.HideInfoBubble

local ColorYellow = Color(255, 180, 90, 50)
local ColorYellowBright = Color(255, 220, 150)

local ColorRed = Color(255, 90, 90, 50)
local ColorRedBright = Color(255, 150, 150)

function ENT:DrawGizmos()
    local Long, Lat = 20, 10
    render.SetColorMaterial()
    render.DrawSphere(self:GetPos(), LoadingRadius, Long, Lat, ColorYellow)
    render.DrawSphere(self:GetPos(), -LoadingRadius, Long, Lat, ColorYellow)
    render.DrawWireframeSphere(self:GetPos(), LoadingRadius, Long, Lat, ColorYellowBright, true)

    render.DrawSphere(self:GetPos(), ReceivingRadius, Long, Lat, ColorRed)
    render.DrawSphere(self:GetPos(), -ReceivingRadius, Long, Lat, ColorRed)
    render.DrawWireframeSphere(self:GetPos(), ReceivingRadius, Long, Lat, ColorRedBright, true)
end

local OneScale = Matrix()
OneScale:Identity()
OneScale:Scale(Vector(1, 1, 1))

function ENT:Draw()
    -- The info bubble is drawn by ACF's overlay system, so only the outline and gizmos are handled here
    local RenderContext = ACF.RenderContext
    local LocalPlayer   = LocalPlayer()
    local Weapon        = LocalPlayer:GetActiveWeapon()
    local LookedAt      = RenderContext.LookAt == self and not HideInfo()

    if LookedAt and RenderContext.ShouldDrawOutline then
        self:DrawEntityOutline()
    end

    self:EnableMatrix("RenderMultiply", OneScale)
    self:DrawModel()

    if not LookedAt then return end
    if LocalPlayer:InVehicle() then return end
    if not IsValid(Weapon) then return end

    local class = Weapon:GetClass()
    if class ~= "weapon_physgun" and (class ~= "gmod_tool" or Weapon.current_mode ~= "acf_menu") then return end

    self:DrawGizmos()
end

function ENT:OnRemove()
    if IsValid(self.CachedMesh) then
        self.CachedMesh:Destroy()
    end
end