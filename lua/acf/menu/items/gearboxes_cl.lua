local ACF          = ACF
local Classes      = ACF.Classes
local GetType      = Classes.GetTypeByName
local PAGE         = "acf_gearbox"
local GEARBOX_BASE = "ACF.Gearboxes.BaseGearbox"
local StatsText    = language.GetPhrase("acf.menu.gearboxes.stats")
local Current      = {}

local function SetStatsText(GearboxStats)
	local Mass, Torque, TorqueRating = ACF.GetGearboxStats(Current.Mass, Current.Scale, Current.MaxTorque, Current.GearCount)
	GearboxStats:SetText(StatsText:format(ACF.FormatMass(Mass), TorqueRating * ACF.TorqueMult, Torque * ACF.TorqueMult))
end

local CreateSubMenu

local function Build(Menu, Contexts)
	local Ctx     = Contexts.Gearbox
	local Entries = Classes.GetChildren(GetType(GEARBOX_BASE))

	Menu:AddTitle("#acf.menu.gearboxes.settings")
	Menu:AddWikiLink("Gearboxes", "docs/acf_tutorials/gearboxes.html")

	Menu:AddLabel("#acf.menu.gearboxes.temp_gear_ratio_warning1")
	Menu:AddLabel("#acf.menu.gearboxes.temp_gear_ratio_warning2")
	Menu:AddLabel("#acf.menu.gearboxes.temp_gear_ratio_warning3")

	local GearboxInverted = Menu:AddCheckBox("#acf.menu.gearboxes.inverted")
	Menu:AddHelp("#acf.menu.gearboxes.inverted_desc")

	local GearboxPanel = Menu:AddPanel("ACF_Panel")

	-- Rebuild the sub-menu whenever the legacy-ratio toggle changes (it changes the ratio limits).
	function GearboxInverted:OnChange(Value)
		Ctx:Set("GearboxLegacyRatio", Value)

		GearboxPanel:ClearTemporal()
		GearboxPanel:StartTemporal()
		CreateSubMenu(GearboxPanel, Entries, Value, Ctx)
		GearboxPanel:EndTemporal()
	end

	GearboxInverted:SetValue(Ctx:Get("GearboxLegacyRatio") and true or false)
end

CreateSubMenu = function(Menu, Entries, UseLegacyRatios, Ctx)
	local GearboxClass = Menu:AddComboBox()
	local GearboxList  = Menu:AddComboBox()

	local Base           = Menu:AddCollapsible("#acf.menu.gearboxes.gearbox_info", nil, "icon16/chart_curve_edit.png")
	local GearboxName    = Base:AddTitle()
	local GearboxDesc    = Base:AddLabel()
	local GearboxPreview = Base:AddModelPreview(nil, true, "Primary")
	local GearboxStats   = Base:AddLabel()
	local GearboxScale   = Base:AddSlider("#acf.menu.gearboxes.scale", ACF.GearboxMinSize, ACF.GearboxMaxSize, 2)
	local GearAmount     = Base:AddSlider("#acf.menu.gearboxes.gear_amount", 3, 10, 0)

	function GearboxClass:OnSelect(Index, _, Data)
		if self.Selected == Data then return end
		self.ListData.Index = Index
		self.Selected = Data
		ACF.Menu.SaveClassCombo(PAGE, "group", Data)

		ACF.Menu.LoadClassCombo(GearboxList, Classes.GetChildren(Data), "Name", "Model", PAGE, "item")
	end

	function GearboxList:OnSelect(Index, _, Data)
		if self.Selected == Data then return end
		self.ListData.Index = Index
		self.Selected = Data
		ACF.Menu.SaveClassCombo(PAGE, "item", Data)

		Ctx:Set("Gearbox", Classes.GetTypeName(Data))

		GearboxName:SetText(Data.Name)
		GearboxDesc:SetText(Data.Description)

		Current.Mass      = Data.Mass
		Current.MaxTorque = Data.MaxTorque
		Current.Scale     = Current.Scale or 1
		Current.GearCount = Data.CanSetGears and Current.GearCount or Data.Gears.Max or 3

		SetStatsText(GearboxStats)

		GearboxPreview:UpdateModel(Data.Model)
		GearboxPreview:UpdateSettings(Data.Preview)

		self:UpdateSettings()
	end

	function GearboxList:UpdateSettings()
		local ClassData = GearboxClass.Selected
		local ListData  = GearboxList.Selected
		if not ClassData or not ListData then return end

		GearAmount:SetVisible(ClassData.CanSetGears)
		SetStatsText(GearboxStats)

		Menu:ClearTemporal(Base)
		Menu:StartTemporal(Base)

		if ListData.CanDualClutch then
			local DualClutch = Base:AddCheckBox("#acf.menu.gearboxes.dual_clutch")

			function DualClutch:OnChange(Value)
				Ctx:Set("DualClutch", Value)

				timer.Simple(0.05, function()
					if IsValid(GearboxPreview) and IsValid(GearboxPreview:GetEntity()) then
						GearboxPreview:GetEntity():SetBodygroup(1, Value and 1 or 0)
					end
				end)

				local GhostEnt = ACF.GetGhostEntity()
				if IsValid(GhostEnt) then GhostEnt:SetBodygroup(1, Value and 1 or 0) end
			end

			Base:AddHelp("#acf.menu.gearboxes.dual_clutch_desc")
			DualClutch:SetValue(Ctx:Get("DualClutch") and true or false)
		else
			Ctx:Set("DualClutch", false)

			timer.Simple(0.05, function()
				if IsValid(GearboxPreview) and IsValid(GearboxPreview:GetEntity()) then
					GearboxPreview:GetEntity():SetBodygroup(1, 0)
				end

				local GhostEnt = ACF.GetGhostEntity()
				if IsValid(GhostEnt) then GhostEnt:SetBodygroup(1, 0) end
			end)
		end

		if ClassData.CreateMenu then
			-- Builder signature: (Class, _, Menu, Ctx, UseLegacyRatios). Build onto Base so its
			-- controls are temporal-managed and cleared on reselect.
			ClassData:CreateMenu(ListData, Base, Ctx, UseLegacyRatios)
		end

		Menu:EndTemporal(Base)
	end

	GearboxScale:SetValue(Ctx:Get("GearboxScale") or 1)
	function GearboxScale:OnValueChanged(Value)
		local Scale = math.Round(Value, 2)
		self:SetValue(Scale)

		Current.Scale = Scale
		Ctx:Set("GearboxScale", Scale)

		SetStatsText(GearboxStats)
		ACF.UpdateGhostEntity({ Primary = { Scale = Vector(Scale, Scale, Scale), AbsoluteScale = true } })
	end

	GearAmount:SetValue(Ctx:Get("GearAmount") or 3)
	function GearAmount:OnValueChanged(Value)
		local Count = math.Round(Value, 0)
		if Count == self.Selected then return end

		self.Selected     = Count
		self:SetValue(Count)
		Current.GearCount = Count
		Ctx:Set("GearAmount", Count)

		GearboxList:UpdateSettings()
	end

	ACF.Menu.LoadClassCombo(GearboxClass, Entries, "Name", nil, PAGE, "group")
end

ACF.Menu.RegisterPage({
	ID       = "acf_gearbox",
	Category = "#acf.menu.entities",
	Name     = "#acf.menu.gearboxes",
	Icon     = "cog",
	Order    = 301,

	Contexts = { Gearbox = "acf_gearbox" },

	Actions = {
		{ Bind = "left",  Context = "Gearbox", Preview = true, Desc = "Spawn a new gearbox, or update the one you're aiming at." },
		{ Bind = "right", Commit = "link", Desc = "Select entities, then a gearbox, to link them (hold R to unlink)." },
	},

	Build = Build,
})
