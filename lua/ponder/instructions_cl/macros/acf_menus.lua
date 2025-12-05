--- Creating the CPanel acf menus are created on

local CreateMenuCPanel = Ponder.API.NewInstruction("ACF.CreateMenuCPanel")
CreateMenuCPanel.Length = 1

function CreateMenuCPanel:First(playback)
    local panel = playback.Environment:GetNamedObject("VGUIPanel", self.Name)
    local Scroll = panel:Add("DScrollPanel")
    Scroll:Dock(FILL)
    local CPanel = Scroll:Add("ControlPanel")
    CPanel:Dock(FILL)
    CPanel:SetName(self.Label)
    panel.Scroll = Scroll
    panel.CPanel = CPanel
end

--- Initializing the main menu and its tree on a given CPanel

local InitializeMainMenu = Ponder.API.NewInstruction("ACF.InitializeMainMenu")
InitializeMainMenu.Length = 1

function InitializeMainMenu:First(playback)
    local panel = playback.Environment:GetNamedObject("VGUIPanel", self.Name)
    local Base = ACF.InitMenuBase(panel.CPanel)
    local Tree = Base:AddPanel("DTree")
    ACF.SetupMenuTree(Base, Tree)
    panel.Base = Base
    panel.Tree = Tree
end

--- Initializing a custom ACF menu on a given CPanel

local InitializeCustomMenu = Ponder.API.NewInstruction("ACF.InitializeCustomACFMenu")
InitializeCustomMenu.Length = 1

function InitializeCustomMenu:First(playback)
    local panel = playback.Environment:GetNamedObject("VGUIPanel", self.Name)
    local Base = ACF.InitMenuBase(panel.CPanel)
    self.CreateMenu(Base)
    panel.Base = Base
end

--- Initializing a custom menu on a given CPanel

local InitializeCustomMenu = Ponder.API.NewInstruction("ACF.InitializeCustomMenu")
InitializeCustomMenu.Length = 1

function InitializeCustomMenu:First(playback)
    local panel = playback.Environment:GetNamedObject("VGUIPanel", self.Name)
    self.BuildCPanel(panel.CPanel)
    panel.Base = panel
end

--- Selecting a node in the menu tree by name

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

local SelectMenuTreeNode = Ponder.API.NewInstruction("ACF.SelectMenuTreeNode")
SelectMenuTreeNode.Length = 1

function SelectMenuTreeNode:First(playback)
    local panel = playback.Environment:GetNamedObject("VGUIPanel", self.Name)
    local Node = RecursiveFindNodeByName(panel.Tree:Root(), language.GetPhrase(self.Select))
    if Node then panel.Tree:SetSelectedItem(Node) end
end

--- Scrolling to a panel in the menu by name

local RecursiveFindPanelByText function RecursiveFindPanelByText(Parent, Select)
    for _, Panel in ipairs(Parent:GetChildren()) do
        if Panel:GetText() == Select then return Panel end
        local Subnode = RecursiveFindPanelByText(Panel, Select)
        if Subnode then return Subnode end
    end
end

local ScrollToMenuPanel = Ponder.API.NewInstruction("ACF.ScrollToMenuPanel")
ScrollToMenuPanel.Length = 1

function ScrollToMenuPanel:First(playback)
    local panel = playback.Environment:GetNamedObject("VGUIPanel", self.Name)
    local Target = RecursiveFindPanelByText(panel.Base, language.GetPhrase(self.Scroll))
    if Target then panel.Scroll:ScrollToChild(Target) end
end

--- Various helpers to set the values of elements in the ACF menu
local SetACFPanelSlider = Ponder.API.NewInstruction("ACF.SetPanelSlider")
SetACFPanelSlider.Length = 1

function SetACFPanelSlider:First(playback)
    local panel = playback.Environment:GetNamedObject("VGUIPanel", self.Name)
    local Slider = RecursiveFindPanelByText(panel.Base, language.GetPhrase(self.SliderName))
    if IsValid(Slider) and Slider.SetValue then
        ACF.DisableClientData = true
        Slider:SetValue(self.Value)
        ACF.DisableClientData = false
    end
end

local RecursiveFindPanelByName function RecursiveFindPanelByName(Parent, Select)
    for _, Panel in ipairs(Parent:GetChildren()) do
        if Panel:GetName() == Select then return Panel end
        local Subnode = RecursiveFindPanelByName(Panel, Select)
        if Subnode then return Subnode end
    end
end

local SetACFPanelComboBox = Ponder.API.NewInstruction("ACF.SetPanelComboBox")
SetACFPanelComboBox.Length = 1

function SetACFPanelComboBox:First(playback)
    local panel = playback.Environment:GetNamedObject("VGUIPanel", self.Name)
    local ComboBox = RecursiveFindPanelByName(panel.Base, language.GetPhrase(self.ComboBoxName))
    if IsValid(ComboBox) and ComboBox.ChooseOptionID then
        ACF.DisableClientData = true
        ComboBox:ChooseOptionID(self.OptionID)
        ACF.DisableClientData = false
    end
end

local SetACFPanelCheckBox = Ponder.API.NewInstruction("ACF.SetPanelCheckBox")
SetACFPanelCheckBox.Length = 1
function SetACFPanelCheckBox:First(playback)
    local panel = playback.Environment:GetNamedObject("VGUIPanel", self.Name)
    local CheckBox = RecursiveFindPanelByText(panel.Base, language.GetPhrase(self.CheckBoxName))
    if IsValid(CheckBox) and CheckBox.SetValue then
        ACF.DisableClientData = true
        CheckBox:SetValue(self.Value)
        ACF.DisableClientData = false
    end
end