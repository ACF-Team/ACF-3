do
    local storyboard = Ponder.API.NewStoryboard("ponder", "tests", "vgui-poc")

    local CreateMenu = Ponder.API.NewInstruction("ACF.CreateMenu")
    CreateMenu.Length = 0.5

    local RecursiveFindNodeByName function RecursiveFindNodeByName(Parent, Select)
        for _, Node in ipairs(Parent:GetChildNodes()) do
            local Text = Node:GetText()
            if Text == Select then return Node end
            local Subnode = RecursiveFindNodeByName(Node, Select)
            if Subnode then
                return Subnode
            end
        end
    end

    function CreateMenu:First(playback)
        self.Type = "DPanel"
        local env   = playback.Environment
        local panel = env:NewNamedObject("VGUIPanel", self.Name, self.Type, self.Parent)

        local Menu = panel:Add("DForm")
        Menu:Dock(FILL)
        local Base = ACF.InitMenuBase(Menu)
        local Tree = Base:AddPanel("DTree")
        ACF.SetupMenuTree(Base, Tree)
        local Found = RecursiveFindNodeByName(Tree:Root(), language.GetPhrase(self.Select))
        Tree:SetSelectedItem(Found)
        Ponder.VGUI_Support.RunMethods(env, panel, self.Calls, self.Properties)
    end

    -- Set storyboard properties
    storyboard:WithName("Ponder - VGUI Functions")
    storyboard:WithModelIcon("models/props_junk/wood_crate001a.mdl")
    storyboard:WithDescription("VGUI panel examples")
    storyboard:SetPrimaryLanguage("en")

    local chapter1 = storyboard:Chapter()

    -- Set up the initial camera position
    chapter1:AddInstruction("ACF.CreateMenu", {
        Name = "Test",
        Select = "#acf.menu.baseplates",
        Calls = {
            {Method = "SetSize", Args = {300, 800}},
            {Method = "Center", Args = {}},
        },
        Time = 0,
        Length = 0.25,
    }):DelayByLength()
    chapter1:AddDelay(3)
    chapter1:AddInstruction("RemovePanel", {
        Name = "Test",
        Time = 0,
        Length = 1,
    }):DelayByLength()
end