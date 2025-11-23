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

    local RecursiveFindPanelByName function RecursiveFindPanelByName(Parent, Select)
        for _, Panel in ipairs(Parent:GetChildren()) do
            local Text = Panel:GetText()
            if Text == Select then return Panel end
            local Subnode = RecursiveFindPanelByName(Panel, Select)
            if Subnode then
                return Subnode
            end
        end
    end

    function CreateMenu:First(playback)
        self.Type = "DPanel"
        local env   = playback.Environment
        local panel = env:NewNamedObject("VGUIPanel", self.Name, self.Type, self.Parent)

        local Scroll = panel:Add("DScrollPanel")
        Scroll:Dock(FILL)
        local CPanel = Scroll:Add("ControlPanel")
        CPanel:Dock(FILL)
        local Menu, Tree = ACF.CreateSpawnMenu(CPanel)
        panel.Menu = Menu
        panel.Tree = Tree

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
        ScrollTo = "#acf.menu.baseplates.plate_thickness",
        Calls = {
            {Method = "SetSize", Args = {300, 400}},
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