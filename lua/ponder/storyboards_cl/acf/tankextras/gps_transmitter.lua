local Storyboard = Ponder.API.NewStoryboard("acf", "tankextras", "gpstransmitter")
Storyboard:WithName("GPS Transmitter")
Storyboard:WithModelIcon("models/props_lab/reciever01a.mdl")
Storyboard:WithDescription("How to use the GPS Transmitter with ACF missiles.")
Storyboard:WithIndexOrder(0)

-------------------------------------------------------------------------------------------------
local Chapter = Storyboard:Chapter("Setup")
Chapter:AddInstruction("MoveCameraLookAt", {Length = 1,  Angle = -225, Distance = 2000}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("PlaceModels", {
    Length = 0.5,
    Models = {
        {Name = "Base", IdentifyAs = "Base", Model = "models/hunter/plates/plate2x5.mdl", Angles = Angle(0, 0, 0), Position = Vector(0, 0, 0), ComeFrom = Vector(0, 0, 50), Scale = Vector(1, 1.25, 1), },
        {Name = "GPS Transmitter", IdentifyAs = "GPS Transmitter", Model = "models/props_lab/reciever01a.mdl", Angles = Angle(0,-90, 0), Position = Vector(0, 0, 10), ComeFrom = Vector(0, 0, 50), ParentTo = "Base", },
        { Name = "Rack" , IdentifyAs = "Missile Rack" , Model = "models/missiles/rkx1.mdl" , Angles = Angle(-45,90, 0) , Position = Vector(0, 60, 40), ComeFrom = Vector(0, 0, 50) , ParentTo = "Base" , Scale = Vector(1, 1, 1) , },
        { Name = "AIO" , IdentifyAs = "AIO" , Model = "models/hunter/plates/plate025x025.mdl" , Angles = Angle(0,0, 0) , Position = Vector(15, 35, 5), ComeFrom = Vector(0, 0, 50) , ParentTo = "Base" , Scale = Vector(1, 1, 1) , },
    }
}))

local Chapter = Storyboard:Chapter("Selecting the right ammo settings for GPS targeting")

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
Chapter:AddInstruction("ACF.SelectMenuTreeNode", {Name = "MainMenuCPanel", Select = "Missiles"}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Select a missile that supports GPS guidance. For this example, we will use the SAKR-10."}))
Chapter:AddDelay(1)
Chapter:AddInstruction("ACF.SetPanelComboBox", {Name = "MainMenuCPanel", ComboBoxName = "MissileTypes", OptionID = 3}):DelayByLength()
Chapter:AddDelay(1)

Chapter:AddInstruction("ACF.SetPanelComboBox", {Name = "MainMenuCPanel", ComboBoxName = "MissileList", OptionID = 2}):DelayByLength()
Chapter:AddInstruction("ACF.ScrollToMenuPanel", {Name = "MainMenuCPanel", Scroll = "#acf.menu.ammo.stage"}):DelayByLength()


Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Set ammo guidance to GPS Guided."}))
Chapter:AddInstruction("ACF.SetPanelComboBox", {Name = "MainMenuCPanel", ComboBoxName = "GuidanceList", OptionID = 2}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Set fuze to contact or optical"}))
Chapter:AddInstruction("ACF.SetPanelComboBox", {Name = "MainMenuCPanel", ComboBoxName = "FuzeList", OptionID = 2}):DelayByLength()

Chapter:AddInstruction("ACF.SetPanelSlider", {Name = "MainMenuCPanel", SliderName = "#acf.menu.ammo.propellant_length", Value = 50}):DelayByLength()
Chapter:AddInstruction("ACF.SetPanelSlider", {Name = "MainMenuCPanel", SliderName = "#acf.menu.ammo.projectile_length", Value = 100}):DelayByLength()
Chapter:AddInstruction("ACF.SetPanelSlider", {Name = "MainMenuCPanel", SliderName = "#acf.menu.ammo.filler_ratio", Value = 1}):DelayByLength()



local Chapter = Storyboard:Chapter("Ammo Placement")
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Shift + left click to spawn an ammo crate and right click to link it to the rack."}))
Chapter:AddDelay(Chapter:AddInstruction("PlaceModels", {
    Models = {
        {Name = "AmmoCrate1", IdentifyAs = "SAKR 10 HE", Model = "models/holograms/hq_rcube.mdl", Angles = Angle(0, 90, 0), Position = Vector(24, -72, 24), ComeFrom = Vector(0, 0, 50), Scale = Vector(1, 4, 2), Material = "phoenix_storms/future_vents", ParentTo = "Base", },
    }
}))
Chapter:AddDelay(Chapter:AddInstruction("PlaceModels", {
    Models = {
        {Name = "Rocketmodel", IdentifyAs = "SAKR 10 HE", Model = "models/missiles/hvar_folded.mdl", Angles = Angle(-45, 90, 0), Position = Vector(0, 60, 40), ComeFrom = Vector(0, 0, 50), Scale = Vector(1, 1, 1), ParentTo = "Base", },
    }
}))

local Chapter = Storyboard:Chapter("Wiring the GPS Transmitter")

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Using the wiring tool, connect the GPS transmitter's Coordinates [VECTOR] input to your all in one controller's HitPos[VECTOR] output."}))

Chapter:AddInstruction("HideToolgun", {}):DelayByLength()
Chapter:AddInstruction("ShowToolgun", {Tool = "Wiring Tool"}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("Tools.MultiParent", {Children = {"GPS Transmitter"}, Parent = "AIO", Easing = math.ease.InOutQuad, Length = 1}))
Chapter:AddInstruction("HideToolgun", {}):DelayByLength()


Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Now when you fire the missile, it will aim for the position your all in one controller was pointing at when you shot."}))


Chapter:AddDelay(1)

