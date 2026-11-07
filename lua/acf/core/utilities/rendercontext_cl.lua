-- Pulls data from the C layer for us to use in rendering functions.
ACF.RenderContext = {}
local RenderContext = ACF.RenderContext

local STICKY_CVAR = CreateClientConVar("acf_overlay_contextmenu_sticky", 1, true, false, "ACF Overlay; keeps the overlay while the context menu cursor is off the entity.", 0, 1)

local function InRange(Entity, Origin)
    return Entity:GetPos():Distance(Origin) < (Entity.MaxWorldTipDistance or 256)
end

-- The context menu's world clicker moves the aim vector with the cursor, so the eye trace follows the mouse
local function KeepLastLookAt(Lookat, LastLookAt, Origin)
    if IsValid(Lookat) and Lookat.ACF_HasOverlay and InRange(Lookat, Origin) then return false end
    if not IsValid(LastLookAt) or not LastLookAt.ACF_HasOverlay or not InRange(LastLookAt, Origin) then return false end
    if not STICKY_CVAR:GetBool() then return false end

    return IsValid(g_ContextMenu) and g_ContextMenu:IsVisible()
end

timer.Create("ACF_RenderContextPopulate_HighFreq", 0.1, 0, function()
    -- This condition happens during first join, which causes the timer to fail
    local LocalPlayer = _G.LocalPlayer()
    if not IsValid(LocalPlayer) then return end

    local EyeTrace = LocalPlayer:GetEyeTrace()
    if not EyeTrace then return end

    RenderContext.ViewSetup = render.GetViewSetup()
    local Weapon = LocalPlayer:GetActiveWeapon()

    -- Cancel out if invalid lookat entity.
    local LastLookAt = RenderContext.LookAt

    local Lookat = EyeTrace.Entity
    local Origin = RenderContext.ViewSetup.origin
    if KeepLastLookAt(Lookat, LastLookAt, Origin) then
        RenderContext.LookAt = LastLookAt
    elseif IsValid(Lookat) and InRange(Lookat, Origin) then
        RenderContext.LookAt = Lookat
    else
        RenderContext.LookAt = nil
    end

    if LastLookAt ~= RenderContext.LookAt then
        hook.Run("ACF_RenderContext_LookAtChanged", LastLookAt, RenderContext.LookAt)
    end

    local class                   = IsValid(Weapon) and Weapon:GetClass() or nil
    RenderContext.PlayerInVehicle = LocalPlayer:InVehicle()
    RenderContext.Class           = class
    RenderContext.PhysOrTool      = class == "weapon_physgun" or class == "gmod_tool"
    RenderContext.InACFMenu       = Weapon.current_mode == "acf_menu"

    local wire_drawoutline = GetConVar("wire_drawoutline")
    if wire_drawoutline then
        RenderContext.ShouldDrawOutline = wire_drawoutline:GetBool()
    end
end)