local Storyboard = Ponder.API.NewStoryboard("acf", "tankbasics", "armor")
Storyboard:WithName("Armor")
Storyboard:WithBaseEntity(nil)
Storyboard:WithModelIcon("models/props_c17/streetsign004f.mdl")
Storyboard:WithDescription("Learn how to protect your tank")
Storyboard:WithIndexOrder(93)

-------------------------------------------------------------------------------------------------

local Chapter = Storyboard:Chapter("Armor Tool Menu")
Chapter:AddInstruction("PlacePanel", {
    Name = "SuspensionMenuCPanel",
    Type = "DPanel",
    Calls = {
        {Method = "SetSize", Args = {300, 700}},
        {Method = "SetPos", Args = {1500, 0}},
        {Method = "CenterVertical", Args = {}},
    },
    Length = 0.25,
}):DelayByLength()
Chapter:AddInstruction("ACF.CreateMenuCPanel", {Name = "SuspensionMenuCPanel", Label = "ACF Menu"}):DelayByLength()
Chapter:AddInstruction("ACF.InitializeCustomMenu", {Name = "SuspensionMenuCPanel", BuildCPanel = ACF.CreateArmorPropertiesMenu}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "We recommend beginners use rigid suspension, since it is the easiest and most optimized."}))
Chapter:AddInstruction("ACF.SetPanelComboBox", {Name = "SuspensionMenuCPanel", ComboBoxName = "Spring Type", OptionID = 1}):DelayByLength()