

do
    local storyboard = Ponder.API.NewStoryboard("ponder", "tests", "vgui-poc")

    -- Set storyboard properties
    storyboard:WithName("Ponder - VGUI Functions")
    storyboard:WithModelIcon("models/props_junk/wood_crate001a.mdl")
    storyboard:WithDescription("VGUI panel examples")
    storyboard:SetPrimaryLanguage("en")

    local chapter1 = storyboard:Chapter()

    -- Set up the initial camera position
    chapter1:AddInstruction("ACF.CreateMainMenu", {
    Name = "MainMenuCPanel",
    Size = {400, 600},
    Select = "#acf.menu.baseplates",
    ScrollTo = "#acf.menu.baseplates.plate_thickness",
    }):DelayByLength()
    chapter1:AddInstruction("RemovePanel", {
        Name = "Test",
        Time = 0,
        Length = 1,
    }):DelayByLength()
end

