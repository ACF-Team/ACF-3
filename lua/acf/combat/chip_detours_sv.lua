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

local ATTEMPT_MESSAGE = "Attempted to call %s (a blocked usercall)."
-- These names are... something... but I figure it's better we're explicit about functionality
-- to make the detours easier to read. These are the methods to disable contraptions/families,
-- based on a single entity or physics object.
local function IfEntManipulationOnACFEntity_ThenDisableFamily(Ent, Type)
    if PreCheck() then return true end
    if not IsValid(Ent) then return false end -- thanks setang steering

    if Ent.IsACFEntity then
        return DisableFamily(Ent, ATTEMPT_MESSAGE:format(Type or "UNKNOWN"))
    end
    return true
end

local function IfPhysObjManipulationOnACFEntity_ThenDisableFamily(PhysObj, Type)
    if PreCheck() then return true end
    if not IsValid(PhysObj) then return false end
    local Ent = PhysObj:GetEntity()
    if not IsValid(Ent) then return false end

    if Ent.IsACFEntity then
        return DisableFamily(Ent, ATTEMPT_MESSAGE:format(Type or "UNKNOWN"))
    end

    return true
end

local function IfEntManipulationOnACFContraption_ThenDisableContraption(Ent, Type, RequiredBaseplateType)
    if PreCheck() then return true end
    if not IsValid(Ent) then return false end

    local Contraption = Ent:GetContraption()
    if not Contraption then return true end -- Allow the call on non-contraptions obviously

    if Contraption:ACF_IsACFContraption() then
        if RequiredBaseplateType ~= nil and Contraption:ACF_GetContraptionType() == RequiredBaseplateType then
            -- Early return and allow the call
            return true
        end

        return DisableContraption(Ent, ATTEMPT_MESSAGE:format(Type or "UNKNOWN"))
    end

    return true
end

local function IfPhysObjManipulationOnACFContraption_ThenDisableContraption(PhysObj, Type, RequiredBaseplateType)
    if PreCheck() then return true end
    if not IsValid(PhysObj) then return false end

    local Ent = PhysObj:GetEntity()
    return IfEntManipulationOnACFContraption_ThenDisableContraption(Ent, Type, RequiredBaseplateType)
end

-- The following blocks are the actual detour implementations. They should have TARGET, METHODS, ON CALL comments for
-- development clarity. The individual detour methods are stored in do-end blocks, to isolate the Func local. We could
-- just write out the local for each different detour we do, but I really didnt feel like doing that. I don't think
-- it impacts performance, or if it does, its probably so minimal that it's not even worth it. But correct me if I'm wrong...

-- TARGET  : SetPos
-- METHODS : Expression 2, Starfall (Entity & Physobj bindings)
-- ON CALL : If target is an ACF entity, allow the call to go through, but disable the entire family.
-- We do it this way to allow user-created building tools to work, while still
-- providing programmatic enforcement during combat. 
local function SetPosDetours()
    do
        local Func Func = Detours.Expression2("e:setPos(v)", function(Scope, Args, ...)
            IfEntManipulationOnACFEntity_ThenDisableFamily(Args[1], "e:setPos(v)")
            return Func(Scope, Args, ...)
        end)
    end

    do
        local Func Func = Detours.Starfall("instance.Types.Entity.Methods.setPos", function(Instance, Ent, ...)
            IfEntManipulationOnACFEntity_ThenDisableFamily(Instance.Types.Entity.Unwrap(Ent), "e:setPos(v)")
            return Func(Instance, Ent, ...)
        end)
    end

    do
        local Func Func = Detours.Starfall("instance.Types.PhysObj.Methods.setPos", function(Instance, PhysObj, ...)
            IfPhysObjManipulationOnACFEntity_ThenDisableFamily(Instance.Types.PhysObj.Unwrap(PhysObj), "physobj:setPos(v)")
            return Func(Instance, PhysObj, ...)
        end)
    end
end

-- TARGET  : SetAngles
-- METHODS : Expression 2, Starfall (Entity & Physobj bindings)
-- ON CALL : If target is an ACF entity, allow the call to go through, but disable the entire family.
-- We do it this way to allow user-created building tools to work, while still
-- providing programmatic enforcement during combat. 
local function SetAngDetours()
    do
        local Func Func = Detours.Expression2("e:setAng(a)", function(Scope, Args, ...)
            IfEntManipulationOnACFEntity_ThenDisableFamily(Args[1], "e:setAng(a)")
            return Func(Scope, Args, ...)
        end)
    end

    do
        local Func Func = Detours.Starfall("instance.Types.Entity.Methods.setAngles", function(Instance, Ent, ...)
            IfEntManipulationOnACFEntity_ThenDisableFamily(Instance.Types.Entity.Unwrap(Ent), "e:setAngles(a)")
            return Func(Instance, Ent, ...)
        end)
    end

    do
        local Func Func = Detours.Starfall("instance.Types.PhysObj.Methods.setAngles", function(Instance, PhysObj, ...)
            IfPhysObjManipulationOnACFEntity_ThenDisableFamily(Instance.Types.PhysObj.Unwrap(PhysObj), "physobj:setAngles(a)")
            return Func(Instance, PhysObj, ...)
        end)
    end
end

-- TARGET  : AddAngleVelocity
-- METHODS : Starfall (Entity & Physobj bindings)
-- ON CALL : If target's contraption is an ACF contraption, disable the contraption and block the call.
-- There are no good uses for the direct velocity methods on aircraft, almost everyone uses applyForce/applyTorque methods.
local function AddAngleVelocityDetours()
    do
        local Func Func = Detours.Starfall("instance.Types.Entity.Methods.addAngleVelocity", function(Instance, Ent, ...)
            if not IfEntManipulationOnACFContraption_ThenDisableContraption(Instance.Types.Entity.Unwrap(Ent), "e:addAngleVelocity(a)") then return end
            return Func(Instance, Ent, ...)
        end)
    end
    do
        local Func Func = Detours.Starfall("instance.Types.PhysObj.Methods.addAngleVelocity", function(Instance, PhysObj, ...)
            if not IfPhysObjManipulationOnACFContraption_ThenDisableContraption(Instance.Types.PhysObj.Unwrap(PhysObj), "physobj:addAngleVelocity(a)") then return end
            return Func(Instance, PhysObj, ...)
        end)
    end
end
-- TARGET  : AddVelocity
-- METHODS : Starfall (Entity & Physobj bindings)
-- ON CALL : If target's contraption is an ACF contraption, disable the contraption and block the call.
-- There are no good uses for the direct velocity methods on aircraft, almost everyone uses applyForce/applyTorque methods.
local function AddVelocityDetours()
    do
        local Func Func = Detours.Starfall("instance.Types.Entity.Methods.addVelocity", function(Instance, Ent, ...)
            if not IfEntManipulationOnACFContraption_ThenDisableContraption(Instance.Types.Entity.Unwrap(Ent), "e:addVelocity(v)") then return end
            return Func(Instance, Ent, ...)
        end)
    end
    do
        local Func Func = Detours.Starfall("instance.Types.PhysObj.Methods.addVelocity", function(Instance, PhysObj, ...)
            if not IfPhysObjManipulationOnACFContraption_ThenDisableContraption(Instance.Types.PhysObj.Unwrap(PhysObj), "physobj:addVelocity(v)") then return end
            return Func(Instance, PhysObj, ...)
        end)
    end
end
-- TARGET  : SetAngleVelocity
-- METHODS : Starfall (Entity & Physobj bindings)
-- ON CALL : If target's contraption is an ACF contraption, disable the contraption and block the call.
-- There are no good uses for the direct velocity methods on aircraft, almost everyone uses applyForce/applyTorque methods.
local function SetAngleVelocityDetours()
    -- Propcore - Entity
    do
        local Func Func = Detours.Expression2("e:propSetAngVelocity(v)", function(Scope, Args, ...)
            if not IfEntManipulationOnACFContraption_ThenDisableContraption(Args[1], "e:propSetAngVelocity(v)") then return end
            return Func(Scope, Args, ...)
        end)
    end
    do
        local Func Func = Detours.Expression2("e:propSetAngVelocityInstant(v)", function(Scope, Args, ...)
            if not IfEntManipulationOnACFContraption_ThenDisableContraption(Args[1], "e:propSetAngVelocityInstant(v)") then return end
            return Func(Scope, Args, ...)
        end)
    end

    -- Propcore - Bone
    do
        local Func Func = Detours.Expression2("b:setAngVelocity(v)", function(Scope, Args, ...)
            local Ent = E2Lib.isValidBone(Args[1])
            if not IfEntManipulationOnACFContraption_ThenDisableContraption(Ent, "b:setAngVelocity(v)") then return end
            return Func(Scope, Args, ...)
        end)
    end
    do
        local Func Func = Detours.Expression2("b:setAngVelocityInstant(v)", function(Scope, Args, ...)
            local Ent = E2Lib.isValidBone(Args[1])
            if not IfEntManipulationOnACFContraption_ThenDisableContraption(Ent, "b:setAngVelocityInstant(v)") then return end
            return Func(Scope, Args, ...)
        end)
    end

    -- Starfall
    do
        local Func Func = Detours.Starfall("instance.Types.Entity.Methods.setAngleVelocity", function(Instance, Ent, ...)
            if not IfEntManipulationOnACFContraption_ThenDisableContraption(Instance.Types.Entity.Unwrap(Ent), "e:setAngleVelocity(a)") then return end
            return Func(Instance, Ent, ...)
        end)
    end
    do
        local Func Func = Detours.Starfall("instance.Types.PhysObj.Methods.setAngleVelocity", function(Instance, PhysObj, ...)
            if not IfPhysObjManipulationOnACFContraption_ThenDisableContraption(Instance.Types.PhysObj.Unwrap(PhysObj), "physobj:setAngleVelocity(a)") then return end
            return Func(Instance, PhysObj, ...)
        end)
    end
end
-- TARGET  : SetVelocity
-- METHODS : Starfall (Entity & Physobj bindings)
-- ON CALL : If target's contraption is an ACF contraption, disable the contraption and block the call.
-- There are no good uses for the direct velocity methods on aircraft, almost everyone uses applyForce/applyTorque methods.
local function SetVelocityDetours()
    -- Propcore - Entity
    do
        local Func Func = Detours.Expression2("e:propSetVelocity(v)", function(Scope, Args, ...)
            if not IfEntManipulationOnACFContraption_ThenDisableContraption(Args[1], "e:propSetVelocity(v)") then return end
            return Func(Scope, Args, ...)
        end)
    end
    do
        local Func Func = Detours.Expression2("e:propSetVelocityInstant(v)", function(Scope, Args, ...)
            if not IfEntManipulationOnACFContraption_ThenDisableContraption(Args[1], "e:propSetVelocityInstant(v)") then return end
            return Func(Scope, Args, ...)
        end)
    end

    -- Propcore - Bone
    do
        local Func Func = Detours.Expression2("b:setVelocity(v)", function(Scope, Args, ...)
            local Ent = E2Lib.isValidBone(Args[1])
            if not IfEntManipulationOnACFContraption_ThenDisableContraption(Ent, "b:setVelocity(v)") then return end
            return Func(Scope, Args, ...)
        end)
    end
    do
        local Func Func = Detours.Expression2("b:setVelocityInstant(v)", function(Scope, Args, ...)
            local Ent = E2Lib.isValidBone(Args[1])
            if not IfEntManipulationOnACFContraption_ThenDisableContraption(Ent, "b:setVelocityInstant(v)") then return end
            return Func(Scope, Args, ...)
        end)
    end

    -- Starfall
    do
        local Func Func = Detours.Starfall("instance.Types.Entity.Methods.setVelocity", function(Instance, Ent, ...)
            if not IfEntManipulationOnACFContraption_ThenDisableContraption(Instance.Types.Entity.Unwrap(Ent), "e:setVelocity(v)") then return end
            return Func(Instance, Ent, ...)
        end)
    end
    do
        local Func Func = Detours.Starfall("instance.Types.PhysObj.Methods.setVelocity", function(Instance, PhysObj, ...)
            if not IfPhysObjManipulationOnACFContraption_ThenDisableContraption(Instance.Types.PhysObj.Unwrap(PhysObj), "physobj:setVelocity(v)") then return end
            return Func(Instance, PhysObj, ...)
        end)
    end
end

local function TriggerDetourRebuild()
    Detours.Loaded = true

    SetPosDetours()
    SetAngDetours()
    AddAngleVelocityDetours()
    AddVelocityDetours()
    SetAngleVelocityDetours()
    SetVelocityDetours()
end
ACF.TriggerDetourRebuild = TriggerDetourRebuild
timer.Simple(Detours.Loaded and 0 or 5, TriggerDetourRebuild)