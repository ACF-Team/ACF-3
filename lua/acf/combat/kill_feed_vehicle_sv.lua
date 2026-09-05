-- Announces a kill-feed entry when a baseplate dies without taking a seated player with it.
-- Not routed through GM:SendDeathNotice since no player actually died.
local ACF = ACF

util.AddNetworkString("ACF_KillFeed_VehicleEntry")

hook.Add("cfw.contraption.entityRemoved", "ACF_KillFeed_VehicleRemoved", function(Contraption, Ent)
    if not IsValid(Ent) or Ent:GetClass() ~= "acf_baseplate" then return end

    local Attacker = Contraption.ACF_LastDamageAttacker
    if not IsValid(Attacker) or not Attacker:IsPlayer() then return end -- Never took damage

    local Owner = Ent:CPPIGetOwner()
    if not IsValid(Owner) or not Owner:IsPlayer() then return end

    -- Zero means a seated player's death or an earlier removal already billed this contraption
    local CostSystem = ACF.Contraption.CostSystem
    local OwnerCost = CostSystem.ClaimContraptionCost(Contraption, Ent)
    if OwnerCost == 0 then return end

    local Inflictor = Contraption.ACF_LastDamageInflictor
    local AttackerCost = CostSystem.GetAttackerCost(Attacker)
    local InflictorClass = IsValid(Inflictor) and Inflictor:GetClass() or "acf_baseplate"

    -- No player died here, only the vehicle; log it as a drone/crewless destruction
    ACF.RecordKill(Attacker, AttackerCost, Owner, OwnerCost, InflictorClass, true)

    if not ACF.EnableKillFeedCost then return end -- Logging is independent of the HUD feed

    net.Start("ACF_KillFeed_VehicleEntry")
        net.WriteEntity(Owner)
        net.WriteFloat(OwnerCost)
        net.WriteEntity(Attacker)
        net.WriteFloat(AttackerCost)
        net.WriteString(InflictorClass)
    net.Broadcast()
end)
