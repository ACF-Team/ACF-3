local ACF = ACF

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
	local Messages = ACF.Utilities.Messages
	local ReceiveShame = GetConVar("acf_legalshame")

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
		Messages.PrintLog("Error", net.ReadString())
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

do -- Default turret menus
	local Turrets	= ACF.Classes.Turrets
	local TurretMassText	= "Drive Mass : %s kg, %s kg max capacity"
	local MassText	= "Mass : %s kg"

	do	-- Turret ring
		local TurretText	= "Teeth Count : %G"
		local HandCrankText	= "-- Handcrank --\n\nMax Speed : %G deg/s\nAcceleration : %G deg/s^2"

		local Orange	= Color(255, 127, 0)
		local Red		= Color(255, 0, 0)
		local Green		= Color(0, 255, 0)

		function ACF.CreateTurretMenu(Data, Menu)
			local TurretClass	= Turrets.Get("1-Turret")
			ACF.SetClientData("Turret", Data.ID)
			ACF.SetClientData("Destiny", "Turrets")
			ACF.SetClientData("PrimaryClass", "acf_turret")

			local TurretData	= {
				Ready		= false,
				TurretClass	= Data.ID,
				Teeth		= TurretClass.GetTeethCount(Data, Data.Size.Base),
				TotalMass	= 0,
				MaxMass		= 0,
				RingSize	= Data.Size.Base,
				RingHeight	= TurretClass.GetRingHeight({Type = "Turret-H", Ratio = Data.Size.Ratio}, Data.Size.Base),
				LocalCoM	= Vector(),
				Tilt		= 1
			}

			local RingSize	= Menu:AddSlider("Ring Diameter", Data.Size.Min, Data.Size.Max, 2)

			local MaxSpeed	= Menu:AddSlider("Max Speed (deg/s)", 0, 120, 2)

			Menu:AddLabel("If the Max Speed slider is lower than the calculated max speed of the turret, this will be the new limit. If 0, it will default to the actual max speed.")

			local RingStats	= Menu:AddLabel(TurretText:format(0, 0))
			local MassLbl	= Menu:AddLabel(MassText:format(0, 0))

			local ArcSettings	= Menu:AddCollapsible("Arc Settings")

			ArcSettings:AddLabel("If the total arc is less than 360, then it will use the limits set here.\nIf it is 360, then it will have free rotation.")

			local MinDeg	= ArcSettings:AddSlider("Minimum Degrees", -180, 0, 1)
			local MaxDeg	= ArcSettings:AddSlider("Maximum Degrees", 0, 180, 1)

			local ArcDraw = vgui.Create("Panel", ArcSettings)
			ArcDraw:SetSize(64, 64)
			ArcDraw:DockMargin(0, 0, 0, 10)
			ArcDraw:Dock(TOP)
			ArcDraw:InvalidateParent()
			ArcDraw:InvalidateLayout()
			ArcDraw.Paint = function(_, _, h)
				surface.DrawRect(0, 0, h, h)

				local Radius = (h / 2) - 2
				surface.DrawCircle(h / 2, h / 2, Radius, Color(65, 65, 65))

				local Min, Max = MinDeg:GetValue(), MaxDeg:GetValue()

				if Data.ID == "Turret-H" then
					surface.SetDrawColor(Orange)
					surface.DrawLine(h / 2, h / 2, h / 2, 1)

					surface.SetDrawColor(Red)
					local MinDegR = math.rad(Min - 90)
					local MinDegX, MinDegY = math.cos(MinDegR) * Radius, math.sin(MinDegR) * Radius
					surface.DrawLine(h / 2, h / 2, (h / 2) + MinDegX, (h / 2) + MinDegY)

					surface.SetDrawColor(Green)
					local MaxDegR = math.rad(Max - 90)
					local MaxDegX, MaxDegY = math.cos(MaxDegR) * Radius, math.sin(MaxDegR) * Radius
					surface.DrawLine(h / 2, h / 2, (h / 2) + MaxDegX, (h / 2) + MaxDegY)
				else -- Vertical turret drives
					surface.SetDrawColor(Orange)
					surface.DrawLine(h / 2, h / 2, h, h / 2)

					surface.SetDrawColor(Red)
					local MinDegR = math.rad(-Min)
					local MinDegX, MinDegY = math.cos(MinDegR) * Radius, math.sin(MinDegR) * Radius
					surface.DrawLine(h / 2, h / 2, (h / 2) + MinDegX, (h / 2) + MinDegY)

					surface.SetDrawColor(Green)
					local MaxDegR = math.rad(-Max)
					local MaxDegX, MaxDegY = math.cos(MaxDegR) * Radius, math.sin(MaxDegR) * Radius
					surface.DrawLine(h / 2, h / 2, (h / 2) + MaxDegX, (h / 2) + MaxDegY)
				end

				draw.SimpleTextOutlined("Zero", "ACF_Control", h + 4, 0, Orange, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1, color_black)
				if (Max - Min) ~= 360 then
					draw.SimpleTextOutlined("Minimum: " .. Min, "ACF_Control", h + 4, 16, Red, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1, color_black)
					draw.SimpleTextOutlined("Maximum: " .. Max, "ACF_Control", h + 4, 32, Green, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1, color_black)
					draw.SimpleTextOutlined("Total Arc: " .. (Max - Min), "ACF_Control", h + 4, 48, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1, color_black)
				else
					draw.SimpleTextOutlined("No Arc Limit", "ACF_Control", h + 4 , 16, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1, color_black)
				end
			end

			MinDeg:SetClientData("MinDeg", "OnValueChanged")
			MinDeg:DefineSetter(function(Panel, _, _, Value)
				local N = math.Clamp(math.Round(Value, 1), -180, 0)

				Panel:SetValue(N)

				return N
			end)
			MinDeg:SetValue(-180)

			MaxDeg:SetClientData("MaxDeg", "OnValueChanged")
			MaxDeg:DefineSetter(function(Panel, _, _, Value)
				local N = math.Clamp(math.Round(Value, 1), 0, 180)

				Panel:SetValue(N)

				return N
			end)
			MaxDeg:SetValue(180)

			if Data.ID == "Turret-V" then
				MinDeg:SetMin(-85)
				MaxDeg:SetMax(85)

				MinDeg:SetValue(-85)
				MaxDeg:SetValue(85)

				ACF.SetClientData("MinDeg", -85)
				ACF.SetClientData("MaxDeg", 85)
			else
				ACF.SetClientData("MinDeg", -180)
				ACF.SetClientData("MaxDeg", 180)
			end

			local EstMass	= Menu:AddSlider("Est. Mass (kg)", 0, 100000, 0)

			local EstDist	= Menu:AddSlider("Mass Center Dist.", 0, 2, 2)

			Menu:AddLabel("Approximation of the turret's speed with a handcrank.")
			local HandCrankLbl	= Menu:AddLabel(HandCrankText:format(0, 0))

			local Graph		= Menu:AddGraph()
			local GraphSize	= Menu:GetParent():GetParent():GetWide()
			Graph:SetSize(GraphSize, GraphSize / 2)
			Graph:SetXLabel("Estimated Mass (kg)")
			Graph:SetYLabel("Degrees/Sec")
			Graph:SetXRange(0, 100000)
			Graph:SetXSpacing(10000)
			Graph:SetYSpacing(5)

			HandCrankLbl.UpdateSim = function(Panel)
				if TurretData.Ready == false then return end

				local Info = TurretClass.CalcSpeed(TurretData, TurretClass.HandGear)

				Panel:SetText(HandCrankText:format(math.Round(Info.MaxSlewRate, 2), math.Round(Info.SlewAccel, 4)))

				local SimTurretData = {
					LocalCoM	= TurretData.LocalCoM,
					RingSize	= TurretData.RingSize,
					RingHeight	= TurretData.RingHeight,
					Teeth		= TurretData.Teeth,
					Tilt		= 1,
					TurretClass	= TurretData.TurretClass,
					TotalMass	= 0,
					MaxMass		= TurretData.MaxMass,
				}

				local Points	= {}

				for I = 1, 101 do
					local Mass = 1000 * (I - 1)
					SimTurretData.TotalMass = Mass

					Points[I] = {x = Mass, y = TurretClass.CalcSpeed(SimTurretData, TurretClass.HandGear).MaxSlewRate}
				end

				Graph:SetYRange(0, Points[1].y * 1.1)

				Graph:Clear()
				Graph:PlotTable("Slew Rate", Points, Color(65, 65, 200))

				Graph:PlotPoint("Estimate", TurretData.TotalMass, Info.MaxSlewRate, Color(65, 65, 200))
			end

			RingSize:SetClientData("RingSize", "OnValueChanged")
			RingSize:DefineSetter(function(Panel, _, _, Value)
				local N = Value

				Panel:SetValue(N)

				local Teeth = TurretClass.GetTeethCount(Data, N)
				RingStats:SetText(TurretText:format(Teeth))
				local MaxMass = TurretClass.GetMaxMass(Data, N)
				MassLbl:SetText(TurretMassText:format(TurretClass.GetMass(Data, N), MaxMass))

				TurretData.Teeth		= Teeth
				TurretData.RingSize		= N
				TurretData.RingHeight	= TurretClass.GetRingHeight({Type = Data.ID, Ratio = Data.Size.Ratio}, N)
				TurretData.MaxMass		= MaxMass

				EstDist:SetMinMax(0, math.max(N * 2, 24))
				MaxSpeed:SetValue(0)

				HandCrankLbl:UpdateSim()

				return N
			end)

			MaxSpeed:SetClientData("MaxSpeed", "OnValueChanged")
			MaxSpeed:DefineSetter(function(Panel, _, _, Value)
				local N = Value

				Panel:SetValue(N)

				return N
			end)

			EstMass.OnValueChanged = function(_, Value)
				TurretData.TotalMass = Value

				HandCrankLbl:UpdateSim()
			end

			EstDist.OnValueChanged = function(_, Value)
				TurretData.LocalCoM = Vector(Value, 0, Value)

				HandCrankLbl:UpdateSim()
			end

			RingSize:SetValue(Data.Size.Base)
			EstMass:SetValue(0)
			EstDist:SetValue(0)
			MaxSpeed:SetValue(0)

			TurretData.Ready	= true
			HandCrankLbl:UpdateSim()
		end
	end

	do	-- Turret Motors
		local TurretData = {
			Ready		= false,
			Mass		= 0,
			TurretType	= "Turret-H",
			TurretTeeth	= 0,
			MotorTeeth	= 0,
			Torque		= 0,
			Distance	= 0,
			HandSim		= 0,
			MotorSim	= 0
		}

		local TorqText	= "Torque : %G Nm"
		local HandcrankText = "-- Handcrank --\n\nMax Speed : %G deg/s\nAcceleration : %G deg/s^2"
		local MotorText	= "-- Motor --\n\nMax Speed : %G deg/s\nAcceleration : %G deg/s^2"

		function ACF.CreateTurretMotorMenu(Data, Menu)
			local MotorClass	= Turrets.Get("2-Motor")
			local TurretClass	= Turrets.Get("1-Turret")

			ACF.SetClientData("Motor", Data.ID)
			ACF.SetClientData("Destiny", "TurretMotors")
			ACF.SetClientData("PrimaryClass", "acf_turret_motor")

			Menu:AddLabel("Motor Speed : " .. Data.Speed .. " RPM")

			local CompSize	= Menu:AddSlider("Motor Scale (" .. Data.ScaleLimit.Min .. "-" .. Data.ScaleLimit.Max .. ")", Data.ScaleLimit.Min, Data.ScaleLimit.Max, 1)

			Menu:AddLabel("Determines the number of teeth of the gear on the motor.")
			local TeethAmt	= Menu:AddSlider("Gear Teeth (" .. Data.Teeth.Min .. "-" .. Data.Teeth.Max .. ")", Data.Teeth.Min, Data.Teeth.Max, 0)

			local MassLbl	= Menu:AddLabel(TurretMassText:format(0, 0))
			local TorqLbl	= Menu:AddLabel(TorqText:format(0))

			-- Simulation

			local TurretSim = Menu:AddCollapsible("Turret Simulation")
			TurretSim:AddLabel("These values are only an approximation!")

			local TurretType = TurretSim:AddComboBox()

			local TurretSize = TurretSim:AddSlider("Turret Size", 0, 1, 2)

			local EstMass = TurretSim:AddSlider("Est. Mass (kg)", 0, 100000, 1)

			local EstDist = TurretSim:AddSlider("Mass Center Dist.", 0, 2, 2)

			local MaxMassLbl	= TurretSim:AddLabel("Max mass: 0kg")

			local Graph		= Menu:AddGraph()
			local GraphSize	= Menu:GetParent():GetParent():GetWide()
			Graph:SetSize(GraphSize, GraphSize / 2)
			Graph:SetXLabel("Estimated Mass (kg)")
			Graph:SetYLabel("Degrees/Sec")
			Graph:SetXRange(0, 100000)
			Graph:SetXSpacing(10000)
			Graph:SetYSpacing(5)

			Graph.Replot = function(self)
				self:Clear()

				local SimTurretData = {
					LocalCoM	= Vector(TurretData.Distance, 0, TurretData.Distance),
					RingSize	= TurretData.Size,
					RingHeight	= TurretData.RingHeight,
					Teeth		= TurretData.TurretTeeth,
					Tilt		= 1,
					TurretClass	= TurretData.Type,
					TotalMass	= 0,
					MaxMass		= TurretData.MaxMass,
				}

				local SimMotorData = {
					Teeth	= TurretData.MotorTeeth,
					Speed	= Data.Speed,
					Torque	= TurretData.Torque,
					Efficiency	= Data.Efficiency,
					Accel	= Data.Accel
				}

				local HandCrankPoints	= {}
				local MotorPoints		= {}

				for I = 1, 101 do
					local Mass = 1000 * (I - 1)
					SimTurretData.TotalMass = Mass

					HandCrankPoints[I] = {x = Mass, y = TurretClass.CalcSpeed(SimTurretData, TurretClass.HandGear).MaxSlewRate}
					MotorPoints[I] = {x = Mass, y = TurretClass.CalcSpeed(SimTurretData, SimMotorData).MaxSlewRate}
				end

				self:SetYRange(0, math.max(MotorPoints[1].y, HandCrankPoints[1].y) * 1.1)

				self:PlotTable("Hand Rate", HandCrankPoints, Color(65, 65, 200))
				self:PlotPoint("Hand Estimate", TurretData.Mass, TurretData.HandSim, Color(65, 65, 200))

				self:PlotTable("Motor Rate", MotorPoints, Color(200, 65, 65))
				self:PlotPoint("Motor Estimate", TurretData.Mass, TurretData.MotorSim, Color(200, 65, 65))
			end

			local HandcrankInfo	= TurretSim:AddLabel(HandcrankText:format(0, 0))
			HandcrankInfo.UpdateSim = function(Panel)
				if TurretData.Ready == false then return end

				local Info = TurretClass.CalcSpeed({Tilt = 1, TotalMass = TurretData.Mass, MaxMass = TurretData.MaxMass, RingSize = TurretData.Size, Teeth = TurretData.TurretTeeth, TurretClass = TurretData.Type, LocalCoM = Vector(TurretData.Distance, 0, TurretData.Distance), RingHeight = TurretData.RingHeight},
				TurretClass.HandGear)

				Panel:SetText(HandcrankText:format(math.Round(Info.MaxSlewRate, 2), math.Round(Info.SlewAccel, 4)))

				TurretData.HandSim = Info.MaxSlewRate
				Graph:Replot()
			end

			local MotorInfo	= TurretSim:AddLabel(MotorText:format(0, 0))
			MotorInfo.UpdateSim = function(Panel)
				if TurretData.Ready == false then return end

				local Info = TurretClass.CalcSpeed({Tilt = 1, TotalMass = TurretData.Mass, MaxMass = TurretData.MaxMass, RingSize = TurretData.Size, Teeth = TurretData.TurretTeeth, TurretClass = TurretData.Type, LocalCoM = Vector(TurretData.Distance, 0, TurretData.Distance), RingHeight = TurretData.RingHeight},
				{Teeth = TurretData.MotorTeeth, Speed = Data.Speed, Torque = TurretData.Torque, Efficiency = Data.Efficiency, Accel	= Data.Accel})

				Panel:SetText(MotorText:format(math.Round(Info.MaxSlewRate, 2), math.Round(Info.SlewAccel, 4)))

				TurretData.MotorSim = Info.MaxSlewRate
				Graph:Replot()
			end

			-- Updating functions

			CompSize:SetClientData("CompSize", "OnValueChanged")
			CompSize:DefineSetter(function(Panel, _, _, Value)
				local N = math.Clamp(math.Round(Value, 1), Data.ScaleLimit.Min, Data.ScaleLimit.Max)

				Panel:SetValue(N)

				local SizePerc = N ^ 2
				MassLbl:SetText(MassText:format(math.Round(math.max(Data.Mass * SizePerc, 5), 1)))

				TurretData.Torque	= MotorClass.GetTorque(Data, N)
				TorqLbl:SetText(TorqText:format(TurretData.Torque))

				MotorInfo:UpdateSim()

				return N
			end)
			CompSize:SetValue(1)

			TeethAmt:SetClientData("Teeth", "OnValueChanged")
			TeethAmt:DefineSetter(function(Panel, _, _, Value)
				local N = math.Clamp(math.Round(Value), Data.Teeth.Min, Data.Teeth.Max)

				Panel:SetValue(N)

				TurretData.MotorTeeth = N

				MotorInfo:UpdateSim()

				return N
			end)
			TeethAmt:SetValue(Data.Teeth.Base)

			TurretSize.OnValueChanged = function(_, Value)
				TurretData.Size			= Value
				TurretData.RingHeight	= TurretClass.GetRingHeight({Type = TurretData.Turret, Ratio = TurretData.Turret.Size.Ratio}, Value)
				TurretData.TurretTeeth	= TurretClass.GetTeethCount(TurretData.Turret, Value)
				TurretData.MaxMass		= TurretClass.GetMaxMass(TurretData.Turret, Value)

				EstDist:SetMinMax(0, math.max(Value * 2, 24))
				MaxMassLbl:SetText("Max mass: " .. math.Round(TurretData.MaxMass, 1) .. "kg")

				MotorInfo:UpdateSim()
				HandcrankInfo:UpdateSim()
			end

			EstMass.OnValueChanged = function(_, Value)
				TurretData.Mass = Value

				MotorInfo:UpdateSim()
				HandcrankInfo:UpdateSim()
			end

			EstDist.OnValueChanged = function(_, Value)
				TurretData.Distance = Value

				MotorInfo:UpdateSim()
				HandcrankInfo:UpdateSim()
			end

			function TurretType:OnSelect(_, _, Turret)
				if self.Selected == Data then return end

				TurretData.Ready		= false

				TurretData.Type			= Turret.ID
				TurretData.Turret		= Turret
				TurretData.MotorTeeth	= TeethAmt:GetValue()

				EstMass:SetValue(0)
				EstDist:SetValue(0)

				TurretSize:SetMinMax(Turret.Size.Min, Turret.Size.Max)
				TurretSize:SetValue(Turret.Size.Base)

				TurretData.Ready		= true

				HandcrankInfo:UpdateSim()
				MotorInfo:UpdateSim()
			end

			ACF.LoadSortedList(TurretType, Turrets.GetItemEntries("1-Turret"), "ID")
		end
	end

	do	-- Turret Gyroscopes
		function ACF.CreateTurretGyroMenu(Data, Menu)
			ACF.SetClientData("Gyro", Data.ID)
			ACF.SetClientData("Destiny", "TurretGyros")
			ACF.SetClientData("PrimaryClass", "acf_turret_gyro")

			Menu:AddLabel(MassText:format(Data.Mass))

			if Data.IsDual then
				Menu:AddLabel("Can control both a horizontal and vertical turret drive.")
			end
		end
	end

	do	-- Turret Computers
		function ACF.CreateTurretComputerMenu(Data, Menu)
			ACF.SetClientData("Computer", Data.ID)
			ACF.SetClientData("Destiny", "TurretComputers")
			ACF.SetClientData("PrimaryClass", "acf_turret_computer")

			Menu:AddLabel(MassText:format(Data.Mass))
		end
	end
end

do -- Link distance gizmo stuff
	local EntGizmoDifferences = {}

	local ColorLinkOk             = Color(55, 235, 55, 255)
	local ColorLinkFail           = Color(255, 88, 88)
	local ColorLinkFailDistMissed = Color(255, 200, 81)
	local ColorLink               = Color(205, 235, 255, 255)

	function ACF.ToolCL_RegisterLinkGizmoData(From, To, Callback)
		EntGizmoDifferences[From] = EntGizmoDifferences[From] or {}
		EntGizmoDifferences[To] = EntGizmoDifferences[To] or {}

		EntGizmoDifferences[From][To] = Callback
		EntGizmoDifferences[To][From] = Callback
	end

	function ACF.ToolCL_GetLinkGizmoData(EntFrom, EntTo)
		local FromTbl = EntGizmoDifferences[EntFrom:GetClass()]
		if not FromTbl then return end

		local ToTbl = FromTbl[EntTo:GetClass()]
		if not ToTbl then return end

		return true, ToTbl(EntFrom, EntTo)
	end

	function ACF.ToolCL_CanLink(From, To)
		if not IsValid(From) then return false, "Link target not valid!" end
		if not IsValid(To) then return false, "Target not valid!" end

		if From == To then return false, "Cannot link an entity to itself!" end

		local HadData, CanLink, WhyNot, RenderData = ACF.ToolCL_GetLinkGizmoData(From, To)
		if not HadData then return false, "No link data." end
		return CanLink == nil and true or CanLink, WhyNot, RenderData
	end

	local LinkDistanceTooFar = {
		Text = "The entity is too far away.",
		Renderer = function(Data)
			local FromPos, ToPos = Data.FromPos, Data.ToPos
			local Normal         = (ToPos - FromPos):GetNormalized()
			local ToMaxDist      = FromPos + (Normal * Data.MaxDist)

			render.SetColorMaterial()
			render.DepthRange(0, 0)
			render.DrawBeam(FromPos, ToMaxDist, 2, 0, 1, color_black)
			render.DrawBeam(ToMaxDist, ToPos, 2, 0, 1, color_black)
			render.DrawBeam(FromPos, ToMaxDist, 1, 0, 1, ColorLinkFailDistMissed)
			render.DrawBeam(ToMaxDist, ToPos, 1, 0, 1, ColorLinkFail)
			render.DepthRange(0, 1)
		end
	}

	local function GenericLinkDistanceCheck(From, To)
		local FromPos, ToPos = From:GetPos(), To:GetPos()
		local Dist    = FromPos:Distance(ToPos)
		local MaxDist = ACF.LinkDistance
		if Dist > MaxDist then return false, LinkDistanceTooFar, {FromPos = FromPos, ToPos = ToPos, Dist = Dist, MaxDist = MaxDist} end
	end

	local function MobilityLinkDistanceCheck(From, To)
		local FromPos, ToPos = From:GetPos(), To:GetPos()
		local Dist    = FromPos:Distance(ToPos)
		local MaxDist = ACF.MobilityLinkDistance
		if Dist > MaxDist then return false, LinkDistanceTooFar, {FromPos = FromPos, ToPos = ToPos, Dist = Dist, MaxDist = MaxDist} end
	end

	local function AlwaysLinkableCheck()
		return true
	end

	ACF.ToolCL_RegisterLinkGizmoData("acf_ammo", "acf_gun", GenericLinkDistanceCheck)
	ACF.ToolCL_RegisterLinkGizmoData("acf_ammo", "acf_rack", GenericLinkDistanceCheck)
	ACF.ToolCL_RegisterLinkGizmoData("acf_turret", "acf_turret_motor", GenericLinkDistanceCheck) -- TODO: Make this use the actual link distance check used in turrets
	ACF.ToolCL_RegisterLinkGizmoData("acf_turret", "acf_turret_gyro", GenericLinkDistanceCheck)

	ACF.ToolCL_RegisterLinkGizmoData("acf_engine", "acf_gearbox", function(From, To)
		--[[
		local Out = From.Out

		if From:GetClass() == "acf_gearbox" then
			local InPos = To.In and To.In.Pos or Vector()
			local InPosWorld = To:LocalToWorld(InPos)

			Out = From:WorldToLocal(InPosWorld).y < 0 and From.OutL or From.OutR
		end

		if ACF.IsDriveshaftAngleExcessive(To, To.In, From, Out) then
			return false, { Text = "The driveshaft angle is excessive." }, {FromPos = From:GetPos(), ToPos = To:GetPos()}
		end
		]]
		return MobilityLinkDistanceCheck(From, To)
	end)

	ACF.ToolCL_RegisterLinkGizmoData("acf_engine", "acf_fueltank", MobilityLinkDistanceCheck)

	ACF.ToolCL_RegisterLinkGizmoData("acf_gun", "acf_turret_computer", AlwaysLinkableCheck)
	ACF.ToolCL_RegisterLinkGizmoData("acf_gun", "acf_computer", AlwaysLinkableCheck)
	ACF.ToolCL_RegisterLinkGizmoData("acf_rack", "acf_computer", AlwaysLinkableCheck)
	ACF.ToolCL_RegisterLinkGizmoData("acf_rack", "acf_radar", AlwaysLinkableCheck)

	local HUDText = {}

	local function DrawText(Text, Color, X, Y)
		if not Y then
			local XY = X:ToScreen()
			X, Y = XY.x, XY.y
		end

		HUDText[#HUDText + 1] = {Text = Text, X = X, Y = Y, Color = Color}
	end

	local DistText   = "Distance: %.1f units"
	local DistTextOK = "✓ OK"
	local DistTextNo = "✗ Cannot link: %s"

	hook.Add("PostDrawTranslucentRenderables", "ACF_PostDrawTranslucentRenderables_LinkDistanceVis", function()
		if not ACF.ToolCL_InLinkState() then return end
		table.Empty(HUDText)

		local LocalPly        = LocalPlayer()
		local PlayerPos       = LocalPly:GetPos()
		local EyeTrace        = LocalPly:GetEyeTrace()
		local LookEnt         = EyeTrace.Entity
		local LookPos         = EyeTrace.HitPos
		local LookingAtEntity = IsValid(LookEnt)
		local LinkEnts        = ACF.ToolCL_GetLinkedEnts()

		for Ent in pairs(LinkEnts) do
			if IsValid(Ent) then
				local TargPos = LookingAtEntity and LookEnt:GetPos() or LookPos
				local EntPos  = Ent:GetPos()

				local Dist = EntPos:Distance(TargPos)
				local PlayerToTarget = math.Clamp(PlayerPos:Distance(TargPos) / 1.5, 0, Dist / 2)
				local InBetween = TargPos + ((EntPos - TargPos):GetNormalized() * math.Clamp(Dist, 0, PlayerToTarget))

				local LinkColor = ColorLink
				local RenderOverride, RenderData

				if LookingAtEntity then
					local CanLink, Why, Data = ACF.ToolCL_CanLink(Ent, LookEnt, Dist)
					LinkColor = CanLink and ColorLinkOk or ColorLinkFail
					local linkText = CanLink and DistTextOK or DistTextNo:format(Why.Text and Why.Text or Why)
					if not CanLink then
						RenderOverride = Why.Renderer
						RenderData = Data
					end
					DrawText(linkText, LinkColor, InBetween)
				else
					DrawText(DistText:format(Dist), LinkColor, InBetween)
				end

				if RenderOverride then
					RenderOverride(RenderData, From, To)
				else
					render.SetColorMaterial()
					render.DepthRange(0, 0)
					render.DrawBeam(EntPos, TargPos, 2, 0, 1, color_black)
					render.DrawBeam(EntPos, TargPos, 1, 0, 1, LinkColor)
					render.DepthRange(0, 1)
				end
			end
		end
	end)

	hook.Add("HUDPaint", "ACF_HUDPaint_LinkDistanceVis", function()
		if not ACF.ToolCL_InLinkState() then return end

		local W, H = ScrW(), ScrH()
		local Padding = 16

		for _, V in ipairs(HUDText) do
			surface.SetFont("ACF_Title")
			local TX, TY = surface.GetTextSize(V.Text)
			TX = TX / 2
			TY = TY / 2
			local X, Y = math.Clamp(V.X, TX + Padding, W - TX - Padding), math.Clamp(V.Y, TY + Padding, H - TY - Padding)

			draw.SimpleTextOutlined(V.Text, "ACF_Title", X, Y, V.Color or color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, color_black)
		end
	end)
end