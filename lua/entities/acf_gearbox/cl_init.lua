include("shared.lua")

local HideInfo = ACF.HideInfoBubble

language.Add("Undone_acf_gearbox", "Undone ACF Gearbox")
language.Add("SBoxLimit__acf_gearbox", "You've reached the ACF Gearboxes limit!")

-- copied from base_wire_entity: DoNormalDraw's notip arg isn't accessible from ENT:Draw defined there.
function ENT:Draw()
	self:DoNormalDraw(false, HideInfo())

	Wire_Render(self)

	if self.GetBeamLength and (not self.GetShowBeam or self:GetShowBeam()) then
		-- Every SENT that has GetBeamLength should draw a tracer. Some of them have the GetShowBeam boolean
		Wire_DrawTracerBeam(self, 1, self.GetBeamHighlight and self:GetBeamHighlight() or false)
	end
end

function ACFGearboxGUICreate(Table)
	if not acfmenupanel.Serialize then
		acfmenupanel.Serialize = function(tbl, factor)
			local str = ""

			for i = 1, 7 do
				str = str .. math.Round(tbl[i] * factor, 1) .. ","
			end

			RunConsoleCommand("acfmenu_data9", str)
		end
	end

	if not acfmenupanel.GearboxData then
		acfmenupanel.GearboxData = {}
	end

	if not acfmenupanel.GearboxData[Table.id] then
		acfmenupanel.GearboxData[Table.id] = {}
		acfmenupanel.GearboxData[Table.id].GearTable = Table.geartable
	end

	if Table.auto and not acfmenupanel.GearboxData[Table.id].ShiftTable then
		acfmenupanel.GearboxData[Table.id].ShiftTable = {10, 20, 30, 40, 50, 60, 70}
	end

	acfmenupanel:CPanelText("Name", Table.name)
	acfmenupanel.CData.DisplayModel = vgui.Create("DModelPanel", acfmenupanel.CustomDisplay)
	acfmenupanel.CData.DisplayModel:SetModel(Table.model)
	acfmenupanel.CData.DisplayModel:SetCamPos(Vector(250, 500, 250))
	acfmenupanel.CData.DisplayModel:SetLookAt(Vector(0, 0, 0))
	acfmenupanel.CData.DisplayModel:SetFOV(20)
	acfmenupanel.CData.DisplayModel:SetSize(acfmenupanel:GetWide(), acfmenupanel:GetWide())
	acfmenupanel.CData.DisplayModel.LayoutEntity = function() end
	acfmenupanel.CustomDisplay:AddItem(acfmenupanel.CData.DisplayModel)
	acfmenupanel:CPanelText("Desc", Table.desc) --Description (Name, Desc)

	if Table.auto and not acfmenupanel.CData.UnitsInput then
		acfmenupanel.CData.UnitsInput = vgui.Create("DComboBox", acfmenupanel.CustomDisplay)
		acfmenupanel.CData.UnitsInput.ID = Table.id
		acfmenupanel.CData.UnitsInput.Gears = Table.gears
		acfmenupanel.CData.UnitsInput:SetSize(60, 22)
		acfmenupanel.CData.UnitsInput:SetTooltip("If using the shift point generator, recalc after changing units.")
		acfmenupanel.CData.UnitsInput:AddChoice("KPH", 10.936, true)
		acfmenupanel.CData.UnitsInput:AddChoice("MPH", 17.6)
		acfmenupanel.CData.UnitsInput:AddChoice("GMU", 1)
		acfmenupanel.CData.UnitsInput:SetDark(true)

		acfmenupanel.CData.UnitsInput.OnSelect = function(panel, _, _, data)
			acfmenupanel.Serialize(acfmenupanel.GearboxData[panel.ID].ShiftTable, data) --dot intentional
		end

		acfmenupanel.CustomDisplay:AddItem(acfmenupanel.CData.UnitsInput)
	end

	if Table.cvt then
		ACF_GearsSlider(2, acfmenupanel.GearboxData[Table.id].GearTable[2], Table.id)
		ACF_GearsSlider(3, acfmenupanel.GearboxData[Table.id].GearTable[-3], Table.id, "Min Target RPM", true)
		ACF_GearsSlider(4, acfmenupanel.GearboxData[Table.id].GearTable[-2], Table.id, "Max Target RPM", true)
		ACF_GearsSlider(10, acfmenupanel.GearboxData[Table.id].GearTable[-1], Table.id, "Final Drive")
		RunConsoleCommand("acfmenu_data1", 0.01)
	else
		for ID, Value in pairs(acfmenupanel.GearboxData[Table.id].GearTable) do
			if ID > 0 and not (Table.auto and ID == 8) then
				ACF_GearsSlider(ID, Value, Table.id)

				if Table.auto then
					ACF_ShiftPoint(ID, acfmenupanel.GearboxData[Table.id].ShiftTable[ID], Table.id, "Gear " .. ID .. " upshift speed: ")
				end
			elseif Table.auto and (ID == -2 or ID == 8) then
				ACF_GearsSlider(8, Value, Table.id, "Reverse")
			elseif ID == -1 then
				ACF_GearsSlider(10, Value, Table.id, "Final Drive")
			end
		end
	end

	acfmenupanel:CPanelText("Desc", Table.desc)
	acfmenupanel:CPanelText("MaxTorque", "Clutch Maximum Torque Rating : " .. Table.maxtq .. "n-m / " .. math.Round(Table.maxtq * 0.73) .. "ft-lb")
	acfmenupanel:CPanelText("Weight", "Weight : " .. Table.weight .. "kg")

	if Table.parentable then
		acfmenupanel:CPanelText("Parentable", "\nThis gearbox can be parented without welding.")
	end

	if Table.auto then
		acfmenupanel:CPanelText("ShiftPointGen", "\nShift Point Generator:")

		if not acfmenupanel.CData.ShiftGenPanel then
			acfmenupanel.CData.ShiftGenPanel = vgui.Create("DPanel")
			acfmenupanel.CData.ShiftGenPanel:SetPaintBackground(false)
			acfmenupanel.CData.ShiftGenPanel:DockPadding(4, 0, 4, 0)
			acfmenupanel.CData.ShiftGenPanel:SetTall(60)
			acfmenupanel.CData.ShiftGenPanel:SizeToContentsX()
			acfmenupanel.CData.ShiftGenPanel.Gears = Table.gears
			acfmenupanel.CData.ShiftGenPanel.Calc = acfmenupanel.CData.ShiftGenPanel:Add("DButton")
			acfmenupanel.CData.ShiftGenPanel.Calc:SetText("Calculate")
			acfmenupanel.CData.ShiftGenPanel.Calc:Dock(BOTTOM)
			--acfmenupanel.CData.ShiftGenPanel.Calc:SetWide( 80 )
			acfmenupanel.CData.ShiftGenPanel.Calc:SetTall(20)

			acfmenupanel.CData.ShiftGenPanel.Calc.DoClick = function()
				local _, factor = acfmenupanel.CData.UnitsInput:GetSelected()
				local mul = math.pi * acfmenupanel.CData.ShiftGenPanel.RPM:GetValue() * acfmenupanel.CData.ShiftGenPanel.Ratio:GetValue() * acfmenupanel.CData[10]:GetValue() * acfmenupanel.CData.ShiftGenPanel.Wheel:GetValue() / (60 * factor)

				for i = 1, acfmenupanel.CData.ShiftGenPanel.Gears do
					acfmenupanel.CData[10 + i].Input:SetValue(math.Round(math.abs(mul * acfmenupanel.CData[i]:GetValue()), 2))
					acfmenupanel.GearboxData[acfmenupanel.CData.UnitsInput.ID].ShiftTable[i] = tonumber(acfmenupanel.CData[10 + i].Input:GetValue())
				end

				acfmenupanel.Serialize(acfmenupanel.GearboxData[acfmenupanel.CData.UnitsInput.ID].ShiftTable, factor) --dot intentional
			end

			acfmenupanel.CData.WheelPanel = acfmenupanel.CData.ShiftGenPanel:Add("DPanel")
			acfmenupanel.CData.WheelPanel:SetPaintBackground(false)
			acfmenupanel.CData.WheelPanel:DockMargin(4, 0, 4, 0)
			acfmenupanel.CData.WheelPanel:Dock(RIGHT)
			acfmenupanel.CData.WheelPanel:SetWide(76)
			acfmenupanel.CData.WheelPanel:SetTooltip("If you use default spherical settings, add 0.5 to your wheel diameter.\nFor treaded vehicles, use the diameter of road wheels, not drive wheels.")
			acfmenupanel.CData.ShiftGenPanel.WheelLabel = acfmenupanel.CData.WheelPanel:Add("DLabel")
			acfmenupanel.CData.ShiftGenPanel.WheelLabel:Dock(TOP)
			acfmenupanel.CData.ShiftGenPanel.WheelLabel:SetDark(true)
			acfmenupanel.CData.ShiftGenPanel.WheelLabel:SetText("Wheel Diameter:")
			acfmenupanel.CData.ShiftGenPanel.Wheel = acfmenupanel.CData.WheelPanel:Add("DNumberWang")
			acfmenupanel.CData.ShiftGenPanel.Wheel:HideWang()
			acfmenupanel.CData.ShiftGenPanel.Wheel:SetDrawBorder(false)
			acfmenupanel.CData.ShiftGenPanel.Wheel:Dock(BOTTOM)
			acfmenupanel.CData.ShiftGenPanel.Wheel:SetDecimals(2)
			acfmenupanel.CData.ShiftGenPanel.Wheel:SetMinMax(0, 9999)
			acfmenupanel.CData.ShiftGenPanel.Wheel:SetValue(30)
			acfmenupanel.CData.RatioPanel = acfmenupanel.CData.ShiftGenPanel:Add("DPanel")
			acfmenupanel.CData.RatioPanel:SetPaintBackground(false)
			acfmenupanel.CData.RatioPanel:DockMargin(4, 0, 4, 0)
			acfmenupanel.CData.RatioPanel:Dock(RIGHT)
			acfmenupanel.CData.RatioPanel:SetWide(76)
			acfmenupanel.CData.RatioPanel:SetTooltip("Total ratio is the ratio of all gearboxes (exluding this one) multiplied together.\nFor example, if you use engine to automatic to diffs to wheels, your total ratio would be (diff gear ratio * diff final ratio).")
			acfmenupanel.CData.ShiftGenPanel.RatioLabel = acfmenupanel.CData.RatioPanel:Add("DLabel")
			acfmenupanel.CData.ShiftGenPanel.RatioLabel:Dock(TOP)
			acfmenupanel.CData.ShiftGenPanel.RatioLabel:SetDark(true)
			acfmenupanel.CData.ShiftGenPanel.RatioLabel:SetText("Total ratio:")
			acfmenupanel.CData.ShiftGenPanel.Ratio = acfmenupanel.CData.RatioPanel:Add("DNumberWang")
			acfmenupanel.CData.ShiftGenPanel.Ratio:HideWang()
			acfmenupanel.CData.ShiftGenPanel.Ratio:SetDrawBorder(false)
			acfmenupanel.CData.ShiftGenPanel.Ratio:Dock(BOTTOM)
			acfmenupanel.CData.ShiftGenPanel.Ratio:SetDecimals(2)
			acfmenupanel.CData.ShiftGenPanel.Ratio:SetMinMax(0, 9999)
			acfmenupanel.CData.ShiftGenPanel.Ratio:SetValue(0.1)
			acfmenupanel.CData.RPMPanel = acfmenupanel.CData.ShiftGenPanel:Add("DPanel")
			acfmenupanel.CData.RPMPanel:SetPaintBackground(false)
			acfmenupanel.CData.RPMPanel:DockMargin(4, 0, 4, 0)
			acfmenupanel.CData.RPMPanel:Dock(RIGHT)
			acfmenupanel.CData.RPMPanel:SetWide(76)
			acfmenupanel.CData.RPMPanel:SetTooltip("Target engine RPM to upshift at.")
			acfmenupanel.CData.ShiftGenPanel.RPMLabel = acfmenupanel.CData.RPMPanel:Add("DLabel")
			acfmenupanel.CData.ShiftGenPanel.RPMLabel:Dock(TOP)
			acfmenupanel.CData.ShiftGenPanel.RPMLabel:SetDark(true)
			acfmenupanel.CData.ShiftGenPanel.RPMLabel:SetText("Upshift RPM:")
			acfmenupanel.CData.ShiftGenPanel.RPM = acfmenupanel.CData.RPMPanel:Add("DNumberWang")
			acfmenupanel.CData.ShiftGenPanel.RPM:HideWang()
			acfmenupanel.CData.ShiftGenPanel.RPM:SetDrawBorder(false)
			acfmenupanel.CData.ShiftGenPanel.RPM:Dock(BOTTOM)
			acfmenupanel.CData.ShiftGenPanel.RPM:SetDecimals(2)
			acfmenupanel.CData.ShiftGenPanel.RPM:SetMinMax(0, 9999)
			acfmenupanel.CData.ShiftGenPanel.RPM:SetValue(5000)
			acfmenupanel.CustomDisplay:AddItem(acfmenupanel.CData.ShiftGenPanel)
		end
	end

	acfmenupanel.CustomDisplay:PerformLayout()
	maxtorque = Table.maxtq
end

function ACF_GearsSlider(Gear, Value, ID, Desc, CVT)
	if Gear and not acfmenupanel.CData[Gear] then
		acfmenupanel.CData[Gear] = vgui.Create("DNumSlider", acfmenupanel.CustomDisplay)
		acfmenupanel.CData[Gear]:SetText(Desc or "Gear " .. Gear)
		acfmenupanel.CData[Gear].Label:SizeToContents()
		acfmenupanel.CData[Gear]:SetDark(true)
		acfmenupanel.CData[Gear]:SetMin(CVT and 1 or -1)
		acfmenupanel.CData[Gear]:SetMax(CVT and 10000 or 1)
		acfmenupanel.CData[Gear]:SetDecimals((not CVT) and 2 or 0)
		acfmenupanel.CData[Gear].Gear = Gear
		acfmenupanel.CData[Gear].ID = ID
		acfmenupanel.CData[Gear]:SetValue(Value)
		RunConsoleCommand("acfmenu_data" .. Gear, Value)

		acfmenupanel.CData[Gear].OnValueChanged = function(slider, val)
			acfmenupanel.GearboxData[slider.ID].GearTable[slider.Gear] = val
			RunConsoleCommand("acfmenu_data" .. Gear, val)
		end

		acfmenupanel.CustomDisplay:AddItem(acfmenupanel.CData[Gear])
	end
end

function ACF_ShiftPoint(Gear, Value, ID, Desc)
	local Index = Gear + 10

	if Gear and not acfmenupanel.CData[Index] then
		acfmenupanel.CData[Index] = vgui.Create("DPanel")
		acfmenupanel.CData[Index]:SetPaintBackground(false)
		acfmenupanel.CData[Index]:SetTall(20)
		acfmenupanel.CData[Index]:SizeToContentsX()
		acfmenupanel.CData[Index].Input = acfmenupanel.CData[Index]:Add("DNumberWang")
		acfmenupanel.CData[Index].Input.Gear = Gear
		acfmenupanel.CData[Index].Input.ID = ID
		acfmenupanel.CData[Index].Input:HideWang()
		acfmenupanel.CData[Index].Input:SetDrawBorder(false)
		acfmenupanel.CData[Index].Input:SetDecimals(2)
		acfmenupanel.CData[Index].Input:SetMinMax(0, 9999)
		acfmenupanel.CData[Index].Input:SetValue(Value)
		acfmenupanel.CData[Index].Input:Dock(RIGHT)
		acfmenupanel.CData[Index].Input:SetWide(45)

		acfmenupanel.CData[Index].Input.OnValueChanged = function(box, value)
			acfmenupanel.GearboxData[box.ID].ShiftTable[box.Gear] = value
			local _, factor = acfmenupanel.CData.UnitsInput:GetSelected()
			acfmenupanel.Serialize(acfmenupanel.GearboxData[acfmenupanel.CData.UnitsInput.ID].ShiftTable, factor) --dot intentional
		end

		RunConsoleCommand("acfmenu_data9", "10,20,30,40,50,60,70")
		acfmenupanel.CData[Index].Label = acfmenupanel.CData[Index]:Add("DLabel")
		acfmenupanel.CData[Index].Label:Dock(RIGHT)
		acfmenupanel.CData[Index].Label:SetWide(120)
		acfmenupanel.CData[Index].Label:SetDark(true)
		acfmenupanel.CData[Index].Label:SetText(Desc)
		acfmenupanel.CustomDisplay:AddItem(acfmenupanel.CData[Index])
	end
end