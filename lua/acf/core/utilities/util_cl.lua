local ACF = ACF

do -- Custom fonts
	surface.CreateFont("ACF_Title", {
		font = "Roboto",
		size = 18,
		weight = 850,
		antialias = true,
	})

	surface.CreateFont("ACF_Label", {
		font = "Roboto",
		size = 14,
		weight = 650,
		antialias = true,
	})

	surface.CreateFont("ACF_Control", {
		font = "Roboto",
		size = 14,
		weight = 550,
		antialias = true,
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
				if Value.SuppressLoad then continue end

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

	--- Initializes the base menu panel for an ACF tool menu.
	--- @param Panel panel The base panel to build the menu off of.
	--- @param GlobalID string The identifier in the ACF global table where a reference to the menu panel should be stored.
	--- @param ReloadCommand? string A concommand string to automatically add a button and concommand to refresh this menu.
	function ACF.InitMenuBase(Panel, GlobalID, ReloadCommand)
		if not IsValid(Panel) or not isstring(GlobalID) then return end

		local Menu = ACF[GlobalID]

		-- MARCH: Adjusted this to remove the old panel and recreate it, rather than calling ClearAllTemporal/ClearAll
		-- Because otherwise auto-refresh doesn't work.
		-- If that breaks something else sorry, but we need something that allows auto-refresh to work so don't just revert this
		if IsValid(Menu) then
			Menu:Remove()
			Menu = nil
		end

		Menu = vgui.Create("ACF_Panel")
		Menu.Panel = Panel

		Panel:AddItem(Menu)

		ACF[GlobalID] = Menu

		if ReloadCommand then
			concommand.Add(ReloadCommand, function()
				if not IsValid(ACF[GlobalID]) then return end

				local CreateMenuFunc = ACF["Create" .. GlobalID]
				CreateMenuFunc(ACF[GlobalID].Panel)
			end)
		end

		if ReloadCommand then
			Menu:AddMenuReload(ReloadCommand)
		end

		return Menu
	end
end

do -- Default gearbox menus
	local Values = {}

	do -- Manual Gearbox Menu
		function ACF.ManualGearboxMenu(Class, _, Menu, _)
			local Gears = Class.CanSetGears and ACF.GetClientNumber("GearAmount", 3) or Class.Gears.Max
			local GearBase = Menu:AddCollapsible("#acf.menu.gearboxes.gear_settings", nil, "icon16/cog_edit.png")

			Values[Class.ID] = Values[Class.ID] or {}

			local ValuesData = Values[Class.ID]

			for I = 1, Gears do
				local Variable = "Gear" .. I
				local Default = ValuesData[Variable]

				if not Default then
					Default = math.Clamp(I * 0.1, ACF.MinGearRatio, ACF.MaxGearRatio)

					ValuesData[Variable] = Default
				end

				ACF.SetClientData(Variable, Default)

				local SliderName = language.GetPhrase("acf.menu.gearboxes.gear_number"):format(I)
				local Control = GearBase:AddSlider(SliderName, ACF.MinGearRatio, ACF.MaxGearRatio, 2)
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

			local FinalDrive = GearBase:AddSlider("#acf.menu.gearboxes.final_drive", ACF.MinGearRatio, ACF.MaxGearRatio, 2)
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
				Name = language.GetPhrase("acf.menu.gearboxes.gear_number"):format(2),
				Variable = "Gear2",
				Min = ACF.MinGearRatio,
				Max = ACF.MaxGearRatio,
				Decimals = 2,
				Default = -1,
			},
			{
				Name = "#acf.menu.gearboxes.min_target_rpm",
				Variable = "MinRPM",
				Min = 1,
				Max = 9900,
				Decimals = 0,
				Default = 3000,
			},
			{
				Name = "#acf.menu.gearboxes.max_target_rpm",
				Variable = "MaxRPM",
				Min = 101,
				Max = 10000,
				Decimals = 0,
				Default = 5000,
			},
			{
				Name = "#acf.menu.gearboxes.final_drive",
				Variable = "FinalDrive",
				Min = ACF.MinGearRatio,
				Max = ACF.MaxGearRatio,
				Decimals = 2,
				Default = 1,
			},
		}

		function ACF.CVTGearboxMenu(Class, _, Menu, _)
			local GearBase = Menu:AddCollapsible("#acf.menu.gearboxes.gear_settings", nil, "icon16/cog_edit.png")

			Values[Class.ID] = Values[Class.ID] or {}

			local ValuesData = Values[Class.ID]

			ACF.SetClientData("Gear1", 1)

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
				Name = "#acf.menu.gearboxes.reverse_gear",
				Variable = "Reverse",
				Min = ACF.MinGearRatio,
				Max = ACF.MaxGearRatio,
				Decimals = 2,
				Default = -1,
			},
			{
				Name = "#acf.menu.gearboxes.final_drive",
				Variable = "FinalDrive",
				Min = ACF.MinGearRatio,
				Max = ACF.MaxGearRatio,
				Decimals = 2,
				Default = 1,
			},
		}

		local GenData = {
			{
				Name = "#acf.menu.gearboxes.upshift_rpm",
				Variable = "UpshiftRPM",
				Tooltip = "#acf.menu.gearboxes.upshift_rpm_desc",
				Min = 0,
				Max = 10000,
				Decimals = 0,
				Default = 5000,
			},
			{
				Name = "#acf.menu.gearboxes.total_ratio",
				Variable = "TotalRatio",
				Tooltip = "#acf.menu.gearboxes.total_ratio_desc",
				Min = 0,
				Max = 1,
				Decimals = 2,
				Default = 0.1,
			},
			{
				Name = "#acf.menu.gearboxes.wheel_diameter",
				Variable = "WheelDiameter",
				Tooltip = "#acf.menu.gearboxes.wheel_diameter_desc",
				Min = 0,
				Max = 1000,
				Decimals = 2,
				Default = 30,
			},
		}

		function ACF.AutomaticGearboxMenu(Class, _, Menu, _)
			local Gears = Class.CanSetGears and ACF.GetClientNumber("GearAmount", 3) or Class.Gears.Max
			local GearBase = Menu:AddCollapsible("#acf.menu.gearboxes.gear_settings", nil, "icon16/cog_edit.png")

			Values[Class.ID] = Values[Class.ID] or {}

			local ValuesData = Values[Class.ID]

			GearBase:AddLabel("#acf.menu.gearboxes.upshift_speed_unit")

			ACF.SetClientData("ShiftUnit", UnitMult)

			local Unit = GearBase:AddComboBox()
			Unit:AddChoice("#acf.menu.gearboxes.kph", 10.936)
			Unit:AddChoice("#acf.menu.gearboxes.mph", 17.6)
			Unit:AddChoice("#acf.menu.gearboxes.gmu", 1)

			function Unit:OnSelect(_, _, Mult)
				if UnitMult == Mult then return end

				local Delta = UnitMult / Mult

				for I = 1, Gears do
					local Var = "Shift" .. I
					local Old = ACF.GetClientNumber(Var)

					ACF.SetClientData(Var, Old * Delta)
				end

				ACF.SetClientData("ShiftUnit", Mult)

				UnitMult = Mult
			end

			for I = 1, Gears do
				local GearVar = "Gear" .. I
				local DefGear = ValuesData[GearVar]

				if not DefGear then
					DefGear = math.Clamp(I * 0.1, ACF.MinGearRatio, ACF.MaxGearRatio)

					ValuesData[GearVar] = DefGear
				end

				ACF.SetClientData(GearVar, DefGear)

				local GearName = language.GetPhrase("acf.menu.gearboxes.gear_number"):format(I)
				local Gear = GearBase:AddSlider(GearName, ACF.MinGearRatio, ACF.MaxGearRatio, 2)
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

				local ShiftName = language.GetPhrase("acf.menu.gearboxes.gear_upshift_speed"):format(I)
				local Shift = GearBase:AddNumberWang(ShiftName, 0, 9999, 2)
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

			local GenBase = Menu:AddCollapsible("#acf.menu.gearboxes.shift_point_generator", nil, "icon16/chart_curve_edit.png")

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

			local Button = GenBase:AddButton("#acf.menu.gearboxes.calculate")

			function Button:DoClickInternal()
				local UpshiftRPM = ValuesData.UpshiftRPM
				local TotalRatio = ValuesData.TotalRatio
				local FinalDrive = ValuesData.FinalDrive
				local WheelDiameter = ValuesData.WheelDiameter
				local Multiplier = math.pi * UpshiftRPM * TotalRatio * FinalDrive * WheelDiameter / (60 * UnitMult)

				for I = 1, Gears do
					local Gear = ValuesData["Gear" .. I]

					ACF.SetClientData("Shift" .. I, Gear * Multiplier)
				end
			end
		end
	end
end

do -- Default turret menus
	local Turrets	= ACF.Classes.Turrets
	local GraphBlue	= Color(65, 65, 200)
	local GraphRed	= Color(200, 65, 65)

	do	-- Turret ring
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

			local RingSize	= Menu:AddSlider("#acf.menu.turrets.ring_diameter", Data.Size.Min, Data.Size.Max, 2)

			local MaxSpeed	= Menu:AddSlider("#acf.menu.turrets.max_speed", 0, 120, 2)

			Menu:AddLabel("#acf.menu.turrets.max_speed_desc")

			local TurretText	= language.GetPhrase("acf.menu.turrets.turret_text")
			local MassText		= language.GetPhrase("acf.menu.turrets.mass_text")
			local RingStats		= Menu:AddLabel(TurretText:format(0, 0))
			local MassLbl		= Menu:AddLabel(MassText:format(0, 0))

			local ArcSettings	= Menu:AddCollapsible("#acf.menu.turrets.arc_settings", nil, "icon16/chart_pie_edit.png")

			ArcSettings:AddLabel("#acf.menu.turrets.arc_settings_desc")

			local CircleColor	= Color(65, 65, 65)
			local MinDegText	= language.GetPhrase("acf.menu.turrets.arc_min")
			local MaxDegText	= language.GetPhrase("acf.menu.turrets.arc_max")
			local TotalArcText	= language.GetPhrase("acf.menu.turrets.arc_total")
			local MinDeg		= ArcSettings:AddSlider("#acf.menu.turrets.min_degrees", -180, 0, 1)
			local MaxDeg		= ArcSettings:AddSlider("#acf.menu.turrets.max_degrees", 0, 180, 1)

			local ArcDraw = vgui.Create("Panel", ArcSettings)
			ArcDraw:SetSize(64, 64)
			ArcDraw:DockMargin(0, 0, 0, 10)
			ArcDraw:Dock(TOP)
			ArcDraw:InvalidateParent()
			ArcDraw:InvalidateLayout()
			ArcDraw.Paint = function(_, _, h)
				surface.DrawRect(0, 0, h, h)

				local Radius = (h / 2) - 2
				surface.DrawCircle(h / 2, h / 2, Radius, CircleColor)

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

				draw.SimpleTextOutlined("#acf.menu.turrets.zero", "ACF_Control", h + 4, 0, Orange, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1, color_black)
				if (Max - Min) ~= 360 then
					draw.SimpleTextOutlined(MinDegText:format(Min), "ACF_Control", h + 4, 16, Red, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1, color_black)
					draw.SimpleTextOutlined(MaxDegText:format(Max), "ACF_Control", h + 4, 32, Green, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1, color_black)
					draw.SimpleTextOutlined(TotalArcText:format(Max - Min), "ACF_Control", h + 4, 48, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1, color_black)
				else
					draw.SimpleTextOutlined("#acf.menu.turrets.no_arc_limit", "ACF_Control", h + 4, 16, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1, color_black)
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

			local EstMass	= Menu:AddSlider("#acf.menu.turrets.estimated_mass", 0, 100000, 0)
			local EstDist	= Menu:AddSlider("#acf.menu.turrets.mass_center_distance", 0, 2, 2)

			Menu:AddLabel("#acf.menu.turrets.handcrank_desc")
			local HandCrankText	= language.GetPhrase("acf.menu.turrets.handcrank_text")
			local HandCrankLbl	= Menu:AddLabel(HandCrankText:format(0, 0))

			local Graph		= Menu:AddGraph()
			local GraphSize	= Menu:GetParent():GetParent():GetWide()
			Graph:SetSize(GraphSize, GraphSize / 2)
			Graph:SetXLabel("#acf.menu.turrets.estimated_mass")
			Graph:SetYLabel("#acf.menu.turrets.degrees_per_second")
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
				Graph:PlotTable(language.GetPhrase("acf.menu.turrets.slew_rate"), Points, GraphBlue)

				Graph:PlotPoint(language.GetPhrase("acf.menu.turrets.estimate"), TurretData.TotalMass, Info.MaxSlewRate, GraphBlue)
			end

			RingSize:SetClientData("RingSize", "OnValueChanged")
			RingSize:DefineSetter(function(Panel, _, _, Value)
				local N = Value

				Panel:SetValue(N)

				local Teeth = TurretClass.GetTeethCount(Data, N)
				RingStats:SetText(TurretText:format(Teeth))
				local MaxMass = TurretClass.GetMaxMass(Data, N)
				local TurretMassText = language.GetPhrase("acf.menu.turrets.turret_mass_text")
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

		function ACF.CreateTurretMotorMenu(Data, Menu)
			local MotorClass	= Turrets.Get("2-Motor")
			local TurretClass	= Turrets.Get("1-Turret")

			ACF.SetClientData("Motor", Data.ID)
			ACF.SetClientData("Destiny", "TurretMotors")
			ACF.SetClientData("PrimaryClass", "acf_turret_motor")

			Menu:AddLabel(language.GetPhrase("acf.menu.turrets.motors.speed"):format(Data.Speed))

			local ScaleText	= language.GetPhrase("acf.menu.turrets.motors.scale")
			local CompSize	= Menu:AddSlider(ScaleText:format(Data.ScaleLimit.Min, Data.ScaleLimit.Max), Data.ScaleLimit.Min, Data.ScaleLimit.Max, 1)

			local TeethText	= language.GetPhrase("acf.menu.turrets.motors.teeth")
			local TeethAmt	= Menu:AddSlider(TeethText:format(Data.Teeth.Min, Data.Teeth.Max), Data.Teeth.Min, Data.Teeth.Max, 0)
			Menu:AddLabel("#acf.menu.turrets.motors.teeth_desc")

			local TurretMassText	= language.GetPhrase("acf.menu.turrets.turret_mass_text")
			local TorqText			= language.GetPhrase("acf.menu.turrets.motors.torque_text")
			local MassLbl			= Menu:AddLabel(TurretMassText:format(0, 0))
			local TorqLbl			= Menu:AddLabel(TorqText:format(0))

			-- Simulation

			local TurretSim = Menu:AddCollapsible("#acf.menu.turrets.motors.simulation")
			TurretSim:AddLabel("#acf.menu.turrets.motors.simulation_desc")

			local TurretType = TurretSim:AddComboBox()
			local TurretSize = TurretSim:AddSlider("#acf.menu.turrets.motors.turret_size", 0, 1, 2)
			local EstMass = TurretSim:AddSlider("#acf.menu.turrets.estimated_mass", 0, 100000, 1)
			local EstDist = TurretSim:AddSlider("#acf.menu.turrets.mass_center_distance", 0, 2, 2)
			local MaxMassText	= language.GetPhrase("acf.menu.turrets.motors.max_mass")
			local MaxMassLbl	= TurretSim:AddLabel(MaxMassText:format(0))

			local Graph		= Menu:AddGraph()
			local GraphSize	= Menu:GetParent():GetParent():GetWide()
			Graph:SetSize(GraphSize, GraphSize / 2)
			Graph:SetXLabel("#acf.menu.turrets.estimated_mass")
			Graph:SetYLabel("#acf.menu.turrets.degrees_per_second")
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

				self:PlotTable(language.GetPhrase("acf.menu.turrets.motors.hand_rate"), HandCrankPoints, GraphBlue)
				self:PlotPoint(language.GetPhrase("acf.menu.turrets.motors.hand_estimate"), TurretData.Mass, TurretData.HandSim, GraphBlue)

				self:PlotTable(language.GetPhrase("acf.menu.turrets.motors.motor_rate"), MotorPoints, GraphRed)
				self:PlotPoint(language.GetPhrase("acf.menu.turrets.motors.motor_estimate"), TurretData.Mass, TurretData.MotorSim, GraphRed)
			end

			local HandcrankText	= language.GetPhrase("acf.menu.turrets.handcrank_text")
			local MotorText		= language.GetPhrase("acf.menu.turrets.motors.motor_text")
			local MassText = language.GetPhrase("acf.menu.turrets.mass_text")

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
				MaxMassLbl:SetText(MaxMassText:format(math.Round(TurretData.MaxMass, 1)))

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

			local MassText = language.GetPhrase("acf.menu.turrets.mass_text")
			Menu:AddLabel(MassText:format(Data.Mass))

			if Data.IsDual then
				Menu:AddLabel("#acf.menu.gyros.dual_desc")
			end
		end
	end

	do	-- Turret Computers
		function ACF.CreateTurretComputerMenu(Data, Menu)
			ACF.SetClientData("Computer", Data.ID)
			ACF.SetClientData("Destiny", "TurretComputers")
			ACF.SetClientData("PrimaryClass", "acf_turret_computer")

			local MassText = language.GetPhrase("acf.menu.turrets.mass_text")
			Menu:AddLabel(MassText:format(Data.Mass))
		end
	end

	do
		-- Draws an outlined beam between var-length pairs of XY1 -> XY2 line segments.
		-- Is not the best thing in the world, only really used in gizmos to make it easier 
		-- to see during building
		function ACF.DrawOutlineBeam(width, color, ...)
			local args = {...}
			local Add = 0.4
			for i = 1, #args, 2 do
				local DirAdd = (args[i + 1] - args[i]):GetNormalized() * (Add / 2)

				render.DrawBeam(args[i] - DirAdd, args[i + 1] + DirAdd, width + Add, 0, 1, color_black)
			end
			for i = 1, #args, 2 do
				render.DrawBeam(args[i], args[i + 1], width, 0, 1, color)
			end
		end
	end
end