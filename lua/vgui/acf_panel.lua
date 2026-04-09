local PANEL     = {}
-- local ACF       = ACF

DEFINE_BASECLASS("Panel")

-- Core panel methods
function PANEL:Init()
	self.Items = {}
end

function PANEL:ClearChildren()
	for Item in pairs(self.Items) do
		Item:Remove()
	end
end

function PANEL:AddPanel(PanelClass)
	if not PanelClass then return end

	local Panel = vgui.Create(PanelClass, self)

	Panel:Dock(TOP)
	Panel:DockMargin(0, 0, 0, 10)
	Panel:InvalidateParent()
	Panel:InvalidateLayout()

	self:InvalidateLayout()
	self.Items[Panel] = true

	return Panel
end

function PANEL:PerformLayout()
	self:SizeToChildren(true, true)
end

-- Core Elements
function PANEL:AddMenuReload(Command)
	local Reload = self:AddButton("Reload Menu")
	local ReloadDesc = language.GetPhrase("You can type %s in console."):format(Command)
	Reload:SetTooltip(ReloadDesc)

	function Reload:DoClickInternal()
		RunConsoleCommand(Command)
	end

	return Reload
end

-- Default Elements
function PANEL:AddTitle(Text)
	local Panel = self:AddPanel("DLabel")
	Panel:SetText(Text or "Title")
	Panel:SetFont("ACF_Title")
	Panel:SetDark(true)

	return Panel
end

function PANEL:AddLabel(Text)
	local Panel = self:AddPanel("DLabel")
	Panel:SetAutoStretchVertical(true)
	Panel:SetText(Text or "Label")
	Panel:SetFont("ACF_Label")
	Panel:SetWrap(true)
	Panel:SetDark(true)

	return Panel
end

function PANEL:AddHelp(Text)
	local TextColor = self:GetSkin().Colours.Tree.Hover
	local Panel = self:AddLabel(Text)
	Panel:DockMargin(10, 0, 10, 10)
	Panel:SetTextColor(TextColor)
	Panel:InvalidateLayout()

	return Panel
end

function PANEL:AddButton(Text)
	local Panel = self:AddPanel("DButton")
	Panel:SetText(Text or "Button")
	Panel:SetFont("ACF_Control")
	Panel:SetDark(true)

	return Panel
end

function PANEL:AddCheckbox(Text)
	local Panel = self:AddPanel("DCheckBoxLabel")
	Panel:SetText(Text or "Checkbox")
	Panel:SetFont("ACF_Control")
	Panel:SetDark(true)

	function Panel:BindToDataVar(Name, Scope, TargetRealm)
		self:BindToDataVarAdv(Name, Scope, "SetChecked", "GetChecked", "OnChange", TargetRealm)
	end

	return Panel
end

function PANEL:AddSlider(Title, Min, Max, Decimals)
	local Panel = self:AddPanel("DNumSlider")
	Panel:DockMargin(0, 0, 0, 5)
	Panel:SetDecimals(Decimals or 0)
	Panel:SetText(Title or "")
	if Min and Max then
		Panel:SetMinMax(Min, Max)
	end
	Panel:SetDark(true)

	Panel.Label:SetFont("ACF_Control")

	function Panel:BindToDataVar(Name, Scope, TargetRealm)
		self:BindToDataVarAdv(Name, Scope, "SetValue", "GetValue", "OnValueChanged", TargetRealm)
	end

	return Panel
end

function PANEL:AddNumberWang(Label, Min, Max, Decimals)
	local Base = self:AddPanel("ACF_Panel")

	local Wang = Base:Add("DNumberWang")
	Wang:SetDecimals(Decimals or 0)
	Wang:SetMinMax(Min, Max)
	Wang:SetTall(20)
	Wang:Dock(RIGHT)

	local Text = Base:Add("DLabel")
	Text:SetText(Label or "Text")
	Text:SetFont("ACF_Control")
	Text:SetDark(true)
	Text:Dock(TOP)

	function Wang:BindToDataVar(Name, Scope, TargetRealm)
		Wang:BindToDataVarAdv(Name, Scope, "SetValue", "GetValue", "OnValueChanged", TargetRealm)
	end

	return Wang, Text
end

function PANEL:AddComboBox()
	local Panel = self:AddPanel("DComboBox")
	Panel:SetFont("ACF_Control")
	Panel:SetSortItems(false)
	Panel:SetDark(true)
	Panel:SetWrap(true)

	function Panel:BindToDataVar(Name, Scope, TargetRealm)
		local suppress = false
		local DataLookup = {}
		for k, v in ipairs(self.Data) do DataLookup[v] = k end

		local function SetValue(data)
			suppress = true
			self:ChooseOptionID(DataLookup[data] or 1)
			suppress = false
		end

		self.OnSelect = function(_, _, _, data)
			if suppress then return end
			ACF.SetDataVar(Name, Scope, data, TargetRealm)
		end

		self:WatchDataVar(Name, Scope, function(value)
			SetValue(value)
		end)

		local initial = ACF.GetDataVar(Name, Scope, TargetRealm)
		if initial ~= nil then
			SetValue(initial)
		end
	end

	return Panel
end

function PANEL:AddCollapsible(Text, State, Icon)
	if State == nil then State = true end

	local Category = self:AddPanel("DCollapsibleCategory")
	Category:SetLabel(Text or "Title")
	Category.Header:SetFont("ACF_Title")
	Category.Header:SetSize(0, 24)
	Category.Image = Category.Header:Add("DImage")
	Category.Image:SetPos(4, 4)
	Category.Image:SetSize(16, 16)
	if Icon ~= nil then
		Category.Header:SetTextInset(26, 0)
		Category.Image:Show()
		Category.Image:SetImage(Icon)
	end

	local Base = vgui.Create("ACF_Panel")
	Base:DockMargin(5, 5, 5, 5)

	Category:SetContents(Base)
	Category:DoExpansion(State)

	return Base, Category
end

function PANEL:AddTextEntry(LabelText)
	local Base = self:AddPanel("ACF_Panel")

	local Label = Base:AddLabel(LabelText)
	local Entry = Base:AddPanel("DTextEntry")

	Label:Dock(LEFT)

	function Entry:BindToDataVar(Name, Scope, TargetRealm)
		self:BindToDataVarAdv(Name, Scope, "SetText", "GetText", "OnTextChanged", TargetRealm)
	end

	return Entry, Base, Label
end

-- Advanced elements that are large are placed in separate files for cleanliness.
include("advanced_panels/presets_bar.lua")(PANEL)
include("advanced_panels/model_preview.lua")(PANEL)
include("advanced_panels/vector_slider.lua")(PANEL)

-- TODO: Add graph element

-- Must be after methods are attached to the PANEL table.
derma.DefineControl("ACF_Panel", "", PANEL, "Panel")