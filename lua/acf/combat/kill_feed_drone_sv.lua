-- Announces a kill-feed entry when a crewless ("drone") contraption's baseplate is removed
-- after taking lethal ACF damage. Deliberately not routed through GM:SendDeathNotice: nobody
-- actually died, and that pipeline feeds achievements/stat trackers listening on AddDeathNotice.
local ACF = ACF

util.AddNetworkString("ACF_KillFeed_DroneEntry")

hook.Add("cfw.contraption.entityRemoved", "ACF_KillFeed_DroneRemoved", function(Contraption, Ent)
    if not IsValid(Ent) or Ent:GetClass() ~= "acf_baseplate" then return end
    if Contraption.Crews and next(Contraption.Crews) then return end -- Had crew; not a drone

    local Attacker = Contraption.ACF_LastDamageAttacker
    if not IsValid(Attacker) or not Attacker:IsPlayer() then return end -- Never took damage

    local Owner = Ent:CPPIGetOwner()
    if not IsValid(Owner) or not Owner:IsPlayer() then return end

    local CostSystem = ACF.Contraption.CostSystem
    local Inflictor = Contraption.ACF_LastDamageInflictor

    net.Start("ACF_KillFeed_DroneEntry")
        net.WriteEntity(Owner)
        net.WriteFloat(CostSystem.GetPlayerCost(Owner))
        net.WriteEntity(Attacker)
        net.WriteFloat(CostSystem.GetPlayerCost(Attacker))
        net.WriteString(IsValid(Inflictor) and Inflictor:GetClass() or "acf_baseplate")
    net.Broadcast()
end)
