local ACF = ACF
local Gearboxes = ACF.Classes.Gearboxes
local Current = {}
local StatsText = language.GetPhrase("acf.menu.gearboxes.stats")

local function CreateMenu(Menu)
	local Entries = Gearboxes.GetEntries()

	Menu:AddTitle("#acf.menu.gearboxes.settings")

	local GearboxClass = Menu:AddComboBox()
	local GearboxList = Menu:AddComboBox()

	local Base = Menu:AddCollapsible("#acf.menu.gearboxes.gearbox_info")
	local GearboxName = Base:AddTitle()
	local GearboxDesc = Base:AddLabel()
	local GearboxPreview = Base:AddModelPreview(nil, true)
	local GearboxStats = Base:AddLabel()
	local GearboxScale = Base:AddSlider("#acf.menu.gearboxes.scale", 0.75, 3, 2)
	local GearAmount = Base:AddSlider("#acf.menu.gearboxes.gear_amount", 3, 8, 0)

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
		Current.GearCount = Current.GearCount or 3

		local Mass = ACF.GetProperMass(math.floor((Data.Mass * (Current.Scale ^ ACF.GearboxMassScale)) / 5) * 5)
		local TorqueRating = Data.MaxTorque * Current.Scale * ACF.TorqueMult
		local Torque = math.floor(Data.MaxTorque * 0.73 * Current.Scale) * ACF.TorqueMult
		GearboxStats:SetText(StatsText:format(Mass, TorqueRating, Torque))

		GearboxPreview:UpdateModel(Data.Model)
		GearboxPreview:UpdateSettings(Data.Preview)
		self:UpdateSettings()
	end

	function GearboxList:UpdateSettings()
		local ClassData = GearboxClass.Selected
		local ListData  = GearboxList.Selected
		if not ClassData or not ListData then return end

		GearAmount:SetVisible(ClassData.CanSetGears)

		local Mass = ACF.GetProperMass(math.floor((Current.Mass * (Current.Scale ^ ACF.GearboxMassScale)) / 5) * 5)

		-- Torque calculations
		local TorqueLoss = Current.MaxTorque * (ACF.GearEfficiency ^ Current.GearCount)
		local ScalingCurve = Current.Scale ^ ACF.GearboxTorqueScale
		local MaxTorque = math.floor((TorqueLoss * ScalingCurve) / 10) * 10
		--local Torque = math.floor(Current.MaxTorque * 0.73 * Scale)
		GearboxStats:SetText(StatsText:format(Mass, MaxTorque * Current.Scale, MaxTorque))

		Menu:ClearTemporal(Base)
		Menu:StartTemporal(Base)

		if ListData.CanDualClutch then
			local DualClutch = Base:AddCheckBox("#acf.menu.gearboxes.dual_clutch")
			DualClutch:SetClientData("DualClutch", "OnChange")
			DualClutch:DefineSetter(function(Panel, _, _, Value)
				Panel:SetValue(Value)
				timer.Simple(0, function()
					GearboxPreview:GetEntity():SetBodygroup(1, Value and 1 or 0)
				end)

				return Value
			end)
			Base:AddHelp("#acf.menu.gearboxes.dual_clutch_desc")
		else
			ACF.SetClientData("DualClutch", false)
			GearboxPreview:GetEntity():SetBodygroup(1, 0)
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
		--[[
		local Mass = ACF.GetProperMass(math.floor((Current.Mass * (Scale ^ ACF.GearboxMassScale)) / 5) * 5)

		-- Torque calculations
		local TorqueLoss = Current.MaxTorque * (ACF.GearEfficiency ^ Current.GearCount)
		local ScalingCurve = Scale ^ ACF.GearboxTorqueScale
		local MaxTorque = math.floor((TorqueLoss * ScalingCurve) / 10) * 10
		--local Torque = math.floor(Current.MaxTorque * 0.73 * Scale)
		GearboxStats:SetText(StatsText:format(Mass, MaxTorque * Scale, MaxTorque))
		]]
		GearboxList:UpdateSettings()
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

ACF.AddMenuItem(301, "Entities", "#acf.menu.gearboxes", "cog", CreateMenu)
