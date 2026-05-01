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

-- Transfer piledriver data when contraptions merge
hook.Add("cfw.contraption.merged", "ACF_CFWPiledriverMerge", function(absorbed, into)
    if not absorbed.Piledrivers then return end

    into.Piledrivers = into.Piledrivers or {}

    for ent in pairs(absorbed.Piledrivers) do
        into.Piledrivers[ent] = true
    end
end)

-- Rebuild piledriver indexes when contraptions split
hook.Add("cfw.contraption.split", "ACF_CFWPiledriverSplit", function(parent, child)
    child.Piledrivers = {}

    for ent in pairs(child.ents) do
        if ent:GetClass() == "acf_piledriver" then
            child.Piledrivers[ent] = true
        end
    end

    parent.Piledrivers = {}

    for ent in pairs(parent.ents) do
        if ent:GetClass() == "acf_piledriver" then
            parent.Piledrivers[ent] = true
        end
    end
end)