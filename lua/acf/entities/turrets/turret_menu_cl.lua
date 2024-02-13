local ACF  		= ACF
local Turrets	= ACF.Classes.Turrets
local MassText	= "Mass : %s kg\n"

do	-- Turret ring
	local TurretText	= "Teeth Count: %G\n"
	local HandCrankText	= "--Handcrank--\nMax Speed: %G deg/s\nAccel: %G deg/s^2"

	local Orange	= Color(255,127,0)
	local Red		= Color(255,0,0)
	local Green		= Color(0,255,0)

	function ACF.CreateTurretMenu(Data, Menu)
		local TurretClass	= Turrets.Get("1-Turret")
		ACF.SetClientData("Turret", Data.ID)
		ACF.SetClientData("Destiny", "Turrets")
		ACF.SetClientData("PrimaryClass", "acf_turret")

		local TurretData	= {
			Ready		= false,
			TurretClass	= Data.ID,
			Teeth		= TurretClass.GetTeethCount(Data,Data.Size.Base),
			TotalMass	= 0,
			RingSize	= Data.Size.Base,
			RingHeight	= TurretClass.GetRingHeight({Type = "Turret-H",Ratio = Data.Size.Ratio},Data.Size.Base),
			LocalCoM	= Vector(),
			Tilt		= 1
		}

		local RingSize	= Menu:AddSlider("Ring diameter (gmu)", Data.Size.Min, Data.Size.Max, 2)

		local RingStats	= Menu:AddLabel(TurretText:format(0,0))
		local MassLbl	= Menu:AddLabel(MassText:format(0))

		Menu:AddLabel("If the total arc is less than 360, then it will use the limits set here.\nIf it is 360, then it will have free rotation.\nUnchecking this will disable the limits as well.")

		local ArcToggle	= Menu:AddCheckBox("Use Arc Settings")

		local ArcSettings	= Menu:AddCollapsible("Arc Settings")
		ArcSettings.ApplySchemeSettings = function(Panel)
			Panel:SetBGColor(Color(150,150,150))
		end

		local MinDeg	= ArcSettings:AddSlider("Minimum Degrees", -180, 0, 1)

		local MaxDeg	= ArcSettings:AddSlider("Maximum Degrees", 0, 180, 1)

		local ArcDraw = vgui.Create("Panel",ArcSettings)
		ArcDraw:SetSize(64,64)
		ArcDraw:DockMargin(0,0,0,10)
		ArcDraw:Dock(TOP)
		ArcDraw:InvalidateParent()
		ArcDraw:InvalidateLayout()
		ArcDraw.Paint = function(_, _, h)
			surface.SetDrawColor(65,65,65)
			surface.DrawRect(0,0,h,h)

			local Radius = (h / 2) - 2
			surface.DrawCircle(h / 2, h / 2, Radius, Color(127, 127, 127))

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

			draw.SimpleTextOutlined("Zero","ACF_Control",h + 4 , 0, Orange, TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP, 1, color_black)
			if (Max - Min) ~= 360 then
				draw.SimpleTextOutlined("Minimum: " .. Min,"ACF_Control",h + 4 , 16, Red, TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP, 1, color_black)
				draw.SimpleTextOutlined("Maximum: " .. Max,"ACF_Control",h + 4 , 32, Green, TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP, 1, color_black)
				draw.SimpleTextOutlined("Total Arc: " .. (Max - Min),"ACF_Control",h + 4 , 48, color_white, TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP, 1, color_black)
			else
				draw.SimpleTextOutlined("No arc limit","ACF_Control",h + 4 , 16, color_white, TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP, 1, color_black)
			end
		end

		MinDeg:SetClientData("MinDeg","OnValueChanged")
		MinDeg:DefineSetter(function(Panel, _, _, Value)
			local N = math.Clamp(math.Round(Value,1),-180,0)

			Panel:SetValue(N)

			return N
		end)
		MinDeg:SetValue(-180)
		MinDeg:SetEnabled(false)

		MaxDeg:SetClientData("MaxDeg", "OnValueChanged")
		MaxDeg:DefineSetter(function(Panel, _, _, Value)
			local N = math.Clamp(math.Round(Value,1),0,180)

			Panel:SetValue(N)

			return N
		end)
		MaxDeg:SetValue(180)
		MaxDeg:SetEnabled(false)

		ACF.SetClientData("MinDeg",-180)
		ACF.SetClientData("MaxDeg",180)

		ArcToggle.OnChange = function(_, Value)
			MinDeg:SetEnabled(Value)
			MaxDeg:SetEnabled(Value)

			if Value == true then
				ACF.SetClientData("MinDeg",MinDeg:GetValue())
				ACF.SetClientData("MaxDeg",MaxDeg:GetValue())
			else
				ACF.SetClientData("MinDeg",-180)
				ACF.SetClientData("MaxDeg",180)
			end
		end

		local EstMass	= Menu:AddSlider("Estimated mass of turret (kg)", 0, 100000, 0)

		local EstDist	= Menu:AddSlider("Center of mass distance (gmu)", 0, 2, 2)

		Menu:AddLabel("Approximation of speed of the turret, with a handcrank.")
		local HandCrankLbl	= Menu:AddLabel(HandCrankText:format(0,0))

		local Graph		= Menu:AddGraph()
		local GraphSize	= Menu:GetParent():GetParent():GetWide()
		Graph:SetSize(GraphSize, GraphSize / 2)
		Graph:SetXLabel("Estimated Mass (kg)")
		Graph:SetYLabel("Degrees/sec")
		Graph:SetXRange(0,100000)
		Graph:SetXSpacing(10000)
		Graph:SetYSpacing(5)

		HandCrankLbl.UpdateSim = function(Panel)
			if TurretData.Ready == false then return end

			local Info = TurretClass.CalcSpeed(TurretData,TurretClass.HandGear)

			Panel:SetText(HandCrankText:format(math.Round(Info.MaxSlewRate,2),math.Round(Info.SlewAccel,4)))

			local SimTurretData = {
				LocalCoM	= TurretData.LocalCoM,
				RingSize	= TurretData.RingSize,
				RingHeight	= TurretData.RingHeight,
				Teeth		= TurretData.Teeth,
				Tilt		= 1,
				TurretClass	= TurretData.TurretClass,
				TotalMass	= 0
			}

			local Points	= {}

			for I = 1, 101 do
				local Mass = 1000 * (I - 1)
				SimTurretData.TotalMass = Mass

				Points[I] = {x = Mass, y = TurretClass.CalcSpeed(SimTurretData, TurretClass.HandGear).MaxSlewRate}
			end

			Graph:SetYRange(0, Points[1].y * 1.1)

			Graph:Clear()
			Graph:PlotTable("Slew Rate", Points, Color(65,65,200))

			Graph:PlotPoint("Estimate", TurretData.TotalMass, Info.MaxSlewRate, Color(65,65,200))
		end

		RingSize:SetClientData("RingSize", "OnValueChanged")
		RingSize:DefineSetter(function(Panel, _, _, Value)
			local N = Value

			Panel:SetValue(N)

			local Teeth = TurretClass.GetTeethCount(Data,N)
			RingStats:SetText(TurretText:format(Teeth))
			MassLbl:SetText(MassText:format(TurretClass.GetMass(Data,N)))

			TurretData.Teeth		= Teeth
			TurretData.RingSize		= N
			TurretData.RingHeight	= TurretClass.GetRingHeight({Type = Data.ID,Ratio = Data.Size.Ratio},N)

			EstDist:SetMinMax(0,math.max(N * 2,24))

			HandCrankLbl:UpdateSim()

			return N
		end)

		EstMass.OnValueChanged = function(_, Value)
			TurretData.TotalMass = Value

			HandCrankLbl:UpdateSim()
		end

		EstDist.OnValueChanged = function(_, Value)
			TurretData.LocalCoM = Vector(Value,0,Value)

			HandCrankLbl:UpdateSim()
		end

		RingSize:SetValue(Data.Size.Base)
		EstMass:SetValue(0)
		EstDist:SetValue(0)

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

	local TorqText	= "%GNm Torque"
	local HandcrankText = "--HANDCRANK--\nMax Speed: %G deg/s\nAccel: %G deg/s^2"
	local MotorText	= "--MOTOR--\nMax Speed: %G deg/s\nAccel: %G deg/s^2"

	function ACF.CreateTurretMotorMenu(Data, Menu)
		local MotorClass	= Turrets.Get("2-Motor")
		local TurretClass	= Turrets.Get("1-Turret")

		ACF.SetClientData("Motor", Data.ID)
		ACF.SetClientData("Destiny", "TurretMotors")
		ACF.SetClientData("PrimaryClass", "acf_turret_motor")

		Menu:AddLabel("Motor Speed: " .. Data.Speed .. "RPM")

		local CompSize	= Menu:AddSlider("Motor Scale (" .. Data.ScaleLimit.Min .. "-" .. Data.ScaleLimit.Max .. ")", Data.ScaleLimit.Min, Data.ScaleLimit.Max, 1)

		Menu:AddLabel("Determines the number of teeth of the gear on the motor.")
		local TeethAmt	= Menu:AddSlider("Gear Teeth (" .. Data.Teeth.Min .. "-" .. Data.Teeth.Max .. ")", Data.Teeth.Min, Data.Teeth.Max, 0)

		local MassLbl	= Menu:AddLabel(MassText:format(0))
		local TorqLbl	= Menu:AddLabel(TorqText:format(0))

		-- Simulation

		local TurretSim = Menu:AddCollapsible("Turret Simulation")
		TurretSim.ApplySchemeSettings = function(Panel)
			Panel:SetBGColor(Color(150,150,150))
		end
		TurretSim:AddLabel("These values are only an approximation!")

		local TurretType = TurretSim:AddComboBox()

		local TurretSize = TurretSim:AddSlider("Turret Size (gmu)", 0, 1, 2)

		local EstMass = TurretSim:AddSlider("Estimated mass (kg)", 0, 100000, 1)

		local EstDist = TurretSim:AddSlider("Center of mass distance (gmu)", 0, 2, 2)

		local Graph		= Menu:AddGraph()
		local GraphSize	= Menu:GetParent():GetParent():GetWide()
		Graph:SetSize(GraphSize, GraphSize / 2)
		Graph:SetXLabel("Estimated Mass (kg)")
		Graph:SetYLabel("Degrees/sec")
		Graph:SetXRange(0,100000)
		Graph:SetXSpacing(10000)
		Graph:SetYSpacing(5)

		Graph.Replot = function(self)
			self:Clear()

			local SimTurretData = {
				LocalCoM	= Vector(TurretData.Distance,0,TurretData.Distance),
				RingSize	= TurretData.Size,
				RingHeight	= TurretData.RingHeight,
				Teeth		= TurretData.TurretTeeth,
				Tilt		= 1,
				TurretClass	= TurretData.Type,
				TotalMass	= 0
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

			self:PlotTable("Hand Rate", HandCrankPoints, Color(65,65,200))
			self:PlotPoint("Hand Estimate", TurretData.Mass, TurretData.HandSim, Color(65,65,200))

			self:PlotTable("Motor Rate", MotorPoints, Color(200,65,65))
			self:PlotPoint("Motor Estimate", TurretData.Mass, TurretData.MotorSim, Color(200,65,65))
		end

		local HandcrankInfo	= TurretSim:AddLabel(HandcrankText:format(0,0))
		HandcrankInfo.UpdateSim = function(Panel)
			if TurretData.Ready == false then return end

			local Info = TurretClass.CalcSpeed({Tilt = 1, TotalMass = TurretData.Mass, RingSize = TurretData.Size, Teeth = TurretData.TurretTeeth, TurretClass = TurretData.Type, LocalCoM = Vector(TurretData.Distance,0,TurretData.Distance), RingHeight = TurretData.RingHeight},
			TurretClass.HandGear)

			Panel:SetText(HandcrankText:format(math.Round(Info.MaxSlewRate,2),math.Round(Info.SlewAccel,4)))

			TurretData.HandSim = Info.MaxSlewRate
			Graph:Replot()
		end

		local MotorInfo	= TurretSim:AddLabel(MotorText:format(0,0))
		MotorInfo.UpdateSim = function(Panel)
			if TurretData.Ready == false then return end

			local Info = TurretClass.CalcSpeed({Tilt = 1, TotalMass = TurretData.Mass, RingSize = TurretData.Size, Teeth = TurretData.TurretTeeth, TurretClass = TurretData.Type, LocalCoM = Vector(TurretData.Distance,0,TurretData.Distance), RingHeight = TurretData.RingHeight},
			{Teeth = TurretData.MotorTeeth, Speed = Data.Speed, Torque = TurretData.Torque, Efficiency = Data.Efficiency, Accel	= Data.Accel})

			Panel:SetText(MotorText:format(math.Round(Info.MaxSlewRate,2),math.Round(Info.SlewAccel,4)))

			TurretData.MotorSim = Info.MaxSlewRate
			Graph:Replot()
		end

		-- Updating functions

		CompSize:SetClientData("CompSize", "OnValueChanged")
		CompSize:DefineSetter(function(Panel, _, _, Value)
			local N = math.Clamp(math.Round(Value,1),Data.ScaleLimit.Min,Data.ScaleLimit.Max)

			Panel:SetValue(N)

			local SizePerc = N ^ 2
			MassLbl:SetText(MassText:format(math.Round(math.max(Data.Mass * SizePerc,5), 1)))

			TurretData.Torque	= MotorClass.GetTorque(Data,N)
			TorqLbl:SetText(TorqText:format(TurretData.Torque))

			MotorInfo:UpdateSim()

			return N
		end)
		CompSize:SetValue(1)

		TeethAmt:SetClientData("Teeth", "OnValueChanged")
		TeethAmt:DefineSetter(function(Panel, _, _, Value)
			local N = math.Clamp(math.Round(Value),Data.Teeth.Min,Data.Teeth.Max)

			Panel:SetValue(N)

			TurretData.MotorTeeth = N

			MotorInfo:UpdateSim()

			return N
		end)
		TeethAmt:SetValue(Data.Teeth.Base)

		TurretSize.OnValueChanged = function(_, Value)
			TurretData.Size			= Value
			TurretData.RingHeight	= TurretClass.GetRingHeight({Type = TurretData.Turret, Ratio = TurretData.Turret.Size.Ratio},Value)
			TurretData.TurretTeeth	= TurretClass.GetTeethCount(TurretData.Turret,Value)

			EstDist:SetMinMax(0,math.max(Value * 2,24))

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

			TurretSize:SetMinMax(Turret.Size.Min,Turret.Size.Max)
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