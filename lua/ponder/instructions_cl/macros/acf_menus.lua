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

local RecursiveFindPanelByName function RecursiveFindPanelByName(Parent, Select)
    for _, Panel in ipairs(Parent:GetChildren()) do
        local Text = Panel:GetText()
        if Text == Select then return Panel end
        local Subnode = RecursiveFindPanelByName(Panel, Select)
        if Subnode then return Subnode end
    end
end

local ScrollToMenuPanel = Ponder.API.NewInstruction("ACF.ScrollToMenuPanel")
ScrollToMenuPanel.Length = 1

function ScrollToMenuPanel:First(playback)
    local panel = playback.Environment:GetNamedObject("VGUIPanel", self.Name)
    local Target = RecursiveFindPanelByName(panel.Base, language.GetPhrase(self.Scroll))
    if Target then panel.Scroll:ScrollToChild(Target) end
end

--- Combines all the work of creating a menu into an easy macro

local CreateMainMenu = Ponder.API.NewInstructionMacro("ACF.CreateMainMenu")
function CreateMainMenu:Run(chapter, parameters)
    local length = parameters.Length or 1
    local timePerAction = length / 3

    local tAdd = 0
    chapter:AddInstruction("PlacePanel", {
        Name = parameters.Name,
        Type = "DPanel",
        Calls = {
            {Method = "SetSize", Args = parameters.Size or {300, 700}},
            {Method = "Center", Args = {}},
        },
        Time = tAdd,
    })
    tAdd = tAdd + timePerAction

    chapter:AddInstruction("ACF.CreateMenuCPanel", {
        Name = parameters.Name,
        Label = parameters.Label or "ACF Menu",
        Time = tAdd,
    })
    tAdd = tAdd + timePerAction

    chapter:AddInstruction("ACF.InitializeMainMenu", {
        Name = parameters.Name,
        Time = tAdd,
    })
    tAdd = tAdd + timePerAction
    return tAdd
end

--- Various helpers to set the values of elements in the ACF menu
local SetACFPanelSlider = Ponder.API.NewInstruction("ACF.SetPanelSlider")
SetACFPanelSlider.Length = 1

function SetACFPanelSlider:First(playback)
    local panel = playback.Environment:GetNamedObject("VGUIPanel", self.Name)
    local Slider = RecursiveFindPanelByName(panel.Base, language.GetPhrase(self.SliderName))
    if IsValid(Slider) and Slider.SetValue then
        ACF.DisableClientData = true
        Slider:SetValue(self.Value)
        ACF.DisableClientData = false
    end
end