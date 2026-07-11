-- Announces a kill-feed entry when a contraption's baseplate dies, separately from any player
-- deaths it caused. Not routed through GM:SendDeathNotice since no player actually died.
local ACF = ACF

util.AddNetworkString("ACF_KillFeed_VehicleEntry")

hook.Add("cfw.contraption.entityRemoved", "ACF_KillFeed_VehicleRemoved", function(Contraption, Ent)
    if not IsValid(Ent) or Ent:GetClass() ~= "acf_baseplate" then return end

    local Attacker = Contraption.ACF_LastDamageAttacker
    if not IsValid(Attacker) or not Attacker:IsPlayer() then return end -- Never took damage

    local Owner = Ent:CPPIGetOwner()
    if not IsValid(Owner) or not Owner:IsPlayer() then return end

    if not ACF.EnableKillFeedCost then return end

    -- As a contraption is deconstructed, a baseplate can be removed multiple times. Only allow this once.
    if Ent.ACF_VehicleKillAnnounced then return end
    Ent.ACF_VehicleKillAnnounced = true

    local CostSystem = ACF.Contraption.CostSystem
    local Inflictor = Contraption.ACF_LastDamageInflictor
    local OwnerCost = Contraption.ACF_LastCost or (CostSystem.CalcCostsFromContraption(Contraption))
    local AttackerCost = CostSystem.GetAttackerCost(Attacker)
    local InflictorClass = IsValid(Inflictor) and Inflictor:GetClass() or "acf_baseplate"

    net.Start("ACF_KillFeed_VehicleEntry")
        net.WriteEntity(Owner)
        net.WriteFloat(OwnerCost)
        net.WriteEntity(Attacker)
        net.WriteFloat(AttackerCost)
        net.WriteString(InflictorClass)
    net.Broadcast()
end)
