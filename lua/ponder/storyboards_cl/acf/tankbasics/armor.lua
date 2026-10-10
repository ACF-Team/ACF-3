local Storyboard = Ponder.API.NewStoryboard("acf", "tankbasics", "armor")
Storyboard:WithName("Armor")
Storyboard:WithBaseEntity(nil)
Storyboard:WithModelIcon("models/props_c17/streetsign004f.mdl")
Storyboard:WithDescription("Learn how to protect your tank")
Storyboard:WithIndexOrder(93)

--------------------------------------------------------------------------------------------------

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

Chapter:AddInstruction("DebugLine", {Name = "PenetratingRound", Start = Vector(200, 0, 0), End = Vector(-600, 0, -48), Color = Color(0, 255, 0), Lifetime = 2, IgnoreZ = true})

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Without armor in the way, the round punches straight through the crew compartment."}))

Chapter:AddDelay(2)

Chapter:AddInstruction("PlaySound", {Sound = "acf_base/weapons/cannon_new.mp3"})
Chapter:AddInstruction("SetSequence", {Name = "Gun2", Sequence = "shoot"})
Chapter:AddInstruction("DebugLine", {Name = "StoppedRound", Start = Vector(200, -100, 0), End = Vector(-180, -100, 0), Color = Color(0, 255, 0), Lifetime = 2, IgnoreZ = true})

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "The round's path stops short of punching all the way through the armor."}))

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

local Chapter = Storyboard:Chapter("Armor Mesh Tool")
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
Chapter:AddInstruction("ACF.InitializeCustomMenu", {Name = "ArmorMenuCPanel", BuildCPanel = function(Panel) return ACF.CreateArmorMeshMenu(Panel) end}):DelayByLength()

Chapter:AddInstruction("ShowToolgun", {Tool = language.GetPhrase("tool.acfarmormesh.name")}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Armor on ACF entities is made of convexes, the individual pieces of their volumetric mesh."}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "The ACF Armor Mesh tool highlights the convex under your crosshair, and shows its material, thickness and health."}))

Chapter:AddInstruction("ACF.SetPanelComboBox", {Name = "ArmorMenuCPanel", ComboBoxName = "ArmorMeshMaterials", OptionID = 12}):DelayByLength() -- RHA
Chapter:AddInstruction("AddHalo", {Target = "ArmorPlate2", Color = Color(255, 210, 90), Length = 0.3}):DelayByLength()

Chapter:AddInstruction("Caption", {
    Text = "Mat: RHA\nEff (mm): 10.00 (KE) 10.00 (CE)\nHP: 100 / 100",
    Horizontal = TEXT_ALIGN_RIGHT,
    Position = Vector(0, 0, 0),
    ParentTo = "ArmorPlate2",
    TextLength = 4,
    UseEntity = true,
})

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Pick a material from the menu, then left click a convex to apply it. Shift+left click applies it to the whole mesh."}))
Chapter:AddInstruction("ACF.SetPanelComboBox", {Name = "ArmorMenuCPanel", ComboBoxName = "ArmorMeshMaterials", OptionID = 9}):DelayByLength() -- Maraging Steel
Chapter:AddInstruction("ClickToolgun", {Tool = language.GetPhrase("tool.acfarmormesh.name"), Target = "ArmorPlate2"}):DelayByLength()
Chapter:AddInstruction("AddHalo", {Target = "ArmorPlate2", Color = Color(140, 180, 255), Length = 0.3}):DelayByLength()

Chapter:AddInstruction("Caption", {
    Text = "Mat: Maraging Steel\nEff (mm): 12.50 (KE) 11.50 (CE)\nHP: 13 / 13",
    Horizontal = TEXT_ALIGN_RIGHT,
    Position = Vector(0, 0, 0),
    ParentTo = "ArmorPlate2",
    TextLength = 4,
    UseEntity = true,
})

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Stronger materials aren't free: Maraging Steel resists penetration better than RHA, but has much less HP per convex."}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "You can only edit material or thickness, not both. Material editing is disabled while Thickness is above zero."}))
Chapter:AddInstruction("ACF.SetPanelSlider", {Name = "ArmorMenuCPanel", SliderName = "Thickness", Value = 100}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "With Thickness set, left click instead sets the thickness of the primitive shape you're aiming at, changing its shape."}))
Chapter:AddInstruction("ClickToolgun", {Tool = language.GetPhrase("tool.acfarmormesh.name"), Target = "ArmorPlate2"}):DelayByLength()
Chapter:AddInstruction("TransformModel", {Target = "ArmorPlate2", Scale = Vector(1, 1, 2.5), Length = 0.5}):DelayByLength()

Chapter:AddInstruction("Caption", {
    Text = "Mat: Maraging Steel\nEff (mm): 125.00 (KE) 115.00 (CE)\nHP: 130 / 130",
    Horizontal = TEXT_ALIGN_RIGHT,
    Position = Vector(0, 0, 0),
    ParentTo = "ArmorPlate2",
    TextLength = 4,
    UseEntity = true,
})

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Set Thickness back to 0 when you're done, to edit material again."}))
Chapter:AddInstruction("ACF.SetPanelSlider", {Name = "ArmorMenuCPanel", SliderName = "Thickness", Value = 0}):DelayByLength()

Chapter:AddDelay(1)
Chapter:AddInstruction("RemoveHalo", {Target = "ArmorPlate2", Length = 0.3}):DelayByLength()
Chapter:AddInstruction("RemovePanel", {Name = "ArmorMenuCPanel", Length = 1}):DelayByLength()
Chapter:AddInstruction("HideToolgun", {}):DelayByLength()
Chapter:AddInstruction("RemoveModel", {Name = "ArmorPlate2"})

local Chapter = Storyboard:Chapter("Spalling")
Chapter:AddInstruction("MoveCameraLookAt", {Length = 1, Angle = 45, Distance = 2000}):DelayByLength()

Chapter:AddInstruction("PlaceModel", {Name = "Gun3", IdentifyAs = "Cannon", Model = "models/tankgun_new/tankgun_100mm.mdl", Angles = Angle(0, 180, 0), Position = Vector(200, 100, 0), ComeFrom = Vector(0, 0, 0)})
Chapter:AddInstruction("PlaceModel", {Name = "ArmorPlate3", IdentifyAs = "Armor Plate", Model = "models/hunter/plates/plate1x2.mdl", Angles = Angle(0, 90, 90), Position = Vector(-180, 100, 0), ComeFrom = Vector(0, 50, 0)})
Chapter:AddInstruction("PlaceModel", {Name = "Crew3", IdentifyAs = "Crew", Model = "models/chairs_playerstart/standingpose.mdl", Angles = Angle(0, -90, 0), Position = Vector(-260, 100, -48), ComeFrom = Vector(0, 0, 0)})
Chapter:AddInstruction("MaterialModel", {Target = "Crew3", Material = "sprops/trans/lights/light_plastic"})

Chapter:AddDelay(2)
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Even when armor stops a round outright, the impact can still break fragments off its inside face."}))
Chapter:AddDelay(2)

Chapter:AddInstruction("PlaySound", {Sound = "acf_base/weapons/cannon_new.mp3"})
Chapter:AddInstruction("SetSequence", {Name = "Gun3", Sequence = "shoot"})
Chapter:AddInstruction("DebugLine", {Name = "StoppedRound2", Start = Vector(200, 100, 0), End = Vector(-180, 100, 0), Color = Color(0, 255, 0), Lifetime = 2, IgnoreZ = true})

Chapter:AddDelay(0.1)

Chapter:AddInstruction("DebugLine", {Name = "Spall1", Start = Vector(-180, 100, 0), End = Vector(-240, 140, -20), Color = Color(255, 140, 40), Lifetime = 2, IgnoreZ = true})
Chapter:AddInstruction("DebugLine", {Name = "Spall2", Start = Vector(-180, 100, 0), End = Vector(-220, 60, -10), Color = Color(255, 90, 20), Lifetime = 2, IgnoreZ = true})
Chapter:AddInstruction("DebugLine", {Name = "Spall3", Start = Vector(-180, 100, 0), End = Vector(-300, 110, -60), Color = Color(255, 180, 60), Lifetime = 2, IgnoreZ = true})
Chapter:AddInstruction("DebugLine", {Name = "Spall4", Start = Vector(-180, 100, 0), End = Vector(-210, 100, 30), Color = Color(255, 60, 10), Lifetime = 2, IgnoreZ = true})

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "This is spalling. These are real fragments with their own paths, and they can still injure crew behind stopped armor."}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "To see fragment paths in-game, set developer 1 and acf_developer 1."}))

Chapter:AddDelay(2)
Chapter:AddInstruction("RemoveModel", {Name = "Gun3"})
Chapter:AddInstruction("RemoveModel", {Name = "ArmorPlate3"})
Chapter:AddInstruction("RemoveModel", {Name = "Crew3"})
Chapter:AddDelay(1)