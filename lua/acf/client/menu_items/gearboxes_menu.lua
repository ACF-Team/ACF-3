local Gearboxes = ACF.Classes.Gearboxes
local Selected = {}
local Sorted = {}

local function LoadSortedList(Panel, List, Member)
	local Choices = Sorted[List]

	if not Choices then
		Choices = {}

		local Count = 0
		for _, V in pairs(List) do
			Count = Count + 1
			Choices[Count] = V
		end

		table.SortByMember(Choices, Member, true)

		Sorted[List] = Choices
		Selected[Choices] = 1
	end

	Panel:Clear()

	for _, V in pairs(Choices) do
		Panel:AddChoice(V.Name, V)
	end

	Panel:ChooseOptionID(Selected[Choices])
end

local function CreateMenu(Menu)
	local GearboxClass = Menu:AddComboBox()
	local GearboxList = Menu:AddComboBox()
	local GearboxName = Menu:AddTitle()
	local GearboxDesc = Menu:AddLabel()

	ACF.WriteValue("PrimaryClass", "acf_gearbox")
	ACF.WriteValue("SecondaryClass", "N/A")

	function GearboxClass:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.Selected = Data

		local Choices = Sorted[Gearboxes]
		Selected[Choices] = Index

		ACF.WriteValue("GearboxClass", Data.ID)

		LoadSortedList(GearboxList, Data.Items, "ID")
	end

	function GearboxList:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.Selected = Data

		local ClassData = GearboxClass.Selected
		local Choices = Sorted[ClassData.Items]
		Selected[Choices] = Index

		ACF.WriteValue("Gearbox", Data.ID)

		GearboxName:SetText(Data.Name)
		GearboxDesc:SetText(Data.Description)

		Menu:ClearTemporal(self)
		Menu:StartTemporal(self)

		if ClassData.CreateMenu then
			ClassData:CreateMenu(Data, Menu)
		end

		Menu:EndTemporal(self)
	end

	LoadSortedList(GearboxClass, Gearboxes, "ID")
end

ACF.AddOptionItem("Entities", "Gearboxes", "cog", CreateMenu)

do -- Default Menus
	local Values = {}
	local CVTData = {
		{
			Name = "Gear 2",
			Variable = "Gear2",
			Min = -1,
			Max = 1,
			Decimals = 2,
			Default = -0.1,
		},
		{
			Name = "Min Target RPM",
			Variable = "MinRPM",
			Min = 1,
			Max = 10000,
			Decimals = 0,
			Default = 3000,
		},
		{
			Name = "Max Target RPM",
			Variable = "MaxRPM",
			Min = 1,
			Max = 10000,
			Decimals = 0,
			Default = 5000,
		},
		{
			Name = "Final Drive",
			Variable = "FinalDrive",
			Min = -1,
			Max = 1,
			Decimals = 2,
			Default = 1,
		},
	}

	function ACF.ManualGearboxMenu(Class, Data, Menu)
		local Text = "Mass : %s\nDefault Gear : Gear %s\nTorque Rating : %s n/m - %s fl-lb"
		local Mass = ACF.GetProperMass(Data.Mass)
		local Gears = Class.Gears
		local Torque = math.floor(Data.MaxTorque * 0.73)

		Menu:AddLabel(Text:format(Mass, Gears.Default or Gears.Min, Data.MaxTorque, Torque))

		if Data.DualClutch then
			Menu:AddLabel("The dual clutch allows you to apply power and brake each side independently.")
		end

		Menu:AddTitle("Gear Settings")

		Values[Class.ID] = Values[Class.ID] or {}

		local ValuesData = Values[Class.ID]

		for I = math.max(1, Gears.Min), Gears.Max do
			local Variable = "Gear" .. I
			local Default = ValuesData[Variable]

			if not Default then
				Default = math.Clamp(I * 0.1, -1, 1)

				ValuesData[Variable] = Default
			end

			ACF.WriteValue(Variable, Default)

			local Control = Menu:AddSlider("Gear " .. I, -1, 1, 2)
			Control:SetDataVar(Variable, "OnValueChanged")
			Control:SetValueFunction(function(Panel)
				local Value = math.Round(ACF.ReadNumber(Variable), 2)

				if ValuesData[Variable] then
					ValuesData[Variable] = Value
				end

				Panel:SetValue(Value)

				return Value
			end)
		end

		if not ValuesData.FinalDrive then
			ValuesData.FinalDrive = 1
		end

		ACF.WriteValue("FinalDrive", ValuesData.FinalDrive)

		local FinalDrive = Menu:AddSlider("Final Drive", -1, 1, 2)
		FinalDrive:SetDataVar("FinalDrive", "OnValueChanged")
		FinalDrive:SetValueFunction(function(Panel)
			local Value = math.Round(ACF.ReadNumber("FinalDrive"), 2)

			if ValuesData.FinalDrive then
				ValuesData.FinalDrive = Value
			end

			Panel:SetValue(Value)

			return Value
		end)
	end

	function ACF.CVTGearboxMenu(Class, Data, Menu)
		local Text = "Mass : %s\nDefault Gear : Gear %s\nTorque Rating : %s n/m - %s fl-lb"
		local Mass = ACF.GetProperMass(Data.Mass)
		local Gears = Class.Gears
		local Torque = math.floor(Data.MaxTorque * 0.73)

		Menu:AddLabel(Text:format(Mass, Gears.Default or Gears.Min, Data.MaxTorque, Torque))

		if Data.DualClutch then
			Menu:AddLabel("The dual clutch allows you to apply power and brake each side independently.")
		end

		Values[Class.ID] = Values[Class.ID] or {}

		local ValuesData = Values[Class.ID]

		ACF.WriteValue("Gear1", 0.01)

		for _, GearData in ipairs(CVTData) do
			local Variable = GearData.Variable
			local Default = ValuesData[Variable]

			if not Default then
				Default = GearData.Default

				ValuesData[Variable] = Default
			end

			ACF.WriteValue(Variable, Default)

			local Control = Menu:AddSlider(GearData.Name, GearData.Min, GearData.Max, GearData.Decimals)
			Control:SetDataVar(Variable, "OnValueChanged")
			Control:SetValueFunction(function(Panel)
				local Value = math.Round(ACF.ReadNumber(Variable), GearData.Decimals)

				ValuesData[Variable] = Value

				Panel:SetValue(Value)

				return Value
			end)
		end
	end

	--function ACF.AutomaticGearboxMenu(Class, Data, Menu)

	--end
end
