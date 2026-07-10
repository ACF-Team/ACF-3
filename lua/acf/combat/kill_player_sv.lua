local ACF = ACF

util.AddNetworkString("ACF_KillFeed_ContraptionCost")

--- Broadcasts kill-feed point costs ahead of the actual kill.
--- @param Victim player The player who's about to die
--- @param Attacker entity The entity credited with the kill, if any
--- @return number VictimCost
--- @return number|nil AttackerCost
function ACF.AnnounceKillFeedCost(Victim, Attacker)
    if not IsValid(Victim) or not Victim:IsPlayer() then return end

    local CostSystem = ACF.Contraption.CostSystem
    local HasAttacker = IsValid(Attacker) and Attacker:IsPlayer()
    local VictimCost = CostSystem.GetPlayerCost(Victim)
    local AttackerCost = HasAttacker and CostSystem.GetPlayerCost(Attacker) or nil

    if ACF.EnableKillFeedCost then
        net.Start("ACF_KillFeed_ContraptionCost")
            net.WriteEntity(Victim)
            net.WriteFloat(VictimCost)
            net.WriteBool(HasAttacker)
            if HasAttacker then net.WriteFloat(AttackerCost) end
        net.Broadcast()
    end

    return VictimCost, AttackerCost
end

do
    local function DamageFn(Victim, Attacker, Inflictor)
        local DmgInfo = DamageInfo()
        DmgInfo:SetDamage(math.huge)
        DmgInfo:SetDamageType(DMG_GENERIC)
        if IsValid(Attacker) then DmgInfo:SetAttacker(Attacker) end
        if IsValid(Inflictor) then DmgInfo:SetInflictor(Inflictor) end
        Victim:TakeDamageInfo(DmgInfo)
    end

    function ACF.KillPlayer(Victim, Attacker, Inflictor)
        if not IsValid(Victim) then return end
        if not Victim:IsPlayer() then return end

        local VictimCost, AttackerCost = ACF.AnnounceKillFeedCost(Victim, Attacker)
        ACF.RecordKill(Attacker, AttackerCost, Victim, VictimCost, IsValid(Inflictor) and Inflictor:GetClass() or nil, false)

        -- The damage hook must be trapped to avoid a potential recursive loop
        -- (in theory, I never tested if it could happen, but better safe than sorry...)
        ACF.RunFunctionWhileBlockingBPSeatDamage(DamageFn, Victim, Attacker, Inflictor)

        -- Last chance... if DmgInfo didn't work, just ensure the player died.
        if Victim:Alive() then Victim:Kill() end
    end
end
