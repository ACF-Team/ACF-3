local Storyboard = Ponder.API.NewStoryboard("acf", "tankbasics", "parenting_linking")
Storyboard:WithName("Parenting & Linking")
Storyboard:WithBaseEntity(nil)
Storyboard:WithModelIcon("models/weapons/w_toolgun.mdl")
Storyboard:WithDescription("Introducing parenting and linking")
Storyboard:WithIndexOrder(98)

-------------------------------------------------------------------------------------------------
local Chapter = Storyboard:Chapter("Setup")
Chapter:AddInstruction("MoveCameraLookAt", {Length = 1,  Angle = -225, Distance = 2000}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("PlaceModels", {
    Length = 0.5,
    Models = {
        {Name = "Base", IdentifyAs = "Base", Model = "models/hunter/plates/plate2x5.mdl", Angles = Angle(0, 0, 0), Position = Vector(0, 0, 0), ComeFrom = Vector(0, 0, 50), Scale = Vector(1, 1.25, 1), },
        {Name = "Engine", IdentifyAs = "Engine", Model = "models/engines/v12l.mdl", Angles = Angle(0, 90, 0), Position = Vector(0, -84, 3), ComeFrom = Vector(0, 0, 50), ParentTo = "Base", },
        {Name = "Gearbox", IdentifyAs = "Gearbox", Model = "models/engines/transaxial_s.mdl", Angles = Angle(0, 90, 0), Position = Vector(0, -144, 3), ComeFrom = Vector(0, 0, 50), ParentTo = "Base", Scale = Vector(2, 2, 2)},
        {Name = "FuelTank1", IdentifyAs = "Fuel Tank", Model = "models/holograms/hq_rcube.mdl", Angles = Angle(0, -90, 0), Position = Vector(36, -84, 15), ComeFrom = Vector(0, 0, 50), Scale = Vector(6, 2, 2), Material = "models/props_canal/metalcrate001d", ParentTo = "Base", },
        {Name = "FuelTank2", IdentifyAs = "Fuel Tank", Model = "models/holograms/hq_rcube.mdl", Angles = Angle(0, -90, 0), Position = Vector(-36, -84, 15), ComeFrom = Vector(0, 0, 50), Scale = Vector(6, 2, 2), Material = "models/props_canal/metalcrate001d", ParentTo = "Base", },
    }
}))


local Chapter = Storyboard:Chapter("Parenting & Linking")
Chapter:AddInstruction("ShowToolgun", {Tool = language.GetPhrase("tool.multi_parent.listname")}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "The Multi Parent tool can parent two entities together."}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Parented entities will move and rotate together."}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Parenting is considerably more optimized than constraints like welds, so use it whenever possible."}))

local Chapter = Storyboard:Chapter("Parenting Menu")

function ParentCPanel( panel )
    panel:AddControl( "Slider", {Label = "Auto Select Radius:", Type = "integer", Min = "64", Max = "1024", Command = ""} )
    panel:AddControl( "Checkbox", {Label = "#tool.multi_parent.removeconstraints", Command = "", Help = true} )
    panel:AddControl( "Checkbox", {Label = "#tool.multi_parent.nocollide", Command = "", Help = true } )
    panel:AddControl( "Checkbox", {Label = "#tool.multi_parent.weld", Command = "", Help = true} )
    panel:AddControl( "Checkbox", {Label = "#tool.multi_parent.disablecollisions", Command = "", Help = true} )
    panel:AddControl( "Checkbox", {Label = "#tool.multi_parent.weight", Command = "", Help = true} )
    panel:AddControl( "Checkbox", {Label = "#tool.multi_parent.disableshadow", Command = "", Help = true} )
end

-- Create parenting menu
Chapter:AddInstruction("PlacePanel", {
    Name = "MultiParentMenuCPanel",
    Type = "DPanel",
    Calls = {
        {Method = "SetSize", Args = {300, 450}},
        {Method = "SetPos", Args = {1500, 0}},
        {Method = "CenterVertical", Args = {}},
    },
    Length = 0.25,
}):DelayByLength()
Chapter:AddInstruction("ACF.CreateMenuCPanel", {Name = "MultiParentMenuCPanel", Label = "Parenting Menu"}):DelayByLength()
Chapter:AddInstruction("ACF.InitializeCustomMenu", {Name = "MultiParentMenuCPanel", BuildCPanel = ParentCPanel}):DelayByLength()

Chapter:AddInstruction("ACF.SetPanelSlider", {Name = "MultiParentMenuCPanel", SliderName = "Auto Select Radius:", Value = 512}):DelayByLength()
Chapter:AddInstruction("ACF.SetPanelCheckBox", {Name = "MultiParentMenuCPanel", CheckBoxName = "#tool.multi_parent.removeconstraints", Value = true}):DelayByLength()
Chapter:AddInstruction("ACF.SetPanelCheckBox", {Name = "MultiParentMenuCPanel", CheckBoxName = "#tool.multi_parent.nocollide", Value = false}):DelayByLength()
Chapter:AddInstruction("ACF.SetPanelCheckBox", {Name = "MultiParentMenuCPanel", CheckBoxName = "#tool.multi_parent.weld", Value = false}):DelayByLength()
Chapter:AddInstruction("ACF.SetPanelCheckBox", {Name = "MultiParentMenuCPanel", CheckBoxName = "#tool.multi_parent.disablecollisions", Value = true}):DelayByLength()
Chapter:AddInstruction("ACF.SetPanelCheckBox", {Name = "MultiParentMenuCPanel", CheckBoxName = "#tool.multi_parent.weight", Value = false}):DelayByLength()
Chapter:AddInstruction("ACF.SetPanelCheckBox", {Name = "MultiParentMenuCPanel", CheckBoxName = "#tool.multi_parent.disableshadow", Value = false}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "It is highly recommended to use the settings shown here."}))

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "IMPORTANT: Make sure to have weld and nocollide disabled to keep your builds optimized!"}))

Chapter:AddDelay(1)

Chapter:AddInstruction("RemovePanel", {Name = "MultiParentMenuCPanel"}):DelayByLength()

local Chapter = Storyboard:Chapter("Parenting Usage")

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Left click all the entities except the baseplate, then right click the baseplate."}))

Chapter:AddDelay(Chapter:AddInstruction("Tools.MultiParent", {
    Children = {"Engine", "FuelTank1", "FuelTank2", "Gearbox"},
    Parent = "Base",
    Easing = math.ease.InOutQuad,
    Length = 4,
}))
Chapter:AddInstruction("HideToolgun", {}):DelayByLength()

Chapter:AddDelay(1)

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "All entities are now parented to the baseplate.\nMoving or rotating the baseplate will also move and rotate the other entities."}))

Chapter:AddDelay(1)
local Chapter = Storyboard:Chapter("Parenting Demonstration")
Chapter:AddInstruction("TransformModel", {
    Target = "Base",
    Position = Vector(0, 0, 100),
    Rotation = Angle(0, 360, 0),
    Length = 2,
}):DelayByLength()

Chapter:AddInstruction("TransformModel", {
    Target = "Base",
    Position = Vector(0, 0, 0),
    Rotation = Angle(0, 0, 0),
    Length = 2,
}):DelayByLength()

Chapter:AddDelay(1)
local Chapter = Storyboard:Chapter("Linking")
Chapter:AddDelay(1)

Chapter:AddInstruction("ShowToolgun", {Tool = language.GetPhrase("tool.acf_menu.menu_name")}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "The ACF Menu tool can link ACF entities to other entities."}))

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Right click the engine and right click the gearbox to link them together."}))

Chapter:AddDelay(Chapter:AddInstruction("ACF Menu", {
    Children = {"Engine"},
    Target = "Gearbox",
    Easing = math.ease.InOutQuad,
    Length = 2,
}))

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Now the gearbox can receive power from the engine."}))

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Hold shift + right click on each fuel tank (multi select) and then right click the engine to link them together."}))

Chapter:AddDelay(Chapter:AddInstruction("ACF Menu", {
    Children = {"FuelTank1", "FuelTank2"},
    Target = "Engine",
    Easing = math.ease.InOutQuad,
    Length = 3,
}))

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Now the engine can receive fuel from the fuel tanks."}))

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "If you look at the engine, you can see a visualization of all linked entities in your drivetrain."}))

Chapter:AddInstruction("HideToolgun", {}):DelayByLength()
Chapter:RecommendStoryboard("acf.tankbasics.suspension")