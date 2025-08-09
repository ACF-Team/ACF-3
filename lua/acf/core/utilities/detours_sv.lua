-- Registers a bunch of legality detours.

local Detours = ACF.Detours

local function DisableEntity(Entity, Reason, Message)
    local Disabled = Entity.Disabled
    if not Disabled or Reason ~= Disabled.Reason then -- Only complain if the reason has changed
        ACF.DisableEntity(Entity, Reason, Message, Timeout)
    end
end

local function DisableFamily(Ent, Reason)
    for Entity in pairs(Ent:GetFamilyChildren()) do
        if Entity.IsACFEntity then
            DisableEntity(Entity, "Invalid usercall on " .. tostring(Ent) .. "", Reason, 10)
        end
    end

    return false
end

local function PreCheck()
    if not ACF.LegalChecks then return true end
    if ACF.AllowArbitraryManipulation then return true end
end

local function CanSetAng(Ent)
    if PreCheck() then return true end
    if Ent.IsACFEntity then
        return DisableFamily(Ent, "Attempted to call SetAngles via a blocked usercall.")
    end
    return true
end

timer.Simple(Detours.Loaded and 0 or 5, function()
    Detours.Loaded = true

    local E2_SetAng E2_SetAng = Detours.Expression2("e:setAng(a)", function(Scope, Args, ...)
        if not CanSetAng(Args[1]) then return end
        return E2_SetAng(Scope, Args, ...)
    end)
    local SF_SetAng SF_SetAng = Detours.Starfall("instance.Types.Entity.Methods.setAngles", function(Instance, Ent, ...)
        if not CanSetAng(Instance.Types.Entity.Unwrap(Ent)) then return end
        return SF_SetAng(Instance, Ent, ...)
    end)

    print("ACF detours loaded...") -- I forgot the print function :) note to self to find it
end)