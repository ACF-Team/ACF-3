-- Purpose: Hooks into some ACF hooks to provide accurate player damage results.

do
    -- Purpose: Track inflictor info when ACF damages an entity on the contraption of the entity.
    hook.Add("ACF_OnDamageEntity", "ACF_OnDamageEntity_TrackInflictorInfo", function(Entity, _, DmgInfo)
        local Contraption = Entity:CFW_GetContraption()
        if not Contraption then return end
        Contraption.ACF_LastDamageTime = CurTime()
        Contraption.ACF_LastDamageAttacker = DmgInfo:GetAttacker()
        Contraption.ACF_LastDamageInflictor = DmgInfo:GetInflictor()
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

    -- When contraptions merge, carry forward the most recent damage info
    hook.Add("cfw.contraption.merged", "ACF_KillTracking_TrackContraptionMerges", function(absorbed, into)
        if (absorbed.ACF_LastDamageTime or 0) > (into.ACF_LastDamageTime or 0) then
            into.ACF_LastDamageTime = absorbed.ACF_LastDamageTime
            into.ACF_LastDamageAttacker = absorbed.ACF_LastDamageAttacker
            into.ACF_LastDamageInflictor = absorbed.ACF_LastDamageInflictor
        end

        if (absorbed.ACF_LastNotifyDeathTime or 0) > (into.ACF_LastNotifyDeathTime or 0) then
            into.ACF_LastNotifyDeathTime = absorbed.ACF_LastNotifyDeathTime
        end
    end)
end