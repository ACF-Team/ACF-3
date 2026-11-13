-- Purpose: Hooks into some ACF hooks to provide accurate player damage results.

do
    local CostSnapshotLife = 10 -- seconds without damage before the cost is taken again

    -- Purpose: Track inflictor info when ACF damages an entity on the contraption of the entity.
    hook.Add("ACF_OnDamageEntity", "ACF_OnDamageEntity_TrackInflictorInfo", function(Entity, _, DmgInfo)
        local Contraption = Entity:CFW_GetContraption()
        if not Contraption then return end

        local Now = CurTime()

        -- Cost cached on the first damage event of each fight
        if not Contraption.ACF_LastCost or Now - (Contraption.ACF_LastDamageTime or 0) > CostSnapshotLife then
            Contraption.ACF_LastCost = (ACF.Contraption.CostSystem.CalcCostsFromContraption(Contraption))
        end

        Contraption.ACF_LastDamageTime = Now
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
        Split.ACF_LastCost = Previous.ACF_LastCost
    end)
end