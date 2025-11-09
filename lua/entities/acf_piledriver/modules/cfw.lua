hook.Add("cfw.contraption.entityAdded", "ACF_CFWPiledriverIndex", function(contraption, ent)
    if ent:GetClass() == "acf_piledriver" then
        contraption.Piledrivers = contraption.Piledrivers or {}
        contraption.Piledrivers[ent] = true
    end
end)

hook.Add("cfw.contraption.entityRemoved", "ACF_CFWPiledriverUnIndex", function(contraption, ent)
    if ent:GetClass() == "acf_piledriver" then
        contraption.Piledrivers = contraption.Piledrivers or {}
        contraption.Piledrivers[ent] = nil
    end
end)