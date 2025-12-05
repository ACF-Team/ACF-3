local Storyboard = Ponder.API.NewStoryboard("acf", "tankbasics", "armor")
Storyboard:WithName("Armor")
Storyboard:WithBaseEntity(nil)
Storyboard:WithModelIcon("models/props_c17/streetsign004f.mdl")
Storyboard:WithDescription("Learn how to protect your tank")
Storyboard:WithIndexOrder(93)

--------------------------------------------------------------------------------------------------

local Draw3D = Ponder.API.NewInstruction("Draw3D")
Draw3D.Length = 0

-------------------------------------------------------------------------------------------------

local Chapter = Storyboard:Chapter("Armor Intro")
Chapter:AddInstruction("MoveCameraLookAt", {Length = 0, Angle = 45, Distance = 2000}):DelayByLength()

-- Setup fail test
Chapter:AddInstruction("PlaceModel", {Name = "Gun1", IdentifyAs = "Cannon", Model = "models/tankgun_new/tankgun_100mm.mdl", Angles = Angle(0, 180, 0), Position = Vector(200, 0, 0), ComeFrom = Vector(0, 0, 0)})
Chapter:AddInstruction("PlaceModel", {Name = "Ammo1", IdentifyAs = "Ammo", Model = "models/holograms/hq_rcube.mdl", Angles = Angle(0, 180, 0), Position = Vector(200, 0, -24), Scale = Vector(2, 2, 2), ComeFrom = Vector(0, 0, 0)})
Chapter:AddInstruction("MaterialModel", {Target = "Ammo1", Material = "phoenix_storms/future_vents"})
Chapter:AddInstruction("PlaceModel", {Name = "Crew1", IdentifyAs = "Crew", Model = "models/chairs_playerstart/standingpose.mdl", Angles = Angle(0, -90, 0), Position = Vector(-200, 0, -48), ComeFrom = Vector(0, 0, 0)})
Chapter:AddInstruction("MaterialModel", {Target = "Crew1", Material = "sprops/trans/lights/light_plastic"})
Chapter:AddInstruction("PlaceModel", {Name = "Shell1", IdentifyAs = "Cannon", Model = "models/munitions/round_100mm.mdl", Angles = Angle(-90, 0, 0), Position = Vector(200, 0, 0), ComeFrom = Vector(0, 0, 0)})

-- Setup success test
Chapter:AddInstruction("PlaceModel", {Name = "Gun2", IdentifyAs = "Cannon", Model = "models/tankgun_new/tankgun_100mm.mdl", Angles = Angle(0, 180, 0), Position = Vector(200, -100, 0), ComeFrom = Vector(0, 0, 0)})
Chapter:AddInstruction("PlaceModel", {Name = "Ammo2", IdentifyAs = "Ammo", Model = "models/holograms/hq_rcube.mdl", Angles = Angle(0, 180, 0), Position = Vector(200, -100, -24), Scale = Vector(2, 2, 2), ComeFrom = Vector(0, 0, 0)})
Chapter:AddInstruction("MaterialModel", {Target = "Ammo2", Material = "phoenix_storms/future_vents"})
Chapter:AddInstruction("PlaceModel", {Name = "Crew2", IdentifyAs = "Crew", Model = "models/chairs_playerstart/standingpose.mdl", Angles = Angle(0, -90, 0), Position = Vector(-200, -100, -48), ComeFrom = Vector(0, 0, 0)})
Chapter:AddInstruction("MaterialModel", {Target = "Crew2", Material = "sprops/trans/lights/light_plastic"})
Chapter:AddInstruction("PlaceModel", {Name = "Shell2", IdentifyAs = "Cannon", Model = "models/munitions/round_100mm.mdl", Angles = Angle(-90, 0, 0), Position = Vector(200, -100, 0), ComeFrom = Vector(0, 0, 0)})
Chapter:AddInstruction("PlaceModel", {Name = "ArmorPlate1", IdentifyAs = "Armor Plate", Model = "models/hunter/plates/plate1x2.mdl", Angles = Angle(0, 90, 90), Position = Vector(-180, -100, 0), ComeFrom = Vector(0, 50, 0)})

-- 

Chapter:AddDelay(2)
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Armor can protect your vital components from damage."}))
Chapter:AddDelay(2)

Chapter:AddInstruction("PlaySound", {Sound = "acf_base/weapons/cannon_new.mp3"})
Chapter:AddInstruction("SetSequence", {Name = "Gun1", Sequence = "shoot"})
Chapter:AddInstruction("TransformModel", {Target = "Shell1", Position = Vector(-3800, 0, 0), Length = 1})

Chapter:AddDelay(0.1)
Chapter:AddInstruction("PlaySound", {Sound = "npc/zombie/zombie_voice_idle6.wav"})
Chapter:AddInstruction("MaterialModel", {Target = "Crew1", Material = "models/flesh"})

Chapter:AddDelay(2)

Chapter:AddInstruction("PlaySound", {Sound = "acf_base/weapons/cannon_new.mp3"})
Chapter:AddInstruction("SetSequence", {Name = "Gun2", Sequence = "shoot"})
Chapter:AddInstruction("TransformModel", {Target = "Shell2", Position = Vector(-200, -100, 0), Length = 0.1})
Chapter:AddDelay(0.1)
Chapter:AddInstruction("RemoveModel", {Name = "Shell2"})

-- Remove all models
Chapter:AddDelay(1)
Chapter:AddInstruction("RemoveModel", {Name = "Gun1"})
Chapter:AddInstruction("RemoveModel", {Name = "Ammo1"})
Chapter:AddInstruction("RemoveModel", {Name = "Crew1"})
Chapter:AddInstruction("RemoveModel", {Name = "Gun2"})
Chapter:AddInstruction("RemoveModel", {Name = "Ammo2"})
Chapter:AddInstruction("RemoveModel", {Name = "Crew2"})
Chapter:AddInstruction("RemoveModel", {Name = "ArmorPlate1"})
Chapter:AddDelay(1)

local Chapter = Storyboard:Chapter("Armor Tool Menu")
Chapter:AddInstruction("PlaceModel", {Name = "ArmorPlate2", IdentifyAs = "Armor Plate", Model = "models/hunter/blocks/cube1x1x1.mdl", Angles = Angle(0, 0, 90), Position = Vector(0, 0, 0), ComeFrom = Vector(0, 50, 0)})

Chapter:AddInstruction("PlacePanel", {
    Name = "ArmorMenuCPanel",
    Type = "DPanel",
    Calls = {
        {Method = "SetSize", Args = {300, 700}},
        {Method = "SetPos", Args = {1500, 0}},
        {Method = "CenterVertical", Args = {}},
    },
    Length = 0.25,
}):DelayByLength()
Chapter:AddInstruction("ACF.CreateMenuCPanel", {Name = "ArmorMenuCPanel", Label = "ACF Menu"}):DelayByLength()
Chapter:AddInstruction("ACF.InitializeCustomACFMenu", {Name = "ArmorMenuCPanel", CreateMenu = ACF.CreateArmorPropertiesMenuHeadless}):DelayByLength()

Chapter:AddInstruction("ShowToolgun", {Tool = language.GetPhrase("tool.acfarmorprop.name")}):DelayByLength()


Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Using the ACF armor properties tool, you can set the armor properties of an entity."}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Please see the help text for thickness and ductility shown in the menu."}))

Chapter:AddInstruction("ACF.SetPanelSlider", {Name = "ArmorMenuCPanel", SliderName = "#tool.acfarmorprop.thickness", Value = 100}):DelayByLength()
Chapter:AddInstruction("ACF.SetPanelSlider", {Name = "ArmorMenuCPanel", SliderName = "#tool.acfarmorprop.ductility", Value = 40}):DelayByLength()

Chapter:AddInstruction("Caption", {
    Text = "Armor: 10mm\nHP: 100\nMass: 1000kg",
    Horizontal = TEXT_ALIGN_RIGHT,
    Position = Vector(0, 0, 0),
    ParentTo = "Baseplate1",
    TextLength = 4,
    UseEntity = true,
})

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Now left click the armor plate to set its armor properties."}))
Chapter:AddInstruction("ClickToolgun", {Tool = language.GetPhrase("tool.acfarmorprop.name"), Target = "ArmorPlate2"}):DelayByLength()

Chapter:AddInstruction("Caption", {
    Text = "Armor: 100mm\nHP: 40\nMass: 1200kg",
    Horizontal = TEXT_ALIGN_RIGHT,
    Position = Vector(0, 0, 0),
    ParentTo = "Baseplate1",
    TextLength = 4,
    UseEntity = true,
})