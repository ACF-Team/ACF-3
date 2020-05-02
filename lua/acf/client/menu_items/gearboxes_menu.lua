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

	ACF.SetToolMode("acf_menu2", "Main", "Spawner")

	function GearboxClass:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.Selected = Data

		local Choices = Sorted[Gearboxes]
		Selected[Choices] = Index

		ACF.WriteValue("GearboxClass", Data.ID)
		ACF.WriteValue("MaxGears", Data.Gears.Max)

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

	do -- Manual Gearbox Menu
		function ACF.ManualGearboxMenu(Class, Data, Menu)
			local Text = "Mass : %s\nTorque Rating : %s n/m - %s fl-lb"
			local Mass = ACF.GetProperMass(Data.Mass)
			local Gears = Class.Gears
			local Torque = math.floor(Data.MaxTorque * 0.73)

			Menu:AddLabel(Text:format(Mass, Data.MaxTorque, Torque))

			if Data.DualClutch then
				Menu:AddLabel("The dual clutch allows you to apply power and brake each side independently.")
			end

			-----------------------------------

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

					ValuesData[Variable] = Value

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

				ValuesData.FinalDrive = Value

				Panel:SetValue(Value)

				return Value
			end)
		end
	end

	do -- CVT Gearbox Menu
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
				Max = 9900,
				Decimals = 0,
				Default = 3000,
			},
			{
				Name = "Max Target RPM",
				Variable = "MaxRPM",
				Min = 101,
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

		function ACF.CVTGearboxMenu(Class, Data, Menu)
			local Text = "Mass : %s\nTorque Rating : %s n/m - %s fl-lb"
			local Mass = ACF.GetProperMass(Data.Mass)
			local Torque = math.floor(Data.MaxTorque * 0.73)

			Menu:AddLabel(Text:format(Mass, Data.MaxTorque, Torque))

			if Data.DualClutch then
				Menu:AddLabel("The dual clutch allows you to apply power and brake each side independently.")
			end

			-----------------------------------

			Menu:AddTitle("Gear Settings")

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
	end

	do -- Automatic Gearbox Menu
		local UnitMult = 10.936 -- km/h is set by default
		local AutoData = {
			{
				Name = "Reverse Gear",
				Variable = "Reverse",
				Min = -1,
				Max = 1,
				Decimals = 2,
				Default = -0.1,
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

		local GenData = {
			{
				Name = "Upshift RPM",
				Variable = "UpshiftRPM",
				Tooltip = "Target engine RPM to upshift at.",
				Min = 0,
				Max = 10000,
				Decimals = 0,
				Default = 5000,
			},
			{
				Name = "Total Ratio",
				Variable = "TotalRatio",
				Tooltip = "Total ratio is the ratio of all gearboxes (exluding this one) multiplied together.\nFor example, if you use engine to automatic to diffs to wheels, your total ratio would be (diff gear ratio * diff final ratio).",
				Min = 0,
				Max = 1,
				Decimals = 2,
				Default = 0.1,
			},
			{
				Name = "Wheel Diameter",
				Variable = "WheelDiameter",
				Tooltip = "If you use default spherical settings, add 0.5 to your wheel diameter.\nFor treaded vehicles, use the diameter of road wheels, not drive wheels.",
				Min = 0,
				Max = 1000,
				Decimals = 2,
				Default = 30,
			},
		}

		function ACF.AutomaticGearboxMenu(Class, Data, Menu)
			local Text = "Mass : %s\nTorque Rating : %s n/m - %s fl-lb"
			local Mass = ACF.GetProperMass(Data.Mass)
			local Gears = Class.Gears
			local Torque = math.floor(Data.MaxTorque * 0.73)

			Menu:AddLabel(Text:format(Mass, Data.MaxTorque, Torque))

			if Data.DualClutch then
				Menu:AddLabel("The dual clutch allows you to apply power and brake each side independently.")
			end

			-----------------------------------

			Menu:AddTitle("Gear Settings")

			Values[Class.ID] = Values[Class.ID] or {}

			local ValuesData = Values[Class.ID]

			Menu:AddLabel("Upshift Speed Unit :")

			ACF.WriteValue("ShiftUnit", UnitMult)

			local Unit = Menu:AddComboBox()
			Unit:AddChoice("KPH", 10.936)
			Unit:AddChoice("MPH", 17.6)
			Unit:AddChoice("GMU", 1)

			function Unit:OnSelect(_, _, Mult)
				if UnitMult == Mult then return end

				local Delta = UnitMult / Mult

				for I = math.max(1, Gears.Min), Gears.Max do
					local Var = "Shift" .. I
					local Old = ACF.ReadNumber(Var)

					ACF.WriteValue(Var, Old * Delta)
				end

				ACF.WriteValue("ShiftUnit", Mult)

				UnitMult = Mult
			end

			for I = math.max(1, Gears.Min), Gears.Max do
				local GearVar = "Gear" .. I
				local DefGear = ValuesData[GearVar]

				if not DefGear then
					DefGear = math.Clamp(I * 0.1, -1, 1)

					ValuesData[GearVar] = DefGear
				end

				ACF.WriteValue(GearVar, DefGear)

				local Gear = Menu:AddSlider("Gear " .. I, -1, 1, 2)
				Gear:SetDataVar(GearVar, "OnValueChanged")
				Gear:SetValueFunction(function(Panel)
					local Value = math.Round(ACF.ReadNumber(GearVar), 2)

					ValuesData[GearVar] = Value

					Panel:SetValue(Value)

					return Value
				end)

				local ShiftVar = "Shift" .. I
				local DefShift = ValuesData[ShiftVar]

				if not DefShift then
					DefShift = I * 10

					ValuesData[ShiftVar] = DefShift
				end

				ACF.WriteValue(ShiftVar, DefShift)

				local Shift = Menu:AddNumberWang("Gear " .. I .. " Upshift Speed", 0, 9999, 2)
				Shift:HideWang()
				Shift:SetDataVar(ShiftVar, "OnValueChanged")
				Shift:SetValueFunction(function(Panel)
					local Value = math.Round(ACF.ReadNumber(ShiftVar), 2)

					ValuesData[ShiftVar] = Value

					Panel:SetValue(Value)

					return Value
				end)
			end

			for _, GearData in ipairs(AutoData) do
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

			Unit:ChooseOptionID(1)

			-----------------------------------

			Menu:AddTitle("Shift Point Generator")

			for _, PanelData in ipairs(GenData) do
				local Variable = PanelData.Variable
				local Default = ValuesData[Variable]

				if not Default then
					Default = PanelData.Default

					ValuesData[Variable] = Default
				end

				ACF.WriteValue(Variable, Default)

				local Panel = Menu:AddNumberWang(PanelData.Name, PanelData.Min, PanelData.Max, PanelData.Decimals)
				Panel:HideWang()
				Panel:SetDataVar(Variable, "OnValueChanged")
				Panel:SetValueFunction(function()
					local Value = math.Round(ACF.ReadNumber(Variable), PanelData.Decimals)

					ValuesData[Variable] = Value

					Panel:SetValue(Value)

					return Value
				end)

				if PanelData.Tooltip then
					Panel:SetTooltip(PanelData.Tooltip)
				end
			end

			local Button = Menu:AddButton("Calculate")

			function Button:DoClickInternal()
				local UpshiftRPM = ValuesData.UpshiftRPM
				local TotalRatio = ValuesData.TotalRatio
				local FinalDrive = ValuesData.FinalDrive
				local WheelDiameter = ValuesData.WheelDiameter
				local Multiplier = math.pi * UpshiftRPM * TotalRatio * FinalDrive * WheelDiameter / (60 * UnitMult)

				for I = math.max(1, Gears.Min), Gears.Max do
					local Gear = ValuesData["Gear" .. I]

					ACF.WriteValue("Shift" .. I, Gear * Multiplier)
				end
			end
		end
	end
end
