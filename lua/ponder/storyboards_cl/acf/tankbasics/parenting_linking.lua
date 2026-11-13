local Storyboard = Ponder.API.NewStoryboard("acf", "tankbasics", "parenting_linking")
Storyboard:WithName("Parenting & Linking")
Storyboard:WithBaseEntity(nil)
Storyboard:WithModelIcon("models/weapons/w_toolgun.mdl")
Storyboard:WithDescription("Introducing parenting and linking")
Storyboard:WithIndexOrder(99.5)

-------------------------------------------------------------------------------------------------
local Chapter = Storyboard:Chapter("Setup")
Chapter:AddInstruction("MoveCameraLookAt", {Length = 1,  Angle = -225, Distance = 1600}):DelayByLength()

Chapter:AddInstruction("PlaceModel", {Name = "Base", IdentifyAs = "Base", Model = "models/hunter/plates/plate2x5.mdl", Angles = Angle(0, 0, 0), Position = Vector(0, 0, 0), ComeFrom = Vector(0, 0, 50), Scale = Vector(1, 1.25, 1)}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Now that you have a baseplate, let's give it a controller. Along the way you'll learn parenting and linking, which every other part of your tank needs."}))

local Chapter = Storyboard:Chapter("AIO Controller")
Chapter:AddInstruction("ShowToolgun", {Tool = language.GetPhrase("tool.acf_menu.menu_name")}):DelayByLength()
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
Chapter:AddInstruction("ACF.SelectMenuTreeNode", {Name = "MainMenuCPanel", Select = "Controllers"}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "An All In One (AIO) controller lets you drive and fight with your vehicle without any wiring. Select Controllers in the ACF menu."}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Press Mouse1 (Left Click) to spawn one on your baseplate."}))
Chapter:AddInstruction("MoveToolgunTo", {Target = "Base", Easing = math.ease.InOutQuad}):DelayByLength()
Chapter:AddInstruction("ClickToolgun", {Target = "Base"}):DelayByLength()
Chapter:AddInstruction("PlaceModel", {Name = "AIO", IdentifyAs = "AIO Controller", Model = "models/hunter/plates/plate025x025.mdl", Position = Vector(-30, 100, 3), ComeFrom = Vector(0, 0, 50), ParentTo = "Base"}):DelayByLength()
Chapter:AddDelay(1)
Chapter:AddInstruction("RemovePanel", {Name = "MainMenuCPanel", Length = 0.5}):DelayByLength()
Chapter:AddInstruction("HideToolgun", {}):DelayByLength()

-------------------------------------------------------------------------------------------------
local Chapter = Storyboard:Chapter("Parenting")
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

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Left click every entity you want to parent, then right click the baseplate last. Here, that's just the controller."}))

Chapter:AddDelay(Chapter:AddInstruction("Tools.MultiParent", {
    Children = {"AIO"},
    Parent = "Base",
    Easing = math.ease.InOutQuad,
    Length = 2,
}))
Chapter:AddInstruction("HideToolgun", {}):DelayByLength()

Chapter:AddDelay(1)

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "The controller is now parented to the baseplate.\nMoving or rotating the baseplate will also move and rotate it."}))

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

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Linking tells ACF entities how they work together. Parenting only holds them in place."}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "With the ACF Menu tool, right click the baseplate, then right click the controller, to link them."}))

Chapter:AddDelay(Chapter:AddInstruction("ACF Menu", {Children = {"Base"}, Target = "AIO", Easing = math.ease.InOutQuad, Length = 2}))

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Now the controller uses the baseplate's seat. Sit in it with Alt + E."}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "To link several entities at once, hold Shift while right clicking each of them, then right click the target."}))

Chapter:AddInstruction("HideToolgun", {}):DelayByLength()

-------------------------------------------------------------------------------------------------
local Chapter = Storyboard:Chapter("AIO Settings")
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Hold C and right click the controller to change its settings."}))
Chapter:AddDelay(Chapter:AddInstruction("ACF.ShowAIOMenu", {Target = "AIO"}))
Chapter:AddInstruction("ACF.SetAIOSetting", {Name = "AIOMenu", Setting = "Cam1Offset"}):DelayByLength()
Chapter:AddInstruction("ACF.SetAIOSetting", {Name = "AIOMenu", Setting = "Cam1Orbit"}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Cam1Offset and Cam1Orbit place the camera around the baseplate."}))
Chapter:AddInstruction("ACF.SetAIOSetting", {Name = "AIOMenu", Setting = "SpeedUnit"}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "SpeedUnit picks how the baseplate's speed is shown on the HUD."}))
Chapter:AddInstruction("RemovePanel", {Name = "AIOMenu", Length = 0.5}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Each of the following tutorials links its new parts to this controller."}))
Chapter:RecommendStoryboard("acf.tankbasics.drivetrain")
