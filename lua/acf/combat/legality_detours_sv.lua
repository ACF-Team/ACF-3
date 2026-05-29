-- Purpose: Registers a bunch of legality detours for chip interactions with
-- ACF entities and contraptions. Still a lot of work to do here...

local ACF = ACF
local Detours = ACF.Detours
local Notify  = ACF.Utilities.Notify
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

local function DisableEntityCheckable(Player, Entity, Reason)
    if IsValid(Entity) and ENTITY.CPPICanTool(Entity, Player, "") and Entity.IsACFEntity and not Entity.IsACFCrew then
        DisableEntity(Entity, "Invalid usercall on " .. tostring(Entity) .. "", Reason, 10)
    end
end


local function DisableFamily(Player, Ent, Reason)
    DisableEntityCheckable(Player, Ent, Reason)
    for Entity in pairs(ENTITY.GetFamilyChildren(Ent)) do
        DisableEntityCheckable(Player, Entity, Reason)
    end

    return false
end

local function DisableContraption(Player, Ent, Reason)
    DisableEntityCheckable(Player, Ent, Reason)
    for Entity in pairs(ENTITY.CFW_GetContraption(Ent).ents) do
        DisableEntityCheckable(Player, Entity, Reason)
    end

    return false
end

local function PreCheck()
    if not ACF.LegalityDetours then return true end
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

    local Contraption = Ent:CFW_GetContraption()
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

-- TARGET  : Freezers and propFreeze equiv.
-- METHODS : Expression 2, Starfall (Entity & Physobj bindings), Wiremod
-- ON CALL : If target's contraption is an ACF contraption, disable the contraption and block the call.
-- There are no good uses for freezing mid-air on an ACF contraption.
-- We will allow unfreezing though, I don't see a problem with that.
-- The most common abuse vector for these are what people refer to as "freezer brakes" to stop mid-air on aircraft/jumping tanks/
-- regular tanks.
local function FreezeDetours()
    -- Propcore - Entity
    do
        local Func Func = Detours.Expression2("e:propFreeze(n)", function(Scope, Args, ...)
            if Args[2] ~= 0 and not IfEntManipulationOnACFContraption_ThenDisableContraption(Scope.player, Args[1], "e:propFreeze(n)") then return end
            return Func(Scope, Args, ...)
        end)
    end
    do
        local Func Func = Detours.Expression2("e:ragdollFreeze(n)", function(Scope, Args, ...)
            if Args[2] ~= 0 and not IfEntManipulationOnACFContraption_ThenDisableContraption(Scope.player, Args[1], "e:ragdollFreeze(n)") then return end
            return Func(Scope, Args, ...)
        end)
    end
    -- Propcore - Bone
    do
        local Func Func = Detours.Expression2("b:boneFreeze(n)", function(Scope, Args, ...)
            local Ent = E2Lib.isValidBone(Args[1])
            if Args[2] ~= 0 and not IfEntManipulationOnACFContraption_ThenDisableContraption(Scope.player, Ent, "b:boneFreeze(n)") then return end
            return Func(Scope, Args, ...)
        end)
    end
    -- Starfall
    do
        local Func Func = Detours.Starfall("instance.Types.Entity.Methods.enableMotion", function(Instance, Ent, Move, ...)
            if not Move and not IfEntManipulationOnACFContraption_ThenDisableContraption(Instance.player, Instance.Types.Entity.Unwrap(Ent), "e:enableMotion(n)") then return end
            return Func(Instance, Ent, Move, ...)
        end)
    end
    do
        local Func Func = Detours.Starfall("instance.Types.PhysObj.Methods.enableMotion", function(Instance, PhysObj, Move, ...)
            if not Move and not IfPhysObjManipulationOnACFContraption_ThenDisableContraption(Instance.player, Instance.Types.PhysObj.Unwrap(PhysObj), "physobj:enableMotion(n)") then return end
            return Func(Instance, PhysObj, Move, ...)
        end)
    end
    -- Wiremod freezers. They call into this hook. Very convenient compared to other entity detours we've had to do...
    do
        hook.Add("OnPhysgunFreeze", "ACF_LegalityDetours_WiremodFreezer", function(Weapon, _, Ent, Player)
            if  IsValid(Weapon)
                and Weapon:GetClass() == "gmod_wire_freezer"
                and not IfEntManipulationOnACFContraption_ThenDisableContraption(Player, Ent, "Wire Freezer Activate ~= 0")
            then
                return false
            end
        end)
    end
end

-- TARGET  : Entering seats on ACF contraptions remotely
-- METHODS : Expression 2, Starfall (Entity & Physobj bindings), Wiremod
-- ON CALL : If target's contraption is an ACF contraption, evaluate the distance between the player, and the to-be-used entity.
-- We will allow the call if the distance is within ~120 Source units. Which is actually quite generous, the limit
-- defined in baseplayer_shared.h (PLAYER_USE_RADIUS) is 80 units.

local PLAYER_USE_RADIUS = 120
local function ApproveUseEntity(PlayerInvoker, ToBeUsedEntity, DoNotify)
    if PreCheck() then return true end
    if not IsValid(PlayerInvoker) then return end
    if not IsValid(ToBeUsedEntity) then return end

    -- We don't care about non-vehicles in this case.
    -- TODO: Should we...?
    if not ToBeUsedEntity:IsVehicle() and ToBeUsedEntity:GetClass() ~= "acf_baseplate" then return true end

    local PlayerPos, ToBeUsedPos = PlayerInvoker:GetPos(), ToBeUsedEntity:GetPos()

    local DistanceFromPlayerToUsed  = PlayerPos:Distance(ToBeUsedPos)
    if DistanceFromPlayerToUsed > PLAYER_USE_RADIUS then
        local Contraption = ToBeUsedEntity:CFW_GetContraption()
        if not Contraption then return true end -- We don't care about non-contraptions, that's none of our business.

        -- Otherwise, if not an ACF contraption, approve it, otherwise deny it.
        if Contraption:ACF_IsACFContraption() then
            if DoNotify then
                Notify.EntityWarningToPlayer(ToBeUsedEntity, PlayerInvoker, "Cannot remote-use an ACF contraption from this distance.", string.format("The distance from your player to the target entity was %d, which exceeds the distance limit of %d", DistanceFromPlayerToUsed, PLAYER_USE_RADIUS))
            end
            return false
        end
    end

    return true
end

local function UseDetours()
    -- Propcore - Entity
    do
        local Func Func = Detours.Expression2("e:canUse(e)", function(Scope, Args, ...)
            if not IsValid(Args[1]) then return end
            if not Args[1]:IsPlayer() then return end

            if not ApproveUseEntity(Args[1], Args[2], false) then return end
            return Func(Scope, Args, ...)
        end)
    end
    do
        local Func Func = Detours.Expression2("e:use()", function(Scope, Args, ...)
            if not ApproveUseEntity(Scope.player, Args[1], true) then return end
            return Func(Scope, Args, ...)
        end)
    end
    -- Starfall
    do
        local Func Func = Detours.Starfall("instance.Types.Entity.Methods.use", function(Instance, Ent, ...)
            if not ApproveUseEntity(Instance.player, Instance.Types.Entity.Unwrap(Ent), true) then return end
            return Func(Instance, Ent, ...)
        end)
    end
    -- Wiremod users. 
    -- Wiremod users and E2 use a "WireUse" hook. Which would be great, if the E2 change wasn't 7 months ago and the user change 3 years ago...
    -- (i don't trust most servers to keep their addons up to date)
    -- Arguably would be fine for users (3+ years ago is a while now...), and I may re-evaluate later. For now, its just easier to do this. 
    do
        Detours.SENT("gmod_wire_user", "TriggerInput", function(self, iname, value)
            if iname == "Fire" and value ~= 0 then
                local start = self:GetPos()

                local ent = util.TraceLine({
                    start = start,
                    endpos = start + self:GetUp() * self:GetBeamLength(),
                    filter = self
                }).Entity

                if not ent:IsValid() then return end

                local ply = self:GetPlayer()
                if not ply:IsValid() then return end

                if not ApproveUseEntity(ply, ent, true) then return false end

                if hook.Run("PlayerUse", ply, ent) == false then return end
                if hook.Run("WireUse", ply, ent, self) == false then return end

                ent:Use(ply, self)
            end
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

-- Somehow missed this one...
-- This hook is also 3+ years old. Hopefully servers are up to date enough for this...
local function WireForcerDetours()
    hook.Add("Wire_ForcerCanUse", "ACF_LegalityDetours_BlockForcers", function(ply, ent, _)
        if not IfEntManipulationOnACFContraption_ThenDisableContraption(ply, ent, "Wiremod Forcer") then return false end
    end)
end

-- TARGET  : Constraints between world <---> ACF contraptions
local function ConstraintDetours()
    local function DetermineValidConstraint_WorldCheck(Entity1, Entity2, Type, DoNotify, NoCollideState)
        if PreCheck() then return true end
        -- Early exit. This will result in these functions being called a 2nd time in the actual constraint creators,
        -- but if we dont do this check here, we'd be both wasting time and potentially get nasty side effects (this runs
        -- so early on, we dont know if Entity1 or Entity2 are valid inputs from the developers calling these functions...)
        -- We assume bone #0 exists at least??? We aren't making the constraint here, so I don't see a reason to capture the argument,
        -- and pass it into every call of this function
        if not constraint.CanConstrain(Entity1, 0) then return false end
        if not constraint.CanConstrain(Entity2, 0) then return false end

        if Entity1 == Entity2 then return true end -- We don't care if the entities are the same (for whatever reason)

        -- Determine which side is the world, and which side isn't, if one side is the world at all.
        local WorldEntity = game.GetWorld()
        local NonWorldEntity

        if Entity1 == WorldEntity then
            NonWorldEntity = Entity2
        elseif Entity2 == WorldEntity then
            NonWorldEntity = Entity1
        else
            return true -- We don't care, it's not trying to constrain to the world.
        end

        local Contraption = NonWorldEntity:CFW_GetContraption()
        if not Contraption then return true end -- We don't care about non-contraptions.

        if not Contraption:ACF_IsACFContraption() then return true end -- We don't care about non-ACF contraptions.

        -- Final chance: if NoCollideState is passed, then only return false if NoCollideState is true (kind of a hack)
        -- This should probably be rewritten to use something that requires less to be passed around but w/e
        print(NoCollideState)
        if NoCollideState ~= nil and NoCollideState == false or NoCollideState == 0 then return true end

        -- Ok, something tried to use a detoured constraint an ACF contraption to the world. Block it
        if DoNotify then
            local Player = NonWorldEntity:CPPIGetOwner()
            if IsValid(Player) then
                Notify.EntityWarningToPlayer(NonWorldEntity, Player, string.format("Cannot create constraint '%s'", Type), "Tried to constrain an ACF contraption to the world.")
            end
        end

        return false
    end

    local ONLY_CHECK_WORLD          = 1
    local ALWAYS_REMOVE             = 2

    local isConstraint  = {
        phys_hinge              = ONLY_CHECK_WORLD, -- axis
        phys_lengthconstraint   = ONLY_CHECK_WORLD, -- rope
        phys_constraint         = ONLY_CHECK_WORLD, -- weld
        phys_ballsocket         = ONLY_CHECK_WORLD, -- ballsocket
        phys_spring             = ONLY_CHECK_WORLD, -- elastic, hydraulics, muscles
        phys_pulleyconstraint   = ONLY_CHECK_WORLD, -- pulley (do people ever use these?)
        phys_slideconstraint    = ONLY_CHECK_WORLD, -- sliders
        phys_ragdollconstraint  = ONLY_CHECK_WORLD, -- adv. ballsocket
        phys_keepupright        = ALWAYS_REMOVE
    }

    -- These detour at the Lua level. I am not sure if that's the right approach. Normally, I would detour at a chip/individual entity
    -- level. However, there are just so many things that can do these kinds of operations...
    -- The validity of these constraints is also pretty universal. In general, there are no legitimate reasons to use these constraints
    -- to constrain an ACF contraption entity to the world.

    -- If this becomes a problem, then we will have to go through on an individual basis in E2, Starfall, and Wiremod. Which would be very annoying.

    local function PostActionUnsetUpright(Constraint) local Ent1 = Constraint.Ent1 if IsValid(Ent1) then Ent1:SetNWBool("IsUpright", false) end end
    local function GetNonWorldOwner(Entity1, Entity2) if IsValid(Entity1) then return Entity1, Entity1:CPPIGetOwner() else return Entity2, Entity2:CPPIGetOwner() end end
    local function CheckPreExistingConstraint(EntityClassName, Constraint, CheckAction)
        local PhysObj1, PhysObj2 = Constraint:GetConstrainedPhysObjects()
        local PostAction
        local PhysObj1_Valid, PhysObj2_Valid = IsValid(PhysObj1), IsValid(PhysObj2)
        if not PhysObj1_Valid and not PhysObj2_Valid and Constraint:GetClass() == "phys_keepupright" then
            -- It's weird, because it calls SetPhysConstraintObjects like the other constraints...
            local Table = Constraint:GetTable()
            local Ent1 = Table.Ent1
            if IsValid(Ent1) then
                PhysObj1 = Ent1:GetPhysicsObject()
                PhysObj2 = PhysObj1

                PhysObj1_Valid, PhysObj2_Valid = IsValid(PhysObj1), IsValid(PhysObj2)
                PostAction = PostActionUnsetUpright
            else
                return
            end
        end

        if not PhysObj1_Valid or not PhysObj2_Valid then return end

        local Entity1, Entity2   = PhysObj1:GetEntity(), PhysObj2:GetEntity()
        if CheckAction == ONLY_CHECK_WORLD then
            if not DetermineValidConstraint_WorldCheck(Entity1, Entity2, "", false, Constraint.NoCollide) then
                -- Remove the constraint.
                Constraint:Remove()
                if PostAction then
                    PostAction(Constraint)
                end
                local NonWorldEntity, Owner = GetNonWorldOwner(Entity1, Entity2)
                if IsValid(Owner) then
                    Notify.EntityWarningToPlayer(NonWorldEntity, Owner, string.format("Cannot keep constraint class '%s'", EntityClassName), "Tried to constrain an ACF contraption to the world.")
                end
            end
        elseif CheckAction == ALWAYS_REMOVE then
            -- Remove the constraint.
            Constraint:Remove()
            if PostAction then
                PostAction(Constraint)
            end
            local NonWorldEntity, Owner = GetNonWorldOwner(Entity1, Entity2)
            if IsValid(Owner) then
                Notify.EntityWarningToPlayer(NonWorldEntity, Owner, string.format("Cannot keep constraint class '%s'", EntityClassName), "This constraint cannot exist on ACF contraptions")
            end
        end
    end

    -- this hook handles cases where constraints are made before we have the ACF contraption guard
    hook.Add("cfw.contraption.entityAdded", "ACF_LegalityDetours_NewEntity_CheckConstraints", function(Contraption, Entity)
        if PreCheck() then return end
        if not Contraption:ACF_IsACFContraption() then return end

        -- Check constraints
        if not constraint.HasConstraints(Entity) then return end

        -- Okay, check all of the constraints then
        for _, Constraint in pairs(Entity.Constraints) do
            local EntityClassName = Constraint:GetClass()
            CheckPreExistingConstraint(EntityClassName, Constraint, isConstraint[EntityClassName])
        end
    end)

    hook.Add("ACF_OnPostACFEntityAddedToContraption", "ACF_LegalityDetours_NewACFContraption_CheckConstraints", function(Contraption, _)
        if PreCheck() then return end
        if Contraption.ACF_EntitiesCount > 1 then return end -- constraint detours are already guarding us

        -- Lookup constraint classes, iterate on all constraints available.
        for EntityClassName, CheckAction in pairs(isConstraint) do
            local Constraints = Contraption.entsbyclass[EntityClassName]
            if Constraints then
                for Constraint in pairs(Constraints) do
                    CheckPreExistingConstraint(EntityClassName, Constraint, CheckAction)
                end
            end
        end
    end)

    do
        local Func Func = Detours.New("constraint.AdvBallsocket", function(Entity1, Entity2, Bone1, Bone2, LocalPos1, LocalPos2, ForceLimit, TorqueLimit, XMin, YMin, ZMin, XMax, YMax, ZMax, XFric, YFric, ZFric, OnlyRotation, NoCollide, ...)
            if not DetermineValidConstraint_WorldCheck(Entity1, Entity2, "adv ballsocket", true, NoCollide or false --[[important we dont pass nil here so it checks!]]) then return false end
            return Func(Entity1, Entity2, Bone1, Bone2, LocalPos1, LocalPos2, ForceLimit, TorqueLimit, XMin, YMin, ZMin, XMax, YMax, ZMax, XFric, YFric, ZFric, OnlyRotation, NoCollide, ...)
        end)
    end
    do
        local Func Func = Detours.New("constraint.Axis", function(Entity1, Entity2, ...)
            if not DetermineValidConstraint_WorldCheck(Entity1, Entity2, "axis", true) then return false end
            return Func(Entity1, Entity2, ...)
        end)
    end
    do
        local Func Func = Detours.New("constraint.Ballsocket", function(Entity1, Entity2, ...)
            if not DetermineValidConstraint_WorldCheck(Entity1, Entity2, "ballsocket", true) then return false end
            return Func(Entity1, Entity2, ...)
        end)
    end
    do
        local Func Func = Detours.New("constraint.Elastic", function(Entity1, Entity2, ...)
            if not DetermineValidConstraint_WorldCheck(Entity1, Entity2, "elastic", true) then return false, nil end
            return Func(Entity1, Entity2, ...)
        end)
    end
    do
        local Func Func = Detours.New("constraint.Hydraulic", function(Player, Entity1, Entity2, ...)
            if not DetermineValidConstraint_WorldCheck(Entity1, Entity2, "hydraulic", true) then return false, nil, nil, nil end
            return Func(Player, Entity1, Entity2, ...)
        end)
    end
    do
        local Func Func = Detours.New("constraint.Motor", function(Entity1, Entity2, ...)
            if not DetermineValidConstraint_WorldCheck(Entity1, Entity2, "motor", true) then return false, nil end
            return Func(Entity1, Entity2, ...)
        end)
    end
    do
        local Func Func = Detours.New("constraint.Muscle", function(Player, Entity1, Entity2, ...)
            if not DetermineValidConstraint_WorldCheck(Entity1, Entity2, "muscle", true) then return false, nil, nil, nil end
            return Func(Player, Entity1, Entity2, ...)
        end)
    end
    do
        local Func Func = Detours.New("constraint.NoCollide", function(Entity1, Entity2, ...)
            if not DetermineValidConstraint_WorldCheck(Entity1, Entity2, "no collide", true) then return false, nil end
            return Func(Entity1, Entity2, ...)
        end)
    end
    do
        local Func Func = Detours.New("constraint.Pulley", function(Entity1, Entity4, ...)
            if not DetermineValidConstraint_WorldCheck(Entity1, Entity4, "pulley", true) then return false, nil, nil, nil end
            return Func(Entity1, Entity4, ...)
        end)
    end
    do
        local Func Func = Detours.New("constraint.Rope", function(Entity1, Entity2, ...)
            if not DetermineValidConstraint_WorldCheck(Entity1, Entity2, "rope", true) then return false, nil end
            return Func(Entity1, Entity2, ...)
        end)
    end
    do
        local Func Func = Detours.New("constraint.Slider", function(Entity1, Entity2, ...)
            if not DetermineValidConstraint_WorldCheck(Entity1, Entity2, "slider", true) then return false, nil end
            return Func(Entity1, Entity2, ...)
        end)
    end
    do
        local Func Func = Detours.New("constraint.Weld", function(Entity1, Entity2, ...)
            if not DetermineValidConstraint_WorldCheck(Entity1, Entity2, "weld", true) then return false end
            return Func(Entity1, Entity2, ...)
        end)
    end
    do
        local Func Func = Detours.New("constraint.Winch", function(Player, Entity1, Entity2, ...)
            if not DetermineValidConstraint_WorldCheck(Entity1, Entity2, "winch", true) then return false, nil, nil end
            return Func(Player, Entity1, Entity2, ...)
        end)
    end

    -- Keep upright detours
    do
        local Func Func = Detours.New("constraint.Keepupright", function(Entity, ...)
            if not IsValid(Entity) then return false end
            local Contraption = Entity:CFW_GetContraption()

            if Contraption == nil then return Func(Entity, ...) end -- Don't care about non-contraptions
            if not Contraption:ACF_IsACFContraption() then return Func(Entity, ...) end -- Don't care about non-ACF contraptions

            -- Notify the player if they exist that this constraint can't be created
            local Player = Entity:CPPIGetOwner()
            if IsValid(Player) then
                Notify.EntityWarningToPlayer(Entity, Player, "Cannot create constraint 'keep upright'", "This constraint cannot exist on ACF contraptions")
            end

            return false
        end)
    end
end

local function TriggerDetourRebuild()
    Detours.Loaded = true

    SetPosDetours()
    SetAngDetours()

    FreezeDetours()
    UseDetours()

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
    WireForcerDetours()

    ConstraintDetours()
end

ACF.TriggerDetourRebuild = TriggerDetourRebuild
timer.Simple(Detours.Loaded and 0 or 5, TriggerDetourRebuild)