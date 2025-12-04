-- Purpose: Hooks into some ACF hooks to provide accurate player damage results.
local ACF = ACF
do
    local BlockDamageHook = false

    -- Purpose: Make players invincible while in ACF baseplate seats.
    -- We don't want other damage systems to interact with ACF combat.
    -- Deaths instead will happen when the crew dies.
    hook.Add("EntityTakeDamage", "ACF_EntityTakeDamage_BlockDamageInBaseplateSeats", function(Target, _)
        if BlockDamageHook then return end -- To avoid crashes/allow ACF to stop damage for a bit
        if ACF.AllowBaseplateDamage then return end

        if not Target:IsPlayer() then return end
        if not Target:InVehicle() then return end

        local Vehicle = Target:GetVehicle()
        if not IsValid(Vehicle) then return end

        local Contraption = Vehicle:GetContraption()
        if not Contraption then return end

        local Base = Contraption.ACF_Baseplate
        if IsValid(Base) then
            return true -- Block damage, because there's a contraption, with a baseplate
        end
    end)

    function ACF.KillPlayer(Victim, Attacker, Inflictor)
        if not IsValid(Victim) then return end
        if not Victim:IsPlayer() then return end

        -- The damage hook must be trapped to avoid a potential recursive loop
        -- (in theory, I never tested if it could happen, but better safe than sorry...)
        BlockDamageHook = true do
            local DmgInfo = DamageInfo()
            DmgInfo:SetDamage(Victim:Health())
            DmgInfo:SetDamageType(DMG_GENERIC)
            if IsValid(Attacker) then DmgInfo:SetAttacker(Attacker) end
            if IsValid(Inflictor) then DmgInfo:SetInflictor(Inflictor) end
            Victim:TakeDamageInfo(DmgInfo)
        end BlockDamageHook = false

        -- Last chance... if DmgInfo didn't work, just ensure the player died.
        if Victim:Alive() then Victim:Kill() end
    end
    -- ACF.KillPlayer(Player(2), Player(3))
end

do
    -- Purpose: Track inflictor info when ACF damages an entity on the contraption of the entity.
    hook.Add("ACF_OnDamageEntity", "ACF_OnDamageEntity_TrackInflictorInfo", function(Entity, _, DmgInfo)
        local Contraption = Entity:GetContraption()
        if not Contraption then return end
        Contraption.ACF_LastDamageTime = CurTime()
        Contraption.ACF_LastDamageAttacker = DmgInfo:GetAttacker()
        Contraption.ACF_LastDamageInflictor = DmgInfo:GetInflictor()
    end)

    -- Purpose: Block crewed contraptions that have had their crew killed from being able to be entered again.
    hook.Add("CanPlayerEnterVehicle", "ACF_CanPlayerEnterVehicle_BlockEnterVehicleOnDeadContraption", function(Player, Vehicle)
        local Contraption = Vehicle:GetContraption()
        if not Contraption then return end
        local Now = CurTime()
        if Contraption.ACF_AllCrewKilled then
            if (Now - (Contraption.ACF_LastNotifyDeathTime or 0)) > 1 then
                ACF.SendNotify(Player, false, "This contraption is no longer usable.")
                Contraption.ACF_LastNotifyDeathTime = Now
            end
            return false
        end
    end)

    -- Purpose: When CFW contraption splits happen, the ACF last damage information gets lost.
    -- So if something blows up in the right way, it could trigger a contraption split before actually
    -- killing the player, I believe. This should hopefully fix the remaining issues with this system
    hook.Add("cfw.contraption.split", "ACF_KillTracking_TrackContraptionSplits", function(Previous, Split)
        Split.ACF_LastNotifyDeathTime = Previous.ACF_LastNotifyDeathTime
        Split.ACF_LastDamageTime = Previous.ACF_LastDamageTime
        Split.ACF_LastDamageAttacker = Previous.ACF_LastDamageAttacker
        Split.ACF_LastDamageInflictor = Previous.ACF_LastDamageInflictor
    end)
end