-- Pulls data from the C layer for us to use in rendering functions.
ACF.RenderContext = {}
local RenderContext = ACF.RenderContext

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
    if
        IsValid(Lookat) and
        Lookat:GetPos():Distance(RenderContext.ViewSetup.origin) < (Lookat.MaxWorldTipDistance or 256)
    then
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