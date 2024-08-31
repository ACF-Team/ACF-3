include("shared.lua")

function ENT:Update() end

local HideInfo = ACF.HideInfoBubble

function ENT:DrawGizmos()
    cam.IgnoreZ(true)

    render.DrawBeam(self:GetPos(), self:LocalToWorld(Vector(self.Size.x / 2, 0, 0)), 2, 0, 1, Color(0, 0, 0))
    render.DrawBeam(self:GetPos(), self:LocalToWorld(Vector(self.Size.x / 2, 0, 0)), 1, 0, 1, Color(255, 50, 40))
    render.DrawBeam(self:GetPos(), self:LocalToWorld(Vector(0, -self.Size.y / 2, 0)), 2, 0, 1, Color(0, 0, 0))
    render.DrawBeam(self:GetPos(), self:LocalToWorld(Vector(0, -self.Size.y / 2, 0)), 1, 0, 1, Color(40, 255, 50))

    cam.IgnoreZ(false)
end

function ENT:Draw()
    -- Partial from base_wire_entity, need the tooltip but without the model drawing since we're drawing our own
    local looked_at = self:BeingLookedAtByLocalPlayer()

    if looked_at then
        self:DrawEntityOutline()
    end

    self:DrawModel()

    if looked_at and not HideInfo() then
        self:AddWorldTip()

        if not LocalPlayer():InVehicle() and IsValid(LocalPlayer():GetActiveWeapon()) and LocalPlayer():GetActiveWeapon():GetClass() == "weapon_physgun" then
            self:DrawGizmos()
        end
    end
end

ACF.Classes.Entities.Register()