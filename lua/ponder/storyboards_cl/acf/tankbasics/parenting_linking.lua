local Storyboard = Ponder.API.NewStoryboard("acf", "tankbasics", "parenting_linking")
Storyboard:WithName("Parenting & Linking")
Storyboard:WithBaseEntity(nil)
Storyboard:WithModelIcon("models/weapons/w_toolgun.mdl")
Storyboard:WithDescription("Introducing parenting and linking")
Storyboard:WithIndexOrder(98)

-------------------------------------------------------------------------------------------------
local Chapter = Storyboard:Chapter("Setup")
Chapter:AddInstruction("MoveCameraLookAt", {Length = 1,  Angle = -225, Distance = 2000}):DelayByLength()

Chapter:AddInstruction("PlaceModel", {
    Name = "Baseplate1",
    IdentifyAs = "acf_baseplate",
    Model = "models/hunter/plates/plate2x5.mdl",
    Position = Vector(0, 0, 0),
    Angles = Angle(0, 0, 0),
    Scale = Vector(1, 1.25, 1),
    ComeFrom = Vector(0, 0, 50)
}):DelayByLength()

Chapter:AddInstruction("PlaceModel", {
    Name = "Engine1",
    Model = "models/engines/v12l.mdl",
    Position = Vector(0, -84, 3),
    Angles = Angle(0, 90, 0),
    ParentTo = "Baseplate1",
}):DelayByLength()

Chapter:AddInstruction("PlaceModel", {
    Name = "FuelTank1",
    Model = "models/acf/core/s_fuel.mdl",
    Position = Vector(36, -84, 15),
    Scale = Vector(6, 2, 2),
    Angles = Angle(0, 90, 0),
    ParentTo = "Baseplate1",
}):DelayByLength()

Chapter:AddInstruction("PlaceModel", {
    Name = "FuelTank2",
    Model = "models/acf/core/s_fuel.mdl",
    Position = Vector(-36, -84, 15),
    Scale = Vector(6, 2, 2),
    Angles = Angle(0, 90, 0),
    ParentTo = "Baseplate1",
}):DelayByLength()

Chapter:AddInstruction("PlaceModel", {
    Name = "Gearbox1",
    Model = "models/engines/transaxial_s.mdl",
    Position = Vector(0, -144, 3),
    Angles = Angle(0, 90, 0),
    Scale = Vector(2, 2, 2),
    ParentTo = "Baseplate1",
}):DelayByLength()


local Chapter = Storyboard:Chapter("Parenting & Linking")
Chapter:AddInstruction("ShowToolgun", {Tool = language.GetPhrase("tool.multi_parent.listname")}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("Caption", {
    Text = "The Multi Parent tool can parent two entities together.",
    Horizontal = TEXT_ALIGN_CENTER,
    Position = Vector(0.5, 0.15, 0),
}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {
    Text = "Parented entities will move and rotate together.",
    Horizontal = TEXT_ALIGN_CENTER,
    Position = Vector(0.5, 0.15, 0),
}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {
    Text = "Parenting is considerably more optimized than constraints like welds, so use it whenever possible.",
    Horizontal = TEXT_ALIGN_CENTER,
    Position = Vector(0.5, 0.15, 0),
}))

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

Chapter:AddDelay(Chapter:AddInstruction("Caption", {
    Text = "It is highly recommended to use the settings shown here.",
    Horizontal = TEXT_ALIGN_CENTER,
    Position = Vector(0.5, 0.15, 0),
}))

Chapter:AddDelay(Chapter:AddInstruction("Caption", {
    Text = "!!!Make sure to have weld and nocollide disabled to keep your builds optimized.!!!",
    Horizontal = TEXT_ALIGN_CENTER,
    Position = Vector(0.5, 0.15, 0),
}))

Chapter:AddDelay(1)

Chapter:AddInstruction("RemovePanel", {Name = "MultiParentMenuCPanel"}):DelayByLength()

local Chapter = Storyboard:Chapter("Parenting Usage")

Chapter:AddDelay(Chapter:AddInstruction("Caption", {
    Text = "Left click all the entities except the baseplate, then right click the baseplate.",
    Horizontal = TEXT_ALIGN_CENTER,
    Position = Vector(0.5, 0.15, 0),
}))

Chapter:AddDelay(Chapter:AddInstruction("Tools.MultiParent", {
    Children = {"Engine1", "FuelTank1", "FuelTank2", "Gearbox1"},
    Parent = "Baseplate1",
    Easing = math.ease.InOutQuad,
    Length = 4,
}))
Chapter:AddInstruction("HideToolgun", {}):DelayByLength()

Chapter:AddDelay(1)

Chapter:AddDelay(Chapter:AddInstruction("Caption", {
    Text = "All entities are now parented to the baseplate.\nMoving or rotating the baseplate will also move and rotate the other entities.",
    Horizontal = TEXT_ALIGN_CENTER,
    Position = Vector(0.5, 0.15, 0),
}))

Chapter:AddDelay(1)
local Chapter = Storyboard:Chapter("Parenting Demonstration")
Chapter:AddInstruction("TransformModel", {
    Target = "Baseplate1",
    Position = Vector(0, 0, 100),
    Rotation = Angle(0, 360, 0),
    Length = 2,
}):DelayByLength()

Chapter:AddInstruction("TransformModel", {
    Target = "Baseplate1",
    Position = Vector(0, 0, 0),
    Rotation = Angle(0, 0, 0),
    Length = 2,
}):DelayByLength()

Chapter:AddDelay(1)
local Chapter = Storyboard:Chapter("Linking")
Chapter:AddDelay(1)

Chapter:AddInstruction("ShowToolgun", {Tool = language.GetPhrase("tool.acf_menu.menu_name")}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("Caption", {
    Text = "The ACF Menu tool can link ACF entities to other entities.",
    Horizontal = TEXT_ALIGN_CENTER,
    Position = Vector(0.5, 0.15, 0),
}))

Chapter:AddDelay(Chapter:AddInstruction("Caption", {
    Text = "Right click the engine and right click the gearbox to link them together.",
    Horizontal = TEXT_ALIGN_CENTER,
    Position = Vector(0.5, 0.15, 0),
}))

Chapter:AddDelay(Chapter:AddInstruction("ACF Menu", {
    Children = {"Engine1"},
    Target = "Gearbox1",
    Easing = math.ease.InOutQuad,
    Length = 2,
}))

Chapter:AddDelay(Chapter:AddInstruction("Caption", {
    Text = "Now the gearbox can receive power from the engine.",
    Horizontal = TEXT_ALIGN_CENTER,
    Position = Vector(0.5, 0.15, 0),
}))

Chapter:AddDelay(Chapter:AddInstruction("Caption", {
    Text = "Hold shift + right click on each fuel tank (multi select) and then right click the engine to link them together.",
    Horizontal = TEXT_ALIGN_CENTER,
    Position = Vector(0.5, 0.15, 0),
}))

Chapter:AddDelay(Chapter:AddInstruction("ACF Menu", {
    Children = {"FuelTank1", "FuelTank2"},
    Target = "Engine1",
    Easing = math.ease.InOutQuad,
    Length = 3,
}))

Chapter:AddDelay(Chapter:AddInstruction("Caption", {
    Text = "Now the engine can receive fuel from the fuel tanks.",
    Horizontal = TEXT_ALIGN_CENTER,
    Position = Vector(0.5, 0.15, 0),
}))

Chapter:AddDelay(Chapter:AddInstruction("Caption", {
    Text = "If you look at the engine, you can see a visualization of all linked entities in your drivetrain.",
    Horizontal = TEXT_ALIGN_CENTER,
    Position = Vector(0.5, 0.15, 0),
}))

Chapter:AddInstruction("HideToolgun", {}):DelayByLength()