-- Purpose: Registers a bunch of legality detours for chip interactions with
-- ACF entities and contraptions. Still a lot of work to do here...

local ACF = ACF
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
end

local function BlockEntManipulationIfApplicable(Ent, Type)
    if PreCheck() then return true end
    if Ent.IsACFEntity then
        return DisableFamily(Ent, ("Attempted to call %s (a blocked usercall)."):format(Type or "UNKNOWN"))
    end
    return true
end

local function BlockPhysObjManipulationIfApplicable(PhysObj, Type)
    if PreCheck() then return true end
    if not IsValid(PhysObj) then return false end
    local Ent = PhysObj:GetEntity()
    if not IsValid(Ent) then return false end

    if Ent.IsACFEntity then
        return DisableFamily(Ent, ("Attempted to call %s (a blocked usercall)."):format(Type or "UNKNOWN"))
    end

    return true
end

timer.Simple(Detours.Loaded and 0 or 5, function()
    Detours.Loaded = true

    -- DETOURS: SetPos
    do
        local E2_Ent_SetPos E2_Ent_SetPos = Detours.Expression2("e:setPos(v)", function(Scope, Args, ...)
            BlockEntManipulationIfApplicable(Args[1], "e:setPos(v)")
            return E2_Ent_SetPos(Scope, Args, ...)
        end)

        local SF_Ent_SetPos SF_Ent_SetPos = Detours.Starfall("instance.Types.Entity.Methods.setPos", function(Instance, Ent, ...)
            BlockEntManipulationIfApplicable(Instance.Types.Entity.Unwrap(Ent), "e:setPos(v)")
            return SF_Ent_SetPos(Instance, Ent, ...)
        end)

        local SF_PhysObj_SetPos SF_PhysObj_SetPos = Detours.Starfall("instance.Types.PhysObj.Methods.setPos", function(Instance, PhysObj, ...)
            BlockPhysObjManipulationIfApplicable(Instance.Types.PhysObj.Unwrap(PhysObj), "physobj:setPos(v)")
            return SF_PhysObj_SetPos(Instance, PhysObj, ...)
        end)
    end

    -- DETOURS: SetAng
    do
        local E2_Ent_SetAng E2_Ent_SetAng = Detours.Expression2("e:setAng(a)", function(Scope, Args, ...)
            BlockEntManipulationIfApplicable(Args[1], "e:setAng(a)")
            return E2_Ent_SetAng(Scope, Args, ...)
        end)

        local SF_Ent_SetAng SF_Ent_SetAng = Detours.Starfall("instance.Types.Entity.Methods.setAngles", function(Instance, Ent, ...)
            BlockEntManipulationIfApplicable(Instance.Types.Entity.Unwrap(Ent), "e:setAng(a)")
            return SF_Ent_SetAng(Instance, Ent, ...)
        end)

        local SF_PhysObj_SetAng SF_PhysObj_SetAng = Detours.Starfall("instance.Types.PhysObj.Methods.setAng", function(Instance, PhysObj, ...)
            BlockPhysObjManipulationIfApplicable(Instance.Types.PhysObj.Unwrap(PhysObj), "physobj:setAng(a)")
            return SF_PhysObj_SetAng(Instance, PhysObj, ...)
        end)
    end
end)