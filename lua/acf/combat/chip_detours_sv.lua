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


-- Crew are explicitly blocked from being disabled, since that will instantly kill all crew members
-- Other entities are fair game though
local function DisableFamily(Ent, Reason)
    for Entity in pairs(Ent:GetFamilyChildren()) do
        if IsValid(Entity) and Entity.IsACFEntity and not Entity.IsACFCrew then
            DisableEntity(Entity, "Invalid usercall on " .. tostring(Ent) .. "", Reason, 10)
        end
    end

    return false
end

local function DisableContraption(Ent, Reason)
    for Entity in pairs(Ent:GetContraption().ents) do
        if IsValid(Entity) and Entity.IsACFEntity and not Entity.IsACFCrew then
            DisableEntity(Entity, "Invalid usercall on " .. tostring(Ent) .. "", Reason, 10)
        end
    end

    return false
end

local function PreCheck()
    if not ACF.LegalChecks then return true end
end

-- These are the methods to disable contraptions/families
local function BlockEntManipulationIfApplicable(Ent, Type, DisableFunc)
    DisableFunc = DisableFunc or DisableFamily
    if PreCheck() then return true end
    if not IsValid(Ent) then return false end -- thanks setang steering

    if Ent.IsACFEntity then
        return DisableFunc(Ent, ("Attempted to call %s (a blocked usercall)."):format(Type or "UNKNOWN"))
    end
    return true
end

local function BlockPhysObjManipulationIfApplicable(PhysObj, Type, DisableFunc)
    DisableFunc = DisableFunc or DisableFamily
    if PreCheck() then return true end
    if not IsValid(PhysObj) then return false end
    local Ent = PhysObj:GetEntity()
    if not IsValid(Ent) then return false end

    if Ent.IsACFEntity then
        return DisableFunc(Ent, ("Attempted to call %s (a blocked usercall)."):format(Type or "UNKNOWN"))
    end

    return true
end

timer.Simple(Detours.Loaded and 0 or 5, function()
    Detours.Loaded = true

    -- DETOURS: SetPos
    do
        local Func Func = Detours.Expression2("e:setPos(v)", function(Scope, Args, ...)
            BlockEntManipulationIfApplicable(Args[1], "e:setPos(v)")
            return Func(Scope, Args, ...)
        end)
    end
    do
        local Func Func = Detours.Starfall("instance.Types.Entity.Methods.setPos", function(Instance, Ent, ...)
            BlockEntManipulationIfApplicable(Instance.Types.Entity.Unwrap(Ent), "e:setPos(v)")
            return Func(Instance, Ent, ...)
        end)
    end
    do
        local Func Func = Detours.Starfall("instance.Types.PhysObj.Methods.setPos", function(Instance, PhysObj, ...)
            BlockPhysObjManipulationIfApplicable(Instance.Types.PhysObj.Unwrap(PhysObj), "physobj:setPos(v)")
            return Func(Instance, PhysObj, ...)
        end)
    end

    -- DETOURS: SetAng
    do
        local Func Func = Detours.Expression2("e:setAng(a)", function(Scope, Args, ...)
            BlockEntManipulationIfApplicable(Args[1], "e:setAng(a)")
            return Func(Scope, Args, ...)
        end)
    end
    do
        local Func Func = Detours.Starfall("instance.Types.Entity.Methods.setAngles", function(Instance, Ent, ...)
            BlockEntManipulationIfApplicable(Instance.Types.Entity.Unwrap(Ent), "e:setAng(a)")
            return Func(Instance, Ent, ...)
        end)
    end
    do
        local Func Func = Detours.Starfall("instance.Types.PhysObj.Methods.setAng", function(Instance, PhysObj, ...)
            BlockPhysObjManipulationIfApplicable(Instance.Types.PhysObj.Unwrap(PhysObj), "physobj:setAng(a)")
            return Func(Instance, PhysObj, ...)
        end)
    end

    -- DETOURS: AddAngleVelocity
    do
        local Func Func = Detours.Starfall("instance.Types.Entity.Methods.addAngleVelocity", function(Instance, Ent, ...)
            BlockEntManipulationIfApplicable(Instance.Types.Entity.Unwrap(Ent), "e:addAngleVelocity(a)", DisableContraption)
            return Func(Instance, Ent, ...)
        end)
    end
    do
        local Func Func = Detours.Starfall("instance.Types.PhysObj.Methods.addAngleVelocity", function(Instance, PhysObj, ...)
            BlockPhysObjManipulationIfApplicable(Instance.Types.PhysObj.Unwrap(PhysObj), "physobj:addAngleVelocity(a)", DisableContraption)
            return Func(Instance, PhysObj, ...)
        end)
    end

    -- DETOURS: AddVelocity
    do
        local Func Func = Detours.Starfall("instance.Types.Entity.Methods.addVelocity", function(Instance, Ent, ...)
            BlockEntManipulationIfApplicable(Instance.Types.Entity.Unwrap(Ent), "e:addVelocity(v)", DisableContraption)
            return Func(Instance, Ent, ...)
        end)
    end
    do
        local Func Func = Detours.Starfall("instance.Types.PhysObj.Methods.addVelocity", function(Instance, PhysObj, ...)
            BlockPhysObjManipulationIfApplicable(Instance.Types.PhysObj.Unwrap(PhysObj), "physobj:addVelocity(v)", DisableContraption)
            return Func(Instance, PhysObj, ...)
        end)
    end

    -- DETOURS: SetAngleVelocity
    do
        local Func Func = Detours.Starfall("instance.Types.Entity.Methods.setAngleVelocity", function(Instance, Ent, ...)
            BlockEntManipulationIfApplicable(Instance.Types.Entity.Unwrap(Ent), "e:setAngleVelocity(a)", DisableContraption)
            return Func(Instance, Ent, ...)
        end)
    end
    do
        local Func Func = Detours.Starfall("instance.Types.PhysObj.Methods.setAngleVelocity", function(Instance, PhysObj, ...)
            BlockPhysObjManipulationIfApplicable(Instance.Types.PhysObj.Unwrap(PhysObj), "physobj:setAngleVelocity(a)", DisableContraption)
            return Func(Instance, PhysObj, ...)
        end)
    end

    -- DETOURS: SetVelocity
    do
        local Func Func = Detours.Starfall("instance.Types.Entity.Methods.setVelocity", function(Instance, Ent, ...)
            BlockEntManipulationIfApplicable(Instance.Types.Entity.Unwrap(Ent), "e:setVelocity(v)", DisableContraption)
            return Func(Instance, Ent, ...)
        end)
    end
    do
        local Func Func = Detours.Starfall("instance.Types.PhysObj.Methods.setVelocity", function(Instance, PhysObj, ...)
            BlockPhysObjManipulationIfApplicable(Instance.Types.PhysObj.Unwrap(PhysObj), "physobj:setVelocity(v)", DisableContraption)
            return Func(Instance, PhysObj, ...)
        end)
    end
end)