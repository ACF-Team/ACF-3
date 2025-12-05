-- Purpose: Registers a bunch of legality detours for chip interactions with
-- ACF entities and contraptions. Still a lot of work to do here...

local ACF = ACF
local Detours = ACF.Detours

local ENTITY = FindMetaTable("Entity")

local function DisableEntity(Entity, Reason, Message)
    local Disabled = Entity.Disabled
    if not Disabled then -- Only complain if the reason has changed
        ACF.DisableEntity(Entity, Reason, Message, Timeout)
    end
end

-- Crew are explicitly blocked from being disabled, since that will instantly kill all crew members
-- Other entities are fair game though
-- The Player argument is to prevent a case where you could grief other peoples contraptions

local function DisableFamily(Player, Ent, Reason)
    for Entity in pairs(ENTITY.GetFamilyChildren(Ent)) do
        if IsValid(Entity) and ENTITY.CPPIGetOwner(Entity) == Player and Entity.IsACFEntity and not Entity.IsACFCrew then
            DisableEntity(Entity, "Invalid usercall on " .. tostring(Ent) .. "", Reason, 10)
        end
    end

    return false
end

local function DisableContraption(Player, Ent, Reason)
    for Entity in pairs(ENTITY.GetContraption(Ent).ents) do
        if IsValid(Entity) and ENTITY.CPPIGetOwner(Entity) == Player and Entity.IsACFEntity and not Entity.IsACFCrew then
            DisableEntity(Entity, "Invalid usercall on " .. tostring(Ent) .. "", Reason, 10)
        end
    end

    return false
end

local function PreCheck()
    if not ACF.LegalChecks then return true end
end

local ATTEMPT_MESSAGE = "Attempted to use %s (a blocked usercall)."
-- These names are... something... but I figure it's better we're explicit about functionality
-- to make the detours easier to read. These are the methods to disable contraptions/families,
-- based on a single entity or physics object.
local function IfEntManipulationOnACFEntity_ThenDisableFamily(Player, Ent, Type)
    if PreCheck() then return true end
    if not IsValid(Ent) then return true end -- thanks setang steering

    -- If the owner performed the call, allow it to go through, despite the fact we disabled the family
    local CalledOnCalleeOwned = Ent:CPPIGetOwner() == Player
    local Family = Ent:GetFamily()

    if not Family then
        if Ent.IsACFEntity == true then
            DisableEntity(Ent, "Invalid usercall on " .. tostring(Ent) .. "", ATTEMPT_MESSAGE:format(Type or "UNKNOWN"), 10)
            return CalledOnCalleeOwned
        end
        return true
    end

    if Ent.IsACFEntity then
       DisableFamily(Player, Ent, ATTEMPT_MESSAGE:format(Type or "UNKNOWN"))
       return CalledOnCalleeOwned
    end

    return true
end

local function IfPhysObjManipulationOnACFEntity_ThenDisableFamily(Player, PhysObj, Type)
    if PreCheck() then return true end
    if not IsValid(PhysObj) then return false end
    local Ent = PhysObj:GetEntity()
    return IfEntManipulationOnACFEntity_ThenDisableFamily(Player, Ent, Type)
end

local function IfEntManipulationOnACFContraption_ThenDisableContraption(Player, Ent, Type, PostContraptionCheck)
    if PreCheck() then return true end
    if not IsValid(Ent) then return false end

    local Contraption = Ent:GetContraption()
    -- Allow the call on non-contraptions, unless they are ACF entities.
    -- So ACF entities/contraptions with ACF entities get blocked.
    if not Contraption then
        if Ent.IsACFEntity == true then
            DisableEntity(Ent, "Invalid usercall on " .. tostring(Ent) .. "", ATTEMPT_MESSAGE:format(Type or "UNKNOWN"), 10)
            return false
        end
        return true
    end

    if Contraption:ACF_IsACFContraption() then
        if PostContraptionCheck ~= nil then
            local Override = PostContraptionCheck(Contraption)
            if Override == true then return true end
        end
        return DisableContraption(Player, Ent, ATTEMPT_MESSAGE:format(Type or "UNKNOWN"))
    end

    return true
end

local function IfPhysObjManipulationOnACFContraption_ThenDisableContraption(Player, PhysObj, Type, PostContraptionCheck)
    if PreCheck() then return true end
    if not IsValid(PhysObj) then return false end

    local Ent = PhysObj:GetEntity()
    return IfEntManipulationOnACFContraption_ThenDisableContraption(Player, Ent, Type, PostContraptionCheck)
end

local function PostContraptionCheck_IsNotGroundVehicle(Contraption)
    if Contraption:ACF_IsAircraft() or Contraption:ACF_IsRecreational() then
        return true
    end
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
            local CalledOnCalleeOwned = IfEntManipulationOnACFEntity_ThenDisableFamily(Scope.player, Args[1], "e:setPos(v)")
            if CalledOnCalleeOwned then return Func(Scope, Args, ...) end
        end)
    end
    do
        local Func Func = Detours.Expression2("b:setPos(v)", function(Scope, Args, ...)
            local Ent = E2Lib.isValidBone(Args[1])
            local CalledOnCalleeOwned = IfEntManipulationOnACFEntity_ThenDisableFamily(Scope.player, Ent, "b:setPos(v)")
            if CalledOnCalleeOwned then return Func(Scope, Args, ...) end
        end)
    end

    do
        local Func Func = Detours.Starfall("instance.Types.Entity.Methods.setPos", function(Instance, Ent, ...)
            local CalledOnCalleeOwned = IfEntManipulationOnACFEntity_ThenDisableFamily(Instance.player, Instance.Types.Entity.Unwrap(Ent), "e:setPos(v)")
            if CalledOnCalleeOwned then return Func(Instance, Ent, ...) end
        end)
    end

    do
        local Func Func = Detours.Starfall("instance.Types.PhysObj.Methods.setPos", function(Instance, PhysObj, ...)
            local CalledOnCalleeOwned = IfPhysObjManipulationOnACFEntity_ThenDisableFamily(Instance.player, Instance.Types.PhysObj.Unwrap(PhysObj), "physobj:setPos(v)")
            if CalledOnCalleeOwned then return Func(Instance, PhysObj, ...) end
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
            local CalledOnCalleeOwned = IfEntManipulationOnACFEntity_ThenDisableFamily(Scope.player, Args[1], "e:setAng(a)")
            if CalledOnCalleeOwned then return Func(Scope, Args, ...) end
        end)
    end
    do
        local Func Func = Detours.Expression2("b:setAng(a)", function(Scope, Args, ...)
            local Ent = E2Lib.isValidBone(Args[1])
            local CalledOnCalleeOwned = IfEntManipulationOnACFEntity_ThenDisableFamily(Scope.player, Ent, "b:setAng(a)")
            if CalledOnCalleeOwned then return Func(Scope, Args, ...) end
        end)
    end

    do
        local Func Func = Detours.Starfall("instance.Types.Entity.Methods.setAngles", function(Instance, Ent, ...)
            local CalledOnCalleeOwned = IfEntManipulationOnACFEntity_ThenDisableFamily(Instance.player, Instance.Types.Entity.Unwrap(Ent), "e:setAngles(a)")
            if CalledOnCalleeOwned then return Func(Instance, Ent, ...) end
        end)
    end

    do
        local Func Func = Detours.Starfall("instance.Types.PhysObj.Methods.setAngles", function(Instance, PhysObj, ...)
            local CalledOnCalleeOwned = IfPhysObjManipulationOnACFEntity_ThenDisableFamily(Instance.player, Instance.Types.PhysObj.Unwrap(PhysObj), "physobj:setAngles(a)")
            if CalledOnCalleeOwned then return Func(Instance, PhysObj, ...) end
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
            if not IfEntManipulationOnACFContraption_ThenDisableContraption(Instance.player, Instance.Types.Entity.Unwrap(Ent), "e:addAngleVelocity(a)", PostContraptionCheck_IsNotGroundVehicle) then return end
            return Func(Instance, Ent, ...)
        end)
    end
    do
        local Func Func = Detours.Starfall("instance.Types.PhysObj.Methods.addAngleVelocity", function(Instance, PhysObj, ...)
            if not IfPhysObjManipulationOnACFContraption_ThenDisableContraption(Instance.player, Instance.Types.PhysObj.Unwrap(PhysObj), "physobj:addAngleVelocity(a)", PostContraptionCheck_IsNotGroundVehicle) then return end
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
            if not IfEntManipulationOnACFContraption_ThenDisableContraption(Instance.player, Instance.Types.Entity.Unwrap(Ent), "e:addVelocity(v)") then return end
            return Func(Instance, Ent, ...)
        end)
    end
    do
        local Func Func = Detours.Starfall("instance.Types.PhysObj.Methods.addVelocity", function(Instance, PhysObj, ...)
            if not IfPhysObjManipulationOnACFContraption_ThenDisableContraption(Instance.player, Instance.Types.PhysObj.Unwrap(PhysObj), "physobj:addVelocity(v)") then return end
            return Func(Instance, PhysObj, ...)
        end)
    end
end
-- TARGET  : SetAngleVelocity
-- METHODS : Expression 2, Starfall (Entity & Physobj bindings)
-- ON CALL : If target's contraption is an ACF contraption, disable the contraption and block the call.
-- There are no good uses for the direct velocity methods on aircraft, almost everyone uses applyForce/applyTorque methods.
local function SetAngleVelocityDetours()
    -- Propcore - Entity
    do
        local Func Func = Detours.Expression2("e:propSetAngVelocity(v)", function(Scope, Args, ...)
            if not IfEntManipulationOnACFContraption_ThenDisableContraption(Scope.player, Args[1], "e:propSetAngVelocity(v)") then return end
            return Func(Scope, Args, ...)
        end)
    end
    do
        local Func Func = Detours.Expression2("e:propSetAngVelocityInstant(v)", function(Scope, Args, ...)
            if not IfEntManipulationOnACFContraption_ThenDisableContraption(Scope.player, Args[1], "e:propSetAngVelocityInstant(v)") then return end
            return Func(Scope, Args, ...)
        end)
    end

    -- Propcore - Bone
    do
        local Func Func = Detours.Expression2("b:setAngVelocity(v)", function(Scope, Args, ...)
            local Ent = E2Lib.isValidBone(Args[1])
            if not IfEntManipulationOnACFContraption_ThenDisableContraption(Scope.player, Ent, "b:setAngVelocity(v)") then return end
            return Func(Scope, Args, ...)
        end)
    end
    do
        local Func Func = Detours.Expression2("b:setAngVelocityInstant(v)", function(Scope, Args, ...)
            local Ent = E2Lib.isValidBone(Args[1])
            if not IfEntManipulationOnACFContraption_ThenDisableContraption(Scope.player, Ent, "b:setAngVelocityInstant(v)") then return end
            return Func(Scope, Args, ...)
        end)
    end

    -- Starfall
    do
        local Func Func = Detours.Starfall("instance.Types.Entity.Methods.setAngleVelocity", function(Instance, Ent, ...)
            if not IfEntManipulationOnACFContraption_ThenDisableContraption(Instance.player, Instance.Types.Entity.Unwrap(Ent), "e:setAngleVelocity(a)") then return end
            return Func(Instance, Ent, ...)
        end)
    end
    do
        local Func Func = Detours.Starfall("instance.Types.PhysObj.Methods.setAngleVelocity", function(Instance, PhysObj, ...)
            if not IfPhysObjManipulationOnACFContraption_ThenDisableContraption(Instance.player, Instance.Types.PhysObj.Unwrap(PhysObj), "physobj:setAngleVelocity(a)") then return end
            return Func(Instance, PhysObj, ...)
        end)
    end
end
-- TARGET  : SetVelocity
-- METHODS : Expression 2, Starfall (Entity & Physobj bindings)
-- ON CALL : If target's contraption is an ACF contraption, disable the contraption and block the call.
-- There are no good uses for the direct velocity methods on aircraft, almost everyone uses applyForce/applyTorque methods.
local function SetVelocityDetours()
    -- Propcore - Entity
    do
        local Func Func = Detours.Expression2("e:propSetVelocity(v)", function(Scope, Args, ...)
            if not IfEntManipulationOnACFContraption_ThenDisableContraption(Scope.player, Args[1], "e:propSetVelocity(v)") then return end
            return Func(Scope, Args, ...)
        end)
    end
    do
        local Func Func = Detours.Expression2("e:propSetVelocityInstant(v)", function(Scope, Args, ...)
            if not IfEntManipulationOnACFContraption_ThenDisableContraption(Scope.player, Args[1], "e:propSetVelocityInstant(v)") then return end
            return Func(Scope, Args, ...)
        end)
    end

    -- Propcore - Bone
    do
        local Func Func = Detours.Expression2("b:setVelocity(v)", function(Scope, Args, ...)
            local Ent = E2Lib.isValidBone(Args[1])
            if not IfEntManipulationOnACFContraption_ThenDisableContraption(Scope.player, Ent, "b:setVelocity(v)") then return end
            return Func(Scope, Args, ...)
        end)
    end
    do
        local Func Func = Detours.Expression2("b:setVelocityInstant(v)", function(Scope, Args, ...)
            local Ent = E2Lib.isValidBone(Args[1])
            if not IfEntManipulationOnACFContraption_ThenDisableContraption(Scope.player, Ent, "b:setVelocityInstant(v)") then return end
            return Func(Scope, Args, ...)
        end)
    end

    -- Starfall
    do
        local Func Func = Detours.Starfall("instance.Types.Entity.Methods.setVelocity", function(Instance, Ent, ...)
            if not IfEntManipulationOnACFContraption_ThenDisableContraption(Instance.player, Instance.Types.Entity.Unwrap(Ent), "e:setVelocity(v)") then return end
            return Func(Instance, Ent, ...)
        end)
    end
    do
        local Func Func = Detours.Starfall("instance.Types.PhysObj.Methods.setVelocity", function(Instance, PhysObj, ...)
            if not IfPhysObjManipulationOnACFContraption_ThenDisableContraption(Instance.player, Instance.Types.PhysObj.Unwrap(PhysObj), "physobj:setVelocity(v)") then return end
            return Func(Instance, PhysObj, ...)
        end)
    end
end

-- TARGET  : ApplyForceCenter, ApplyForceOffset
-- METHODS : Expression 2, Starfall (Entity & Physobj bindings)
-- ON CALL : If target's contraption is an ACF contraption, and is a ground vehicle, disable the contraption and block the call.
-- We will eventually block it outright, but it is still justifiable on aircraft.
local function ApplyForceDetours()
    -- Expression 2
    do
        local Func Func = Detours.Expression2("applyForce(v)", function(Scope, Args, ...)
            if not IfEntManipulationOnACFContraption_ThenDisableContraption(Scope.player, Args[1], "applyForce(v)", PostContraptionCheck_IsNotGroundVehicle) then return end
            return Func(Scope, Args, ...)
        end)
    end
    do
        local Func Func = Detours.Expression2("e:applyForce(v)", function(Scope, Args, ...)
            if not IfEntManipulationOnACFContraption_ThenDisableContraption(Scope.player, Args[1], "e:applyForce(v)", PostContraptionCheck_IsNotGroundVehicle) then return end
            return Func(Scope, Args, ...)
        end)
    end
    do
        local Func Func = Detours.Expression2("b:applyForce(v)", function(Scope, Args, ...)
            local Ent = E2Lib.isValidBone(Args[1])
            if not IfEntManipulationOnACFContraption_ThenDisableContraption(Scope.player, Ent, "b:applyForce(v)", PostContraptionCheck_IsNotGroundVehicle) then return end
            return Func(Scope, Args, ...)
        end)
    end

    do
        local Func Func = Detours.Expression2("applyOffsetForce(vv)", function(Scope, Args, ...)
            if not IfEntManipulationOnACFContraption_ThenDisableContraption(Scope.player, Args[1], "applyOffsetForce(vv)", PostContraptionCheck_IsNotGroundVehicle) then return end
            return Func(Scope, Args, ...)
        end)
    end
    do
        local Func Func = Detours.Expression2("e:applyOffsetForce(vv)", function(Scope, Args, ...)
            if not IfEntManipulationOnACFContraption_ThenDisableContraption(Scope.player, Args[1], "e:applyOffsetForce(vv)", PostContraptionCheck_IsNotGroundVehicle) then return end
            return Func(Scope, Args, ...)
        end)
    end
    do
        local Func Func = Detours.Expression2("b:applyOffsetForce(vv)", function(Scope, Args, ...)
            local Ent = E2Lib.isValidBone(Args[1])
            if not IfEntManipulationOnACFContraption_ThenDisableContraption(Scope.player, Ent, "b:applyOffsetForce(vv)", PostContraptionCheck_IsNotGroundVehicle) then return end
            return Func(Scope, Args, ...)
        end)
    end

    -- Starfall
    do
        local Func Func = Detours.Starfall("instance.Types.Entity.Methods.applyForceCenter", function(Instance, Ent, ...)
            if not IfEntManipulationOnACFContraption_ThenDisableContraption(Instance.player, Instance.Types.Entity.Unwrap(Ent), "e:applyForceCenter(v)", PostContraptionCheck_IsNotGroundVehicle) then return end
            return Func(Instance, Ent, ...)
        end)
    end
    do
        local Func Func = Detours.Starfall("instance.Types.PhysObj.Methods.applyForceCenter", function(Instance, PhysObj, ...)
            if not IfPhysObjManipulationOnACFContraption_ThenDisableContraption(Instance.player, Instance.Types.PhysObj.Unwrap(PhysObj), "physobj:applyForceCenter(v)", PostContraptionCheck_IsNotGroundVehicle) then return end
            return Func(Instance, PhysObj, ...)
        end)
    end

    do
        local Func Func = Detours.Starfall("instance.Types.Entity.Methods.applyForceOffset", function(Instance, Ent, ...)
            if not IfEntManipulationOnACFContraption_ThenDisableContraption(Instance.player, Instance.Types.Entity.Unwrap(Ent), "e:applyForceOffset(v, v)", PostContraptionCheck_IsNotGroundVehicle) then return end
            return Func(Instance, Ent, ...)
        end)
    end
    do
        local Func Func = Detours.Starfall("instance.Types.PhysObj.Methods.applyForceOffset", function(Instance, PhysObj, ...)
            if not IfPhysObjManipulationOnACFContraption_ThenDisableContraption(Instance.player, Instance.Types.PhysObj.Unwrap(PhysObj), "physobj:applyForceOffset(v, v)", PostContraptionCheck_IsNotGroundVehicle) then return end
            return Func(Instance, PhysObj, ...)
        end)
    end

    -- Gates
    do
        local Func Func = Detours.WireGate("entity_applyf", function(Gate, Ent, Vec, ...)
            if not IfEntManipulationOnACFContraption_ThenDisableContraption(Gate:CPPIGetOwner(), Ent, "Gate 'Apply Force'", PostContraptionCheck_IsNotGroundVehicle) then return end
            return Func(Gate, Ent, Vec, ...)
        end)
    end
    do
        local Func Func = Detours.WireGate("entity_applyof", function(Gate, Ent, Vec, Offset, ...)
            if not IfEntManipulationOnACFContraption_ThenDisableContraption(Gate:CPPIGetOwner(), Ent, "Gate 'Apply Offset Force'", PostContraptionCheck_IsNotGroundVehicle) then return end
            return Func(Gate, Ent, Vec, Offset, ...)
        end)
    end
end

-- TARGET  : ApplyTorque, ApplyAngForce
-- METHODS : Expression 2, Starfall (Entity & Physobj bindings)
-- ON CALL : If target is an ACF entity, allow the call to go through, but disable the entire family.
-- ON CALL : If target's contraption is an ACF contraption, and is a ground vehicle, disable the contraption and block the call.
-- We will eventually block it outright, but it is still justifiable on aircraft.
local function ApplyTorqueDetours()
    -- Expression 2
    do
        local Func Func = Detours.Expression2("applyAngForce(a)", function(Scope, Args, ...)
            if not IfEntManipulationOnACFContraption_ThenDisableContraption(Scope.player, Args[1], "applyAngForce(a)", PostContraptionCheck_IsNotGroundVehicle) then return end
            return Func(Scope, Args, ...)
        end)
    end
    do
        local Func Func = Detours.Expression2("e:applyAngForce(a)", function(Scope, Args, ...)
            if not IfEntManipulationOnACFContraption_ThenDisableContraption(Scope.player, Args[1], "e:applyAngForce(a)", PostContraptionCheck_IsNotGroundVehicle) then return end
            return Func(Scope, Args, ...)
        end)
    end
    do
        local Func Func = Detours.Expression2("b:applyAngForce(a)", function(Scope, Args, ...)
            local Ent = E2Lib.isValidBone(Args[1])
            if not IfEntManipulationOnACFContraption_ThenDisableContraption(Scope.player, Ent, "b:applyAngForce(a)", PostContraptionCheck_IsNotGroundVehicle) then return end
            return Func(Scope, Args, ...)
        end)
    end

    do
        local Func Func = Detours.Expression2("applyTorque(v)", function(Scope, Args, ...)
            if not IfEntManipulationOnACFContraption_ThenDisableContraption(Scope.player, Args[1], "applyTorque(v)", PostContraptionCheck_IsNotGroundVehicle) then return end
            return Func(Scope, Args, ...)
        end)
    end
    do
        local Func Func = Detours.Expression2("e:applyTorque(v)", function(Scope, Args, ...)
            if not IfEntManipulationOnACFContraption_ThenDisableContraption(Scope.player, Args[1], "e:applyTorque(v)", PostContraptionCheck_IsNotGroundVehicle) then return end
            return Func(Scope, Args, ...)
        end)
    end
    do
        local Func Func = Detours.Expression2("b:applyTorque(v)", function(Scope, Args, ...)
            local Ent = E2Lib.isValidBone(Args[1])
            if not IfEntManipulationOnACFContraption_ThenDisableContraption(Scope.player, Ent, "b:applyTorque(v)", PostContraptionCheck_IsNotGroundVehicle) then return end
            return Func(Scope, Args, ...)
        end)
    end

    -- Starfall
    do
        local Func Func = Detours.Starfall("instance.Types.Entity.Methods.applyAngForce", function(Instance, Ent, ...)
            if not IfEntManipulationOnACFContraption_ThenDisableContraption(Instance.player, Instance.Types.Entity.Unwrap(Ent), "e:applyAngForce(a)", PostContraptionCheck_IsNotGroundVehicle) then return end
            return Func(Instance, Ent, ...)
        end)
    end
    do
        local Func Func = Detours.Starfall("instance.Types.PhysObj.Methods.applyAngForce", function(Instance, PhysObj, ...)
            if not IfPhysObjManipulationOnACFContraption_ThenDisableContraption(Instance.player, Instance.Types.PhysObj.Unwrap(PhysObj), "physobj:applyAngForce(a)", PostContraptionCheck_IsNotGroundVehicle) then return end
            return Func(Instance, PhysObj, ...)
        end)
    end

    do
        local Func Func = Detours.Starfall("instance.Types.Entity.Methods.applyTorque", function(Instance, Ent, ...)
            if not IfEntManipulationOnACFContraption_ThenDisableContraption(Instance.player, Instance.Types.Entity.Unwrap(Ent), "e:applyTorque(v)", PostContraptionCheck_IsNotGroundVehicle) then return end
            return Func(Instance, Ent, ...)
        end)
    end
    do
        local Func Func = Detours.Starfall("instance.Types.PhysObj.Methods.applyTorque", function(Instance, PhysObj, ...)
            if not IfPhysObjManipulationOnACFContraption_ThenDisableContraption(Instance.player, Instance.Types.PhysObj.Unwrap(PhysObj), "physobj:applyTorque(v)", PostContraptionCheck_IsNotGroundVehicle) then return end
            return Func(Instance, PhysObj, ...)
        end)
    end

    -- Gates
    do
        local Func Func = Detours.WireGate("entity_applyaf", function(Gate, Ent, Ang, ...)
            if not IfEntManipulationOnACFContraption_ThenDisableContraption(Gate:CPPIGetOwner(), Ent, "Gate 'Apply Angular Force'", PostContraptionCheck_IsNotGroundVehicle) then return end
            return Func(Gate, Ent, Ang, ...)
        end)
    end
    do
        local Func Func = Detours.WireGate("entity_applytorq", function(Gate, Ent, Vec, ...)
            if not IfEntManipulationOnACFContraption_ThenDisableContraption(Gate:CPPIGetOwner(), Ent, "Gate 'Apply Torque'", PostContraptionCheck_IsNotGroundVehicle) then return end
            return Func(Gate, Ent, Vec, ...)
        end)
    end
end

local function GmodThrusterDetours()
    do
        local Func Func = Detours.SENT("gmod_thruster", "PhysicsSimulate", function(self, ...)
            if not self:IsOn() then return Func(self, ...) end
            if not IfEntManipulationOnACFContraption_ThenDisableContraption(self:CPPIGetOwner(), self, "Sandbox Thruster:PhysicsSimulate") then return SIM_NOTHING end
            return Func(self, ...)
        end)
    end
end

local function WireThrusterDetours()
    do
        local Func Func = Detours.SENT("gmod_wire_thruster", "PhysicsSimulate", function(self, ...)
            if not self:IsOn() then return Func(self, ...) end
            if not IfEntManipulationOnACFContraption_ThenDisableContraption(self:CPPIGetOwner(), self, "Wiremod Thruster:PhysicsSimulate") then return SIM_NOTHING end
            return Func(self, ...)
        end)
    end

    do
        local Func Func = Detours.SENT("gmod_wire_vectorthruster", "PhysicsSimulate", function(self, ...)
            if not self:IsOn() then return Func(self, ...) end
            if not IfEntManipulationOnACFContraption_ThenDisableContraption(self:CPPIGetOwner(), self, "Wiremod Vector Thruster:PhysicsSimulate") then return SIM_NOTHING end
            return Func(self, ...)
        end)
    end
end

local function GmodHoverballDetours()
    do
        local Func Func = Detours.SENT("gmod_hoverball", "PhysicsSimulate", function(self, ...)
            if not self:GetEnabled() then return Func(self, ...) end
            if not IfEntManipulationOnACFContraption_ThenDisableContraption(self:CPPIGetOwner(), self, "Sandbox Hoverball:PhysicsSimulate") then return SIM_NOTHING end
            return Func(self, ...)
        end)
    end
end

local function WireHoverballDetours()
    do
        local Func Func = Detours.SENT("gmod_wire_hoverball", "PhysicsSimulate", function(self, ...)
            if not self:IsOn() then return Func(self, ...) end
            if not IfEntManipulationOnACFContraption_ThenDisableContraption(self:CPPIGetOwner(), self, "Wiremod Hoverball:PhysicsSimulate") then return SIM_NOTHING end
            return Func(self, ...)
        end)
    end
end

local function WireTeleporterDetours()
    do
        local Func Func = Detours.SENT("gmod_wire_teleporter", "Jump", function(self, ...)
            if not IfEntManipulationOnACFContraption_ThenDisableContraption(self:CPPIGetOwner(), self, "Wiremod Teleporter:Jump") then return end
            return Func(self, ...)
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
    ApplyForceDetours()
    ApplyTorqueDetours()

    GmodThrusterDetours()
    GmodHoverballDetours()

    WireThrusterDetours()
    WireHoverballDetours()

    WireTeleporterDetours()
end

ACF.TriggerDetourRebuild = TriggerDetourRebuild
timer.Simple(Detours.Loaded and 0 or 5, TriggerDetourRebuild)