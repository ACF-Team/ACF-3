local ACF = ACF
local ReceiveShame = GetConVar("acf_legalshame")

do -- Custom fonts
	surface.CreateFont("ACF_Title", {
		font = "Roboto",
		size = 18,
		weight = 850,
	})

	surface.CreateFont("ACF_Label", {
		font = "Roboto",
		size = 14,
		weight = 650,
	})

	surface.CreateFont("ACF_Control", {
		font = "Roboto",
		size = 14,
		weight = 550,
	})
end

do -- Networked notifications
	local notification = notification

	net.Receive("ACF_Notify", function()
		local Type = NOTIFY_ERROR

		if net.ReadBool() then
			Type = NOTIFY_GENERIC
		else
			surface.PlaySound("buttons/button10.wav")
		end

		notification.AddLegacy(net.ReadString(), Type, 7)
	end)

	net.Receive("ACF_NameAndShame", function()
		if not ReceiveShame:GetBool() then return end
		MsgN(net.ReadString())
	end)
end

do -- Panel helpers
	local Sorted = {}

	function ACF.LoadSortedList(Panel, List, Member)
		local Data = Sorted[List]

		if not Data then
			local Choices = {}
			local Count = 0

			for _, Value in pairs(List) do
				Count = Count + 1

				Choices[Count] = Value
			end

			table.SortByMember(Choices, Member, true)

			Data = {
				Choices = Choices,
				Index = 1,
			}

			Sorted[List] = Data
		end

		local Current = Data.Index

		Panel.ListData = Data

		Panel:Clear()

		for Index, Value in ipairs(Data.Choices) do
			Panel:AddChoice(Value.Name, Value, Index == Current)
		end
	end
end

do -- Default gearbox menus
	local Values = {}

	do -- Manual Gearbox Menu
		function ACF.ManualGearboxMenu(Class, Data, Menu, Base)
			local Text = "Mass : %s\nTorque Rating : %s n/m - %s fl-lb\n"
			local Mass = ACF.GetProperMass(Data.Mass)
			local Gears = Class.Gears
			local Torque = math.floor(Data.MaxTorque * 0.73)

			Base:AddLabel(Text:format(Mass, Data.MaxTorque, Torque))

			if Data.DualClutch then
				Base:AddLabel("The dual clutch allows you to apply power and brake each side independently.")
			end

			-----------------------------------

			local GearBase = Menu:AddCollapsible("Gear Settings")

			Values[Class.ID] = Values[Class.ID] or {}

			local ValuesData = Values[Class.ID]

			for I = 1, Gears.Max do
				local Variable = "Gear" .. I
				local Default = ValuesData[Variable]

				if not Default then
					Default = math.Clamp(I * 0.1, -1, 1)

					ValuesData[Variable] = Default
				end

				ACF.SetClientData(Variable, Default)

				local Control = GearBase:AddSlider("Gear " .. I, -1, 1, 2)
				Control:SetClientData(Variable, "OnValueChanged")
				Control:DefineSetter(function(Panel, _, _, Value)
					Value = math.Round(Value, 2)

					ValuesData[Variable] = Value

					Panel:SetValue(Value)

					return Value
				end)
			end

			if not ValuesData.FinalDrive then
				ValuesData.FinalDrive = 1
			end

			ACF.SetClientData("FinalDrive", ValuesData.FinalDrive)

			local FinalDrive = GearBase:AddSlider("Final Drive", -1, 1, 2)
			FinalDrive:SetClientData("FinalDrive", "OnValueChanged")
			FinalDrive:DefineSetter(function(Panel, _, _, Value)
				Value = math.Round(Value, 2)

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

		function ACF.CVTGearboxMenu(Class, Data, Menu, Base)
			local Text = "Mass : %s\nTorque Rating : %s n/m - %s fl-lb\n"
			local Mass = ACF.GetProperMass(Data.Mass)
			local Torque = math.floor(Data.MaxTorque * 0.73)

			Base:AddLabel(Text:format(Mass, Data.MaxTorque, Torque))

			if Data.DualClutch then
				Base:AddLabel("The dual clutch allows you to apply power and brake each side independently.")
			end

			-----------------------------------

			local GearBase = Menu:AddCollapsible("Gear Settings")

			Values[Class.ID] = Values[Class.ID] or {}

			local ValuesData = Values[Class.ID]

			ACF.SetClientData("Gear1", 0.01)

			for _, GearData in ipairs(CVTData) do
				local Variable = GearData.Variable
				local Default = ValuesData[Variable]

				if not Default then
					Default = GearData.Default

					ValuesData[Variable] = Default
				end

				ACF.SetClientData(Variable, Default)

				local Control = GearBase:AddSlider(GearData.Name, GearData.Min, GearData.Max, GearData.Decimals)
				Control:SetClientData(Variable, "OnValueChanged")
				Control:DefineSetter(function(Panel, _, _, Value)
					Value = math.Round(Value, GearData.Decimals)

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

		function ACF.AutomaticGearboxMenu(Class, Data, Menu, Base)
			local Text = "Mass : %s\nTorque Rating : %s n/m - %s fl-lb\n"
			local Mass = ACF.GetProperMass(Data.Mass)
			local Gears = Class.Gears
			local Torque = math.floor(Data.MaxTorque * 0.73)

			Base:AddLabel(Text:format(Mass, Data.MaxTorque, Torque))

			if Data.DualClutch then
				Base:AddLabel("The dual clutch allows you to apply power and brake each side independently.")
			end

			-----------------------------------

			local GearBase = Menu:AddCollapsible("Gear Settings")

			Values[Class.ID] = Values[Class.ID] or {}

			local ValuesData = Values[Class.ID]

			GearBase:AddLabel("Upshift Speed Unit :")

			ACF.SetClientData("ShiftUnit", UnitMult)

			local Unit = GearBase:AddComboBox()
			Unit:AddChoice("KPH", 10.936)
			Unit:AddChoice("MPH", 17.6)
			Unit:AddChoice("GMU", 1)

			function Unit:OnSelect(_, _, Mult)
				if UnitMult == Mult then return end

				local Delta = UnitMult / Mult

				for I = 1, Gears.Max do
					local Var = "Shift" .. I
					local Old = ACF.GetClientNumber(Var)

					ACF.SetClientData(Var, Old * Delta)
				end

				ACF.SetClientData("ShiftUnit", Mult)

				UnitMult = Mult
			end

			for I = 1, Gears.Max do
				local GearVar = "Gear" .. I
				local DefGear = ValuesData[GearVar]

				if not DefGear then
					DefGear = math.Clamp(I * 0.1, -1, 1)

					ValuesData[GearVar] = DefGear
				end

				ACF.SetClientData(GearVar, DefGear)

				local Gear = GearBase:AddSlider("Gear " .. I, -1, 1, 2)
				Gear:SetClientData(GearVar, "OnValueChanged")
				Gear:DefineSetter(function(Panel, _, _, Value)
					Value = math.Round(Value, 2)

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

				ACF.SetClientData(ShiftVar, DefShift)

				local Shift = GearBase:AddNumberWang("Gear " .. I .. " Upshift Speed", 0, 9999, 2)
				Shift:HideWang()
				Shift:SetClientData(ShiftVar, "OnValueChanged")
				Shift:DefineSetter(function(Panel, _, _, Value)
					Value = math.Round(Value, 2)

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

				ACF.SetClientData(Variable, Default)

				local Control = GearBase:AddSlider(GearData.Name, GearData.Min, GearData.Max, GearData.Decimals)
				Control:SetClientData(Variable, "OnValueChanged")
				Control:DefineSetter(function(Panel, _, _, Value)
					Value = math.Round(Value, GearData.Decimals)

					ValuesData[Variable] = Value

					Panel:SetValue(Value)

					return Value
				end)
			end

			Unit:ChooseOptionID(1)

			-----------------------------------

			local GenBase = Menu:AddCollapsible("Shift Point Generator")

			for _, PanelData in ipairs(GenData) do
				local Variable = PanelData.Variable
				local Default = ValuesData[Variable]

				if not Default then
					Default = PanelData.Default

					ValuesData[Variable] = Default
				end

				ACF.SetClientData(Variable, Default)

				local Panel = GenBase:AddNumberWang(PanelData.Name, PanelData.Min, PanelData.Max, PanelData.Decimals)
				Panel:HideWang()
				Panel:SetClientData(Variable, "OnValueChanged")
				Panel:DefineSetter(function(_, _, _, Value)
					Value = math.Round(Value, PanelData.Decimals)

					ValuesData[Variable] = Value

					Panel:SetValue(Value)

					return Value
				end)

				if PanelData.Tooltip then
					Panel:SetTooltip(PanelData.Tooltip)
				end
			end

			local Button = GenBase:AddButton("Calculate")

			function Button:DoClickInternal()
				local UpshiftRPM = ValuesData.UpshiftRPM
				local TotalRatio = ValuesData.TotalRatio
				local FinalDrive = ValuesData.FinalDrive
				local WheelDiameter = ValuesData.WheelDiameter
				local Multiplier = math.pi * UpshiftRPM * TotalRatio * FinalDrive * WheelDiameter / (60 * UnitMult)

				for I = 1, Gears.Max do
					local Gear = ValuesData["Gear" .. I]

					ACF.SetClientData("Shift" .. I, Gear * Multiplier)
				end
			end
		end
	end
end