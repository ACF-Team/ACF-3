timer.Simple(0, function()
    if not Ponder then return end

    Ponder.API.RegisterAddon(language.GetPhrase("acf.storyboards.addon"), "models/engines/inline5s.mdl", language.GetPhrase("acf.storyboards.addon.desc"))
    Ponder.API.RegisterAddonCategory(language.GetPhrase("acf.storyboards.addon"), language.GetPhrase("acf.storyboards.weapons"), 1, "models/munitions/round_100mm_shot.mdl", language.GetPhrase("acf.storyboards.weapons.desc"))
    Ponder.API.RegisterAddonCategory(language.GetPhrase("acf.storyboards.addon"), language.GetPhrase("acf.storyboards.turrets"), 2, "models/acf/core/t_ring.mdl", language.GetPhrase("acf.storyboards.turrets.desc"))
end)