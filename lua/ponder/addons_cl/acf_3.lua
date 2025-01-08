Ponder.API.RegisterAddon("acf", {
    Name = "acf.storyboards.addon",
    ModelIcon = "models/engines/inline5s.mdl",
    Description = "acf.storyboards.addon.desc"
})

-- NOTE TO CRAFT/anyone wondering why we define these here:
--     Ponder can load categories at this point; the categories_cl folder is meant to just make it more extendable (say, ACF missiles adds its own things)

Ponder.API.RegisterAddonCategory("acf", "weapons", {
    Name = "acf.storyboards.weapons",
    Order = 2,
    ModelIcon = "models/munitions/round_100mm_shot.mdl",
    Description = "acf.storyboards.weapons.desc"
})

Ponder.API.RegisterAddonCategory("acf", "turrets", {
    Name = "acf.storyboards.turrets",
    Order = 2,
    ModelIcon = "models/acf/core/t_ring.mdl",
    Description = "acf.storyboards.turrets.desc"
})