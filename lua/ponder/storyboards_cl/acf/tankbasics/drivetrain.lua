local Storyboard = Ponder.API.NewStoryboard("acf", "tankbasics", "drivetrain")
Storyboard:WithName("Drivetrains")
Storyboard:WithBaseEntity(nil)
Storyboard:WithModelIcon("models/engines/v12l.mdl")
Storyboard:WithDescription("Learn how to make your tank move.")
Storyboard:WithIndexOrder(99)

-------------------------------------------------------------------------------------------------
local Chapter = Storyboard:Chapter("Setup")
Chapter:AddInstruction("MoveCameraLookAt", {Length = 1,  Angle = -45, Distance = 2000}):DelayByLength()

Chapter:AddInstruction("PlaceModel", {
    Name = "Baseplate1",
    IdentifyAs = "acf_baseplate",
    Model = "models/hunter/plates/plate2x5.mdl",
    Position = Vector(0, 0, 0),
    Angles = Angle(0, 0, 0),
    Scale = Vector(1, 1.25, 1),
    ComeFrom = Vector(0, 0, 50)
}):DelayByLength()

Chapter:AddInstruction("PlaceModel", {Name = "AIO", IdentifyAs = "AIO Controller", Model = "models/hunter/plates/plate025x025.mdl", Position = Vector(-30, 100, 3), ComeFrom = Vector(0, 0, 50), ParentTo = "Baseplate1"}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Now that you have a baseplate and a controller, let's give it a drivetrain."}))

Chapter:AddDelay(1)
local Chapter = Storyboard:Chapter("Engines Intro")
Chapter:AddDelay(1)
Chapter:AddInstruction("Caption", {Text = "Select engines from the menu, then click on the drop downs to select the engine class and model you want."})

Chapter:AddInstruction("PlacePanel", {
    Name = "MainMenuCPanel",
    Type = "DPanel",
    Calls = {
        {Method = "SetSize", Args = {300, 600}},
        {Method = "SetPos", Args = {1500, 0}},
        {Method = "CenterVertical", Args = {}},
    },
    Length = 0.25,
}):DelayByLength()

Chapter:AddInstruction("ACF.CreateMenuCPanel", {Name = "MainMenuCPanel", Label = "ACF Menu"}):DelayByLength()
Chapter:AddInstruction("ACF.InitializeMainMenu", {Name = "MainMenuCPanel"}):DelayByLength()
Chapter:AddInstruction("ACF.SelectMenuTreeNode", {Name = "MainMenuCPanel", Select = "#acf.menu.engines"}):DelayByLength()
Chapter:AddInstruction("ACF.ScrollToMenuPanel", {Name = "MainMenuCPanel", Scroll = "#acf.menu.engines.engine_info"}):DelayByLength()

Chapter:AddDelay(1)
Chapter:AddInstruction("ACF.SetPanelComboBox", {Name = "MainMenuCPanel", Choice = "V12 Engine"}):DelayByLength()
Chapter:AddDelay(1)
Chapter:AddInstruction("ACF.SetPanelComboBox", {Name = "MainMenuCPanel", Choice = "21.0L V12 Diesel"}):DelayByLength()
Chapter:AddDelay(1)

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Press Mouse1 (Left Click) to spawn an engine."}))

Chapter:AddInstruction("PlaceModel", {
    Name = "Engine1",
    Model = "models/engines/v12l.mdl",
    Position = Vector(96, 0, 0),
    Angles = Angle(0, 0, 0),
}):DelayByLength()

Chapter:AddDelay(1)

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Engines provide power to move your tank."}))

local Chapter = Storyboard:Chapter("Engines Placement")
Chapter:AddInstruction("Caption", {
    Text = "Driveshaft",
    Horizontal = TEXT_ALIGN_CENTER,
    Position = Vector(-35, 0, 9),
    ParentTo = "Engine1",
    UseEntity = true,
    TextLength = 3,
})

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Move them onto your baseplate with the driveshaft pointing towards the back."}))

Chapter:AddInstruction("TransformModel", {
    Target = "Engine1",
    Position = Vector(0, -84, 3),
    Rotation = Angle(0, 90, 0),
    Length = 1,
}):DelayByLength()

Chapter:AddDelay(1)

Chapter:AddInstruction("MoveCameraLookAt", {Length = 0.5,  Angle = -135, Distance = 2000}):DelayByLength()
Chapter:AddInstruction("MoveCameraLookAt", {Length = 0.5,  Angle = -225, Distance = 2000}):DelayByLength()

Chapter:AddDelay(1)
local Chapter = Storyboard:Chapter("Fuel Intro")
Chapter:AddDelay(1)

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Engines require a fuel tank to function."}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Scroll to the Fuel Tank section and set a size (E.g. 72x24x24)"}))

Chapter:AddInstruction("ACF.ScrollToMenuPanel", {Name = "MainMenuCPanel", Scroll = "#acf.menu.fuel.tank_info"}):DelayByLength()

Chapter:AddDelay(1)

Chapter:AddInstruction("ACF.SetPanelSlider", {Name = "MainMenuCPanel", SliderName = "#acf.menu.fuel.tank_length", Value = 72}):DelayByLength()
Chapter:AddInstruction("ACF.SetPanelSlider", {Name = "MainMenuCPanel", SliderName = "#acf.menu.fuel.tank_width", Value = 24}):DelayByLength()
Chapter:AddInstruction("ACF.SetPanelSlider", {Name = "MainMenuCPanel", SliderName = "#acf.menu.fuel.tank_height", Value = 24}):DelayByLength()

Chapter:AddDelay(1)

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Press SHIFT + Mouse1 (Left Click) to spawn a fuel tank."}))

Chapter:AddInstruction("PlaceModel", {
    Name = "FuelTank1",
    Model = "models/acf/core/s_fuel.mdl",
    Position = Vector(96, 0, 0),
    Scale = Vector(6, 2, 2),
    Angles = Angle(0, 0, 0),
}):DelayByLength()

Chapter:AddInstruction("PlaceModel", {
    Name = "FuelTank2",
    Model = "models/acf/core/s_fuel.mdl",
    Position = Vector(96, 48, 0),
    Scale = Vector(6, 2, 2),
    Angles = Angle(0, 0, 0),
}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Fuel tanks store fuel based on their volume."}))

local Chapter = Storyboard:Chapter("Fuel Placement")
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Move them onto your baseplate like so."}))

Chapter:AddInstruction("TransformModel", {
    Target = "FuelTank1",
    Position = Vector(36, -84, 15),
    Rotation = Angle(0, 90, 0),
    Length = 1,
}):DelayByLength()

Chapter:AddInstruction("TransformModel", {
    Target = "FuelTank2",
    Position = Vector(-36, -84, 15),
    Rotation = Angle(0, 90, 0),
    Length = 1,
}):DelayByLength()

Chapter:AddDelay(1)
local Chapter = Storyboard:Chapter("Gearbox Intro")
Chapter:AddDelay(1)

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Next, select Gearboxes from the menu."}))

Chapter:AddInstruction("ACF.SelectMenuTreeNode", {Name = "MainMenuCPanel", Select = "#acf.menu.gearboxes"}):DelayByLength()

Chapter:AddInstruction("ACF.ScrollToMenuPanel", {Name = "MainMenuCPanel", Scroll = "#acf.menu.gearboxes.gearbox_info"}):DelayByLength()

Chapter:AddInstruction("Caption", {
    Text = "Please use the settings shown.",
    Horizontal = TEXT_ALIGN_CENTER,
    Position = Vector(0.5, 0.15, 0),
})

Chapter:AddDelay(1)
Chapter:AddInstruction("ACF.SetPanelComboBox", {Name = "MainMenuCPanel", Choice = "CVT"}):DelayByLength()
Chapter:AddDelay(1)
Chapter:AddInstruction("ACF.SetPanelComboBox", {Name = "MainMenuCPanel", Choice = "CVT, Transaxial"}):DelayByLength()
Chapter:AddDelay(1)

Chapter:AddInstruction("ACF.ScrollToMenuPanel", {Name = "MainMenuCPanel", Scroll = "#acf.menu.gearboxes.scale"}):DelayByLength()

Chapter:AddDelay(1)
Chapter:AddDelay(Chapter:AddInstruction("Caption", {
    Text = "Larger gearboxes can handle stronger engines.",
    Horizontal = TEXT_ALIGN_CENTER,
    Position = Vector(0.5, 0.15, 0),
}))
Chapter:AddInstruction("ACF.SetPanelSlider", {Name = "MainMenuCPanel", SliderName = "#acf.menu.gearboxes.scale", Value = 2}):DelayByLength()

Chapter:AddDelay(1)
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Dual clutches allow you to brake either side independently."}))
Chapter:AddInstruction("ACF.SetPanelCheckBox", {Name = "MainMenuCPanel", CheckBoxName = "#acf.menu.gearboxes.dual_clutch", Value = true}):DelayByLength()

Chapter:AddDelay(1)
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Gearing roughly determines your preference for speed (towards 1) or torque (towards 10)."}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Gear 2 is a gear used to reverse the tank. Usually torque is preferred."}))
Chapter:AddInstruction("ACF.SetPanelSlider", {Name = "MainMenuCPanel", SliderName = string.format(language.GetPhrase("#acf.menu.gearboxes.gear_number"), 2), Value = 2}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Final Drive is a multiplier applied to all gears 'at the end' of the gearbox."}))
Chapter:AddInstruction("ACF.SetPanelSlider", {Name = "MainMenuCPanel", SliderName = "#acf.menu.gearboxes.final_drive", Value = 1}):DelayByLength()

Chapter:AddDelay(1)
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Minimum and Maximum Target RPMs come from our engine specs."}))
Chapter:AddInstruction("ACF.SetPanelSlider", {Name = "MainMenuCPanel", SliderName = "#acf.menu.gearboxes.min_target_rpm", Value = 1250}):DelayByLength()
Chapter:AddInstruction("ACF.SetPanelSlider", {Name = "MainMenuCPanel", SliderName = "#acf.menu.gearboxes.max_target_rpm", Value = 1880}):DelayByLength()

Chapter:AddDelay(1)
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Press Mouse1 (Left Click) to spawn a gearbox."}))

Chapter:AddInstruction("PlaceModel", {
    Name = "Gearbox1",
    Model = "models/engines/transaxial_s.mdl",
    Position = Vector(96, 0, 0),
    Angles = Angle(0, 0, 0),
    Scale = Vector(2, 2, 2),
}):DelayByLength()

local Chapter = Storyboard:Chapter("Gearbox Placement")
Chapter:AddInstruction("Caption", {
    Text = "Input Shaft",
    Horizontal = TEXT_ALIGN_CENTER,
    Position = Vector(12, 0, 9),
    ParentTo = "Gearbox1",
    UseEntity = true,
    TextLength = 3,
})

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Move it onto your baseplate like so, with the input shaft pointing towards the engine."}))

Chapter:AddInstruction("TransformModel", {
    Target = "Gearbox1",
    Position = Vector(0, -144, 3),
    Rotation = Angle(0, 90, 0),
    Length = 1,
}):DelayByLength()

Chapter:AddDelay(1)
Chapter:AddInstruction("RemovePanel", {Name = "MainMenuCPanel", Length = 1}):DelayByLength()

-------------------------------------------------------------------------------------------------
local Chapter = Storyboard:Chapter("Parenting")
Chapter:AddInstruction("ShowToolgun", {Tool = language.GetPhrase("tool.multi_parent.listname")}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "With the Multi Parent tool, parent the engine, fuel tanks and gearbox to the baseplate."}))
Chapter:AddDelay(Chapter:AddInstruction("Tools.MultiParent", {Children = {"Engine1", "FuelTank1", "FuelTank2", "Gearbox1"}, Parent = "Baseplate1", Easing = math.ease.InOutQuad, Length = 4}))
Chapter:AddInstruction("HideToolgun", {}):DelayByLength()

local Chapter = Storyboard:Chapter("Linking")
Chapter:AddInstruction("ShowToolgun", {Tool = language.GetPhrase("tool.acf_menu.menu_name")}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "With the ACF Menu tool, right click the engine, then right click the gearbox, to link them."}))
Chapter:AddDelay(Chapter:AddInstruction("ACF Menu", {Children = {"Engine1"}, Target = "Gearbox1", Easing = math.ease.InOutQuad, Length = 2}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Now the gearbox can receive power from the engine."}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Hold Shift and right click each fuel tank, then right click the engine, to link them all."}))
Chapter:AddDelay(Chapter:AddInstruction("ACF Menu", {Children = {"FuelTank1", "FuelTank2"}, Target = "Engine1", Easing = math.ease.InOutQuad, Length = 3}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Now the engine can receive fuel from the fuel tanks."}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "If you look at the engine, you can see a visualization of all linked entities in your drivetrain."}))
Chapter:AddInstruction("HideToolgun", {}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Next, add wheels so the gearbox has something to drive."}))
Chapter:RecommendStoryboard("acf.tankbasics.suspension")