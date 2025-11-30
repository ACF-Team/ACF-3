local EntityCost = 0.1 -- Cost per entity in contraption

hook.Add("cfw.contraption.created", "ACF_CFW_CostTrack", function(Contraption)
    print("cfw.contraption.created", Contraption)
    Contraption.Cost = 0
end)

hook.Add("cfw.contraption.entityAdded", "ACF_CFW_CostTrack", function(Contraption, Entity)
    print("cfw.contraption.entityAdded", Contraption, Entity)
    Contraption.Cost = Contraption.Cost + EntityCost
end)

hook.Add("cfw.contraption.entityRemoved", "ACF_CFW_CostTrack", function(Contraption, Entity)
    print("cfw.contraption.entityRemoved", Contraption, Entity)
end)

hook.Add("cfw.contraption.merged", "ACF_CFW_CostTrack", function(Contraption, MergedInto)
    print("cfw.contraption.merged", Contraption, MergedInto)
end)

hook.Add("cfw.contraption.removed", "ACF_CFW_CostTrack", function(Contraption)
    print("cfw.contraption.removed", Contraption)
end)