-- This stuff is meant to allow people to "opt out" of visuals and only see what is hittable on a contraption
-- Helps with various forms of facade you could accomplish otherwise.
-- Still experimental
local DrawCvar = GetConVar("acf_drawtruevisuals")

local VisibleClasses = {
    ["prop_physics"] = true,
    ["primitive_shape"] = true,
}

local IgnoreClasses = {
    ["physgun_beam"] = true,
    ["viewmodel"] = true,
    ["class C_Sun"] = true,
    ["class C_ShadowControl"] = true,
    ["class C_SFogController"] = true,
    ["env_Skypaint"] = true,
    ["class C_EnvTonemapController"] = true,
    ["class C_GMODGameRulesProxy"] = true,
    ["class C_PlayerResource"] = true,
    ["worldspawn"] = true,
}

local Visible = Color(255, 255, 255, 255)
local function EntityPiecewiseFn()
    for _, Entity in ents.Iterator() do
        if not Entity:IsWeapon() and not Entity:IsPlayer() then
            local Class = Entity:GetClass()
            if not IgnoreClasses[Class] then
                if not Entity.IsACFEntity and not VisibleClasses[Class] then
                    Entity:SetNoDraw(true)
                else
                    Entity:SetNoDraw(false)
                    Entity:SetColor(Visible)
                    Entity:SetMaterial("")
                    Entity:SetRenderMode(RENDERMODE_NORMAL)
                end
            end
        end
    end
end

-- this reduces C calls that would otherwise be in the hooks
local ShouldDraw = false
timer.Create("ACF_CheckDrawCvar", 0.1, 0, function()
    local LastShouldDraw = ShouldDraw
    ShouldDraw = DrawCvar:GetBool()

    if ShouldDraw ~= LastShouldDraw then
        if ShouldDraw then
            hook.Add("Think", "ACF_DrawTrueVisuals", EntityPiecewiseFn)
            hook.Add("Tick", "ACF_DrawTrueVisuals", EntityPiecewiseFn)
        else
            hook.Remove("Think", "ACF_DrawTrueVisuals")
            hook.Remove("Tick", "ACF_DrawTrueVisuals")
            -- Trigger a full update 
            RunConsoleCommand("record", "fix")
            RunConsoleCommand("stop")
        end
    end
end)