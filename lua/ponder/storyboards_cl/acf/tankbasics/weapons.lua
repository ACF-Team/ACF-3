local Storyboard = Ponder.API.NewStoryboard("acf", "tankbasics", "weapons")
Storyboard:WithName("Weapons")
Storyboard:WithBaseEntity(nil)
Storyboard:WithModelIcon("models/munitions/round_100mm.mdl")
Storyboard:WithDescription("Learn how to destroy other tanks")
Storyboard:WithIndexOrder(95)

-------------------------------------------------------------------------------------------------

local Chapter = Storyboard:Chapter("Setup")
Chapter:AddInstruction("MoveCameraLookAt", {Length = 1,  Angle = -45, Distance = 2000}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("PlaceModels", {
    Length = 0.5,
    Models = {
        {Name = "Base", IdentifyAs = "Base", Model = "models/hunter/plates/plate2x5.mdl", Angles = Angle(0, 0, 0), Position = Vector(0, 0, 0), ComeFrom = Vector(0, 0, 50), Scale = Vector(1, 1.25, 1), },
        {Name = "Engine", IdentifyAs = "Engine", Model = "models/engines/v12l.mdl", Angles = Angle(0, 90, 0), Position = Vector(0, -84, 3), ComeFrom = Vector(0, 0, 50), ParentTo = "Base", },
        {Name = "Gearbox", IdentifyAs = "Gearbox", Model = "models/engines/transaxial_s.mdl", Angles = Angle(0, 90, 0), Position = Vector(0, -144, 3), ComeFrom = Vector(0, 0, 50), ParentTo = "Base", Scale = Vector(2, 2, 2)},
        {Name = "FuelTank1", IdentifyAs = "Fuel Tank", Model = "models/holograms/hq_rcube.mdl", Angles = Angle(0, -90, 0), Position = Vector(36, -84, 15), ComeFrom = Vector(0, 0, 50), Scale = Vector(6, 2, 2), Material = "models/props_canal/metalcrate001d", ParentTo = "Base", },
        {Name = "FuelTank2", IdentifyAs = "Fuel Tank", Model = "models/holograms/hq_rcube.mdl", Angles = Angle(0, -90, 0), Position = Vector(-36, -84, 15), ComeFrom = Vector(0, 0, 50), Scale = Vector(6, 2, 2), Material = "models/props_canal/metalcrate001d", ParentTo = "Base", },
        {Name = "TurretH", IdentifyAs = "Turret Ring", Model = "models/acf/core/t_ring.mdl", Angles = Angle(0, 0, 0), Position = Vector(0, 0, 36), ComeFrom = Vector(0, 0, 50), ParentTo = "Base", },
        {Name = "TurretV", IdentifyAs = "Turret Trun", Model = "models/acf/core/t_trun.mdl", Angles = Angle(0, 90, 0), Position = Vector(0, 48, 18), ComeFrom = Vector(0, 0, 50), ParentTo = "TurretH", },
    }
}))

local Chapter = Storyboard:Chapter("Gun Intro")
Chapter:AddInstruction("ShowToolgun", {Tool = language.GetPhrase("tool.acf_menu.menu_name")}):DelayByLength()

Chapter:AddInstruction("PlacePanel", {
    Name = "MainMenuCPanel",
    Type = "DPanel",
    Calls = {
        {Method = "SetSize", Args = {300, 700}},
        {Method = "SetPos", Args = {1500, 0}},
        {Method = "CenterVertical", Args = {}},
    },
    Length = 0.25,
}):DelayByLength()

Chapter:AddInstruction("ACF.CreateMenuCPanel", {Name = "MainMenuCPanel", Label = "ACF Menu"}):DelayByLength()
Chapter:AddInstruction("ACF.InitializeMainMenu", {Name = "MainMenuCPanel"}):DelayByLength()
Chapter:AddInstruction("ACF.SelectMenuTreeNode", {Name = "MainMenuCPanel", Select = "#acf.menu.weapons"}):DelayByLength()
Chapter:AddInstruction("ACF.ScrollToMenuPanel", {Name = "MainMenuCPanel", Scroll = "#acf.menu.weapons.weapon_info"}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "The primary way to destroy other vehicles is through the use of weapons. Here we will look at guns."}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "For this example, use a 125mm Cannon."}))
Chapter:AddInstruction("ACF.SetPanelComboBox", {Name = "MainMenuCPanel", ComboBoxName = "WeaponClassList", OptionID = 3}):DelayByLength()
Chapter:AddInstruction("ACF.SetPanelComboBox", {Name = "MainMenuCPanel", ComboBoxName = "WeaponBreechIndex", OptionID = 1})
Chapter:AddInstruction("ACF.SetPanelSlider", {Name = "MainMenuCPanel", SliderName = "#acf.menu.caliber", Value = 125}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Spawn the gun and place it in the center of the vertical turret ring."}))
Chapter:AddInstruction("PlaceModel", {Name = "Gun", IdentifyAs = "125mm Cannon", Model = "models/tankgun_new/tankgun_100mm.mdl", Angles = Angle(0, 0, 0), Position = Vector(0, 0, 0), ComeFrom = Vector(0, 0, 50), Scale = Vector(125 / 100, 125 / 100, 125 / 100), ParentTo = "TurretV", }):DelayByLength()

local Chapter = Storyboard:Chapter("Alignment")
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Make sure the gun is centered and aligned with the turret rings."}))
Chapter:AddInstruction("MoveCameraLookAt", {Length = 1,  Angle = 0, Height = 0}):DelayByLength()
Chapter:AddDelay(1)
Chapter:AddInstruction("MoveCameraLookAt", {Length = 1,  Angle = 90, Height = 0}):DelayByLength()
Chapter:AddDelay(1)
Chapter:AddInstruction("MoveCameraLookAt", {Length = 1,  Angle = -45, Distance = 2000}):DelayByLength()

local Chapter = Storyboard:Chapter("Gun Parenting")

Chapter:AddInstruction("HideToolgun", {}):DelayByLength()
Chapter:AddInstruction("ShowToolgun", {Tool = language.GetPhrase("tool.multi_parent.listname")}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Parent the gun to the vertical ring."}))
Chapter:AddDelay(Chapter:AddInstruction("Tools.MultiParent", {Children = {"Gun"}, Parent = "TurretV", Easing = math.ease.InOutQuad, Length = 2}))
Chapter:AddInstruction("HideToolgun", {}):DelayByLength()
Chapter:AddInstruction("ShowToolgun", {Tool = language.GetPhrase("tool.acf_menu.menu_name")}):DelayByLength()

local Chapter = Storyboard:Chapter("Ammo Intro")
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Our cannon still needs ammunition to fire."}))
Chapter:AddInstruction("ACF.ScrollToMenuPanel", {Name = "MainMenuCPanel", Scroll = "#acf.menu.ammo.ammo_info"}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Select AP ammo for this example."}))
Chapter:AddInstruction("ACF.SetPanelComboBox", {Name = "MainMenuCPanel", ComboBoxName = "AmmoType", OptionID = 1}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Set the projectile vs propellant length to optimize for penetration."}))
Chapter:AddInstruction("ACF.SetPanelSlider", {Name = "MainMenuCPanel", SliderName = "#acf.menu.ammo.projectile_length", Value = 7.50}):DelayByLength()
Chapter:AddInstruction("ACF.SetPanelSlider", {Name = "MainMenuCPanel", SliderName = "#acf.menu.ammo.propellant_length", Value = 32.50}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Set the number of projectiles the crate stores in each dimension."}))
Chapter:AddInstruction("ACF.SetPanelSlider", {Name = "MainMenuCPanel", SliderName = "#acf.menu.ammo.projectiles_length", Value = 4}):DelayByLength()
Chapter:AddInstruction("ACF.SetPanelSlider", {Name = "MainMenuCPanel", SliderName = "#acf.menu.ammo.projectiles_width", Value = 1}):DelayByLength()
Chapter:AddInstruction("ACF.SetPanelSlider", {Name = "MainMenuCPanel", SliderName = "#acf.menu.ammo.projectiles_height", Value = 2}):DelayByLength()

local Chapter = Storyboard:Chapter("Ammo Placement")
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Shift + left click to spawn an ammo crate. Place two at the rear of the turret."}))
Chapter:AddDelay(Chapter:AddInstruction("PlaceModels", {
    Models = {
        {Name = "AmmoCrate1", IdentifyAs = "Ammo Crate (125mmC AP)", Model = "models/holograms/hq_rcube.mdl", Angles = Angle(0, 90, 0), Position = Vector(24, -72, 24), ComeFrom = Vector(0, 0, 50), Scale = Vector(4, 4, 2), Material = "phoenix_storms/future_vents", ParentTo = "TurretH", },
        {Name = "AmmoCrate2", IdentifyAs = "Ammo Crate (125mmC AP)", Model = "models/holograms/hq_rcube.mdl", Angles = Angle(0, 90, 0), Position = Vector(-24, -72, 24), ComeFrom = Vector(0, 0, 50), Scale = Vector(4, 4, 2), Material = "phoenix_storms/future_vents", ParentTo = "TurretH", },
    }
}))

local Chapter = Storyboard:Chapter("Ammo Parenting")

Chapter:AddInstruction("HideToolgun", {}):DelayByLength()
Chapter:AddInstruction("ShowToolgun", {Tool = language.GetPhrase("tool.multi_parent.listname")}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Parent the ammo crates to the horizontal turret ring."}))
Chapter:AddDelay(Chapter:AddInstruction("Tools.MultiParent", {Children = {"AmmoCrate1", "AmmoCrate2"}, Parent = "TurretH", Easing = math.ease.InOutQuad, Length = 2}))
Chapter:AddInstruction("HideToolgun", {}):DelayByLength()
Chapter:AddInstruction("ShowToolgun", {Tool = language.GetPhrase("tool.acf_menu.menu_name")}):DelayByLength()

local Chapter = Storyboard:Chapter("Ammo Linking")
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Using the ACF Menu tool, link both ammo crates to the gun."}))
Chapter:AddDelay(Chapter:AddInstruction("ACF Menu", {Children = {"AmmoCrate1", "AmmoCrate2"}, Target = "Gun", Easing = math.ease.InOutQuad, Length = 3}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Now the gun can draw ammo from either crate when firing."}))
Chapter:AddInstruction("HideToolgun", {}):DelayByLength()
Chapter:AddDelay(1)
Chapter:RecommendStoryboard("acf.tankbasics.crew_basics")