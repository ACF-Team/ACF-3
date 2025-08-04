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

Ponder.API.RegisterAddonCategory("acf", "mobility", {
    Name = "acf.storyboards.mobility",
    Order = 2,
    ModelIcon = "models/props_phx/wheels/trucktire.mdl",
    Description = "acf.storyboards.mobility.desc"
})

Ponder.API.RegisterAddonCategory("acf", "tankbasics", {
    Name = "Tank Basics",
    Order = 2,
    ModelIcon = "models/hunter/plates/plate025x025.mdl",
    Description = "Learn how to setup a basic tank."
})

ACF.PonderModelCaches = {
    -- Import tank skeleton
    -- (Baseplate: 2x5, Engine: V12L, Gearbox: Transaxial L, Main Gun: 125mmC, RWS Gun: 20mmMG)
    TankSkeleton = {
        {Name = "Base", IdentifyAs = "Base", Model = "models/hunter/plates/plate2x5.mdl", Angles = Angle(0, 0, 0), Position = Vector(0, 0, 0), ComeFrom = Vector(0, 0, 50), Scale = Vector(1, 1.25, 1), },

        -- Engine area
        {Name = "Engine", IdentifyAs = "Engine", Model = "models/engines/v12l.mdl", Angles = Angle(0, 90, 0), Position = Vector(0, -84, 3), ComeFrom = Vector(0, 0, 50), ParentTo = "Base", },
        {Name = "Gearbox", IdentifyAs = "Gearbox", Model = "models/engines/transaxial_s.mdl", Angles = Angle(0, 90, 0), Position = Vector(0, -144, 3), ComeFrom = Vector(0, 0, 50), ParentTo = "Base", Scale = Vector(2, 2, 2)},
        {Name = "FuelTank1", IdentifyAs = "Fuel Tank", Model = "models/holograms/hq_rcube.mdl", Angles = Angle(0, -90, 0), Position = Vector(36, -84, 15), ComeFrom = Vector(0, 0, 50), Scale = Vector(6, 2, 2), Material = "models/props_canal/metalcrate001d", ParentTo = "Base", },
        {Name = "FuelTank2", IdentifyAs = "Fuel Tank", Model = "models/holograms/hq_rcube.mdl", Angles = Angle(0, -90, 0), Position = Vector(-36, -84, 15), ComeFrom = Vector(0, 0, 50), Scale = Vector(6, 2, 2), Material = "models/props_canal/metalcrate001d", ParentTo = "Base", },

        -- Driver area
        {Name = "FuelTank3", IdentifyAs = "Fuel Tank", Model = "models/holograms/hq_rcube.mdl", Angles = Angle(0, -90, 0), Position = Vector(36, 120, 15), ComeFrom = Vector(0, 0, 50), Scale = Vector(4, 2, 2), Material = "models/props_canal/metalcrate001d", ParentTo = "Base", },
        {Name = "FuelTank4", IdentifyAs = "Fuel Tank", Model = "models/holograms/hq_rcube.mdl", Angles = Angle(0, -90, 0), Position = Vector(-36, 120, 15), ComeFrom = Vector(0, 0, 50), Scale = Vector(4, 2, 2), Material = "models/props_canal/metalcrate001d", ParentTo = "Base", },
        {Name = "Driver", IdentifyAs = "Driver", Model = "models/chairs_playerstart/sitpose.mdl", Angles = Angle(0, 0, 30), Position = Vector(0, 144, 3), ComeFrom = Vector(0, 0, 50), Material = "sprops/sprops_grid_12x12", ParentTo = "Base", },
        {Name = "AmmoCrate3", IdentifyAs = "Ammo Crate (125mmC AP)", Model = "models/holograms/hq_rcube.mdl", Angles = Angle(0, 90, 0), Position = Vector(24, 72, 15), ComeFrom = Vector(0, 0, 50), Scale = Vector(3, 3.5, 2), Material = "phoenix_storms/future_vents", ParentTo = "Base", },
        {Name = "AmmoCrate4", IdentifyAs = "Ammo Crate (125mmC HE)", Model = "models/holograms/hq_rcube.mdl", Angles = Angle(0, 90, 0), Position = Vector(-24, 72, 15), ComeFrom = Vector(0, 0, 50), Scale = Vector(3, 3.5, 2), Material = "phoenix_storms/future_vents", ParentTo = "Base", },

        -- Wheels
        {Name = "LWheel1", IdentifyAs = "Wheel", Model = "models/xeon133/offroad/off-road-40.mdl", Angles = Angle(0, 0, 0), Position = Vector(72, -144, 0), ComeFrom = Vector(0, 0, 50), ParentTo = "Base", },
        {Name = "LWheel2", IdentifyAs = "Wheel", Model = "models/xeon133/offroad/off-road-40.mdl", Angles = Angle(0, 0, 0), Position = Vector(72, -48, 0), ComeFrom = Vector(0, 0, 50), ParentTo = "Base", },
        {Name = "LWheel3", IdentifyAs = "Wheel", Model = "models/xeon133/offroad/off-road-40.mdl", Angles = Angle(0, 0, 0), Position = Vector(72, 48, 0), ComeFrom = Vector(0, 0, 50), ParentTo = "Base", },
        {Name = "LWheel4", IdentifyAs = "Wheel", Model = "models/xeon133/offroad/off-road-40.mdl", Angles = Angle(0, 0, 0), Position = Vector(72, 144, 0), ComeFrom = Vector(0, 0, 50), ParentTo = "Base", },
        {Name = "RWheel1", IdentifyAs = "Wheel", Model = "models/xeon133/offroad/off-road-40.mdl", Angles = Angle(0, 0, 0), Position = Vector(-72, -144, 0), ComeFrom = Vector(0, 0, 50), ParentTo = "Base", },
        {Name = "RWheel2", IdentifyAs = "Wheel", Model = "models/xeon133/offroad/off-road-40.mdl", Angles = Angle(0, 0, 0), Position = Vector(-72, -48, 0), ComeFrom = Vector(0, 0, 50), ParentTo = "Base", },
        {Name = "RWheel3", IdentifyAs = "Wheel", Model = "models/xeon133/offroad/off-road-40.mdl", Angles = Angle(0, 0, 0), Position = Vector(-72, 48, 0), ComeFrom = Vector(0, 0, 50), ParentTo = "Base", },
        {Name = "RWheel4", IdentifyAs = "Wheel", Model = "models/xeon133/offroad/off-road-40.mdl", Angles = Angle(0, 0, 0), Position = Vector(-72, 144, 0), ComeFrom = Vector(0, 0, 50), ParentTo = "Base", },

        -- Turret
        {Name = "TurretH", IdentifyAs = "Turret Ring", Model = "models/acf/core/t_ring.mdl", Angles = Angle(0, 0, 0), Position = Vector(0, 0, 36), ComeFrom = Vector(0, 0, 50), ParentTo = "Base", },
        {Name = "TurretV", IdentifyAs = "Turret Trun", Model = "models/acf/core/t_trun.mdl", Angles = Angle(0, 90, 0), Position = Vector(0, 48, 18), ComeFrom = Vector(0, 0, 50), ParentTo = "TurretH", },
        {Name = "AmmoCrate1", IdentifyAs = "Ammo Crate (125mmC AP)", Model = "models/holograms/hq_rcube.mdl", Angles = Angle(0, 90, 0), Position = Vector(24, -72, 24), ComeFrom = Vector(0, 0, 50), Scale = Vector(4, 4, 2), Material = "phoenix_storms/future_vents", ParentTo = "TurretH", },
        {Name = "AmmoCrate2", IdentifyAs = "Ammo Crate (125mmC HE)", Model = "models/holograms/hq_rcube.mdl", Angles = Angle(0, 90, 0), Position = Vector(-24, -72, 24), ComeFrom = Vector(0, 0, 50), Scale = Vector(4, 4, 2), Material = "phoenix_storms/future_vents", ParentTo = "TurretH", },

        -- Turret Electronics
        {Name = "BallComp", IdentifyAs = "Ballistic Computer", Model = "models/acf/core/t_computer.mdl", Angles = Angle(0, 0, 0), Position = Vector(-36, 36, 12), ComeFrom = Vector(0, 0, 50), ParentTo = "TurretH", },
        {Name = "Gyro", IdentifyAs = "Two Axis Gyro", Model = "models/acf/core/t_gyro.mdl", Angles = Angle(0, 0, 0), Position = Vector(-24, 42, 9), ComeFrom = Vector(0, 0, 50), ParentTo = "TurretH", },
        {Name = "MotorH", IdentifyAs = "Turret Ring Motor", Model = "models/acf/core/t_drive_e.mdl", Angles = Angle(0, 0, 0), Position = Vector(-36, -36, 15), ComeFrom = Vector(0, 0, 50), Scale = Vector(1.5, 1.5, 1.5), ParentTo = "TurretH", },
        {Name = "MotorV", IdentifyAs = "Turret Trun Motor", Model = "models/acf/core/t_drive_e.mdl", Angles = Angle(90, 0, 0), Position = Vector(36, 48, 18), ComeFrom = Vector(0, 0, 50), Scale = Vector(1.5, 1.5, 1.5), ParentTo = "TurretH", },

        -- Turret crew
        {Name = "Gun", IdentifyAs = "125mm Cannon", Model = "models/tankgun_new/tankgun_100mm.mdl", Angles = Angle(0, 0, 0), Position = Vector(0, 0, 0), ComeFrom = Vector(0, 0, 50), Scale = Vector(125 / 100, 125 / 100, 125 / 100), ParentTo = "TurretV", },
        {Name = "Gunner", IdentifyAs = "Gunner", Model = "models/chairs_playerstart/sitpose.mdl", Angles = Angle(0, 0, 0), Position = Vector(-24, 18, -33), ComeFrom = Vector(0, 0, 50), Material = "sprops/sprops_grid_12x12", ParentTo = "TurretH", },
        {Name = "Commander", IdentifyAs = "Gunner", Model = "models/chairs_playerstart/sitpose.mdl", Angles = Angle(0, 0, 0), Position = Vector(24, 18, -33), ComeFrom = Vector(0, 0, 50), Material = "sprops/sprops_grid_12x12", ParentTo = "TurretH", },
        {Name = "Loader", IdentifyAs = "Loader", Model = "models/chairs_playerstart/standingpose.mdl", Angles = Angle(0, 45, 0), Position = Vector(20, -20, -33), ComeFrom = Vector(0, 0, 50), Material = "sprops/sprops_grid_12x12", ParentTo = "TurretH", },
        {Name = "Loader2", IdentifyAs = "Loader (Extra)", Model = "models/chairs_playerstart/standingpose.mdl", Angles = Angle(0, -45, 0), Position = Vector(-20, -20, -33), ComeFrom = Vector(0, 0, 50), Material = "sprops/sprops_grid_12x12", ParentTo = "TurretH", },

        -- RWS
        {Name = "TurretH2", IdentifyAs = "Turret Ring (RWS)", Model = "models/holograms/cylinder.mdl", Angles = Angle(0, 0, 0), Position = Vector(30, 30, 36), ComeFrom = Vector(0, 0, 50), Scale = Vector(3 / 12, 3 / 12, 1), ParentTo = "TurretH", },
        {Name = "TurretV2", IdentifyAs = "Turret Trun (RWS)", Model = "models/acf/core/t_trun.mdl", Angles = Angle(0, 90, 0), Position = Vector(0, 0, 12), ComeFrom = Vector(0, 0, 50), Scale = Vector(0.15, 0.15, 0.15), ParentTo = "TurretH2", },
        {Name = "Gun2", IdentifyAs = "12.7mm Machineg Gun", Model = "models/machinegun/machinegun_20mm.mdl", Angles = Angle(0, 0, 0), Position = Vector(0, 0, 0), ComeFrom = Vector(0, 0, 0), Scale = Vector(12.7 / 20, 12.7 / 20, 12.7 / 20), ParentTo = "TurretV2", },
        {Name = "AmmoCrate5", IdentifyAs = "Ammo Crate (12.7mmMG)", Model = "models/holograms/hq_rcube.mdl", Angles = Angle(0, 90, 0), Position = Vector(0, 0, -12), ComeFrom = Vector(0, 0, 50), Scale = Vector(1, 1, 1), Material = "phoenix_storms/future_vents", ParentTo = "TurretH2", },
    }
}
