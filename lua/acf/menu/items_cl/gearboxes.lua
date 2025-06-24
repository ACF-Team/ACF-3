local ACF = ACF
local Gearboxes = ACF.Classes.Gearboxes
local Current = {}
local StatsText = language.GetPhrase("acf.menu.gearboxes.stats")

local function SetStatsText(GearboxStats)
	local Mass, Torque, TorqueRating = ACF.GetGearboxStats(Current.Mass, Current.Scale, Current.MaxTorque, Current.GearCount)

	GearboxStats:SetText(StatsText:format(ACF.GetProperMass(Mass), TorqueRating, Torque))
end

local function CreateMenu(Menu)
	local Entries = Gearboxes.GetEntries()

	Menu:AddTitle("#acf.menu.gearboxes.settings")
	-- TODO: Remove this warning a few months after the scalable gearboxes update is added
	Menu:AddLabel("#acf.menu.gearboxes.temp_gear_ratio_warning1")
	Menu:AddLabel("#acf.menu.gearboxes.temp_gear_ratio_warning2")

	local GearboxClass = Menu:AddComboBox()
	local GearboxList = Menu:AddComboBox()

	local Base = Menu:AddCollapsible("#acf.menu.gearboxes.gearbox_info", nil, "icon16/chart_curve_edit.png")
	local GearboxName = Base:AddTitle()
	local GearboxDesc = Base:AddLabel()
	local GearboxPreview = Base:AddModelPreview(nil, true)
	local GearboxStats = Base:AddLabel()
	local GearboxScale = Base:AddSlider("#acf.menu.gearboxes.scale", ACF.GearboxMinSize, ACF.GearboxMaxSize, 2)
	local GearAmount = Base:AddSlider("#acf.menu.gearboxes.gear_amount", 3, 10, 0)

	ACF.SetClientData("PrimaryClass", "acf_gearbox")
	ACF.SetClientData("SecondaryClass", "N/A")

	ACF.SetToolMode("acf_menu", "Spawner", "Gearbox")

	function GearboxClass:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.ListData.Index = Index
		self.Selected = Data

		ACF.SetClientData("GearboxClass", Data.ID)

		ACF.LoadSortedList(GearboxList, Data.Items, "ID")
	end

	function GearboxList:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.ListData.Index = Index
		self.Selected = Data

		ACF.SetClientData("Gearbox", Data.ID)

		GearboxName:SetText(Data.Name)
		GearboxDesc:SetText(Data.Description)

		Current.Mass = Data.Mass
		Current.MaxTorque = Data.MaxTorque
		Current.Scale = Current.Scale or 1
		Current.GearCount = Data.Class.CanSetGears and Current.GearCount or Data.Class.Gears.Max or 3

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
			DualClutch:SetClientData("DualClutch", "OnChange")
			DualClutch:DefineSetter(function(Panel, _, _, Value)
				Panel:SetValue(Value)
				timer.Simple(0.05, function()
					GearboxPreview:GetEntity():SetBodygroup(1, Value and 1 or 0)
				end)

				return Value
			end)
			Base:AddHelp("#acf.menu.gearboxes.dual_clutch_desc")
			DualClutch:SetChecked(true)
		else
			ACF.SetClientData("DualClutch", false)

			timer.Simple(0.05, function()
				GearboxPreview:GetEntity():SetBodygroup(1, 0)
			end)
		end

		if ClassData.CreateMenu then
			ClassData:CreateMenu(ListData, Menu, Base)
		end

		Menu:EndTemporal(Base)
	end

	GearboxScale:SetClientData("GearboxScale", "OnValueChanged")
	GearboxScale:DefineSetter(function(Panel, _, _, Value)
		local Scale = math.Round(Value, 2)

		Panel:SetValue(Scale)
		Current.Scale = Scale

		SetStatsText(GearboxStats)

		return Scale
	end)

	GearAmount:SetClientData("GearAmount", "OnValueChanged")
	GearAmount:DefineSetter(function(Panel, _, _, Value)
		local Count = math.Round(Value, 0)
		if Count == Panel.Selected then return Count end

		Current.GearCount = Count
		Panel.Selected = Count
		Panel:SetValue(Count)
		GearboxList:UpdateSettings()

		return Count
	end)

	ACF.LoadSortedList(GearboxClass, Entries, "ID")
end

ACF.AddMenuItem(301, "#acf.menu.entities", "#acf.menu.gearboxes", "cog", CreateMenu)