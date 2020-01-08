include("shared.lua")

local SeatedInfo = CreateClientConVar("ACF_FuelInfoWhileSeated", 0, true, false)

-- copied from base_wire_entity: DoNormalDraw's notip arg isn't accessible from ENT:Draw defined there.
function ENT:Draw()
	local lply = LocalPlayer()
	local hideBubble = not SeatedInfo:GetBool() and IsValid(lply) and lply:InVehicle()
	self.BaseClass.DoNormalDraw(self, false, hideBubble)
	Wire_Render(self)

	if self.GetBeamLength and (not self.GetShowBeam or self:GetShowBeam()) then
		-- Every SENT that has GetBeamLength should draw a tracer. Some of them have the GetShowBeam boolean
		Wire_DrawTracerBeam(self, 1, self.GetBeamHighlight and self:GetBeamHighlight() or false)
	end
end

function ACFFuelTankGUICreate(Table)
	if not acfmenupanel.CustomDisplay then return end

	if not acfmenupanel.FuelTankData then
		acfmenupanel.FuelTankData = {}
		acfmenupanel.FuelTankData.Id = "Tank_4x4x2"
		acfmenupanel.FuelTankData.FuelID = "Petrol"
	end

	local Tanks = ACF.Weapons.FuelTanks
	local SortedTanks = {}

	for n in pairs(Tanks) do
		table.insert(SortedTanks, n)
	end

	table.sort(SortedTanks)
	acfmenupanel:CPanelText("Name", Table.name)
	acfmenupanel:CPanelText("Desc", Table.desc)
	-- tank size dropbox
	acfmenupanel.CData.TankSizeSelect = vgui.Create("DComboBox", acfmenupanel.CustomDisplay)
	acfmenupanel.CData.TankSizeSelect:SetSize(100, 30)

	for _, v in ipairs(SortedTanks) do
		acfmenupanel.CData.TankSizeSelect:AddChoice(v)
	end

	acfmenupanel.CData.TankSizeSelect.OnSelect = function(_, _, data)
		RunConsoleCommand("acfmenu_data1", data)
		acfmenupanel.FuelTankData.Id = data
		ACFFuelTankGUIUpdate(Table)
	end

	acfmenupanel.CData.TankSizeSelect:SetText(acfmenupanel.FuelTankData.Id)
	RunConsoleCommand("acfmenu_data1", acfmenupanel.FuelTankData.Id)
	acfmenupanel.CustomDisplay:AddItem(acfmenupanel.CData.TankSizeSelect)
	-- fuel type dropbox
	acfmenupanel.CData.FuelSelect = vgui.Create("DComboBox", acfmenupanel.CustomDisplay)
	acfmenupanel.CData.FuelSelect:SetSize(100, 30)

	for Key in pairs(ACF.FuelDensity) do
		acfmenupanel.CData.FuelSelect:AddChoice(Key)
	end

	acfmenupanel.CData.FuelSelect.OnSelect = function(_, _, data)
		RunConsoleCommand("acfmenu_data2", data)
		acfmenupanel.FuelTankData.FuelID = data
		ACFFuelTankGUIUpdate(Table)
	end

	acfmenupanel.CData.FuelSelect:SetText(acfmenupanel.FuelTankData.FuelID)
	RunConsoleCommand("acfmenu_data2", acfmenupanel.FuelTankData.FuelID)
	acfmenupanel.CustomDisplay:AddItem(acfmenupanel.CData.FuelSelect)
	ACFFuelTankGUIUpdate(Table)
	acfmenupanel.CustomDisplay:PerformLayout()
end

function ACFFuelTankGUIUpdate()
	if not acfmenupanel.CustomDisplay then return end
	local Tanks = ACF.Weapons.FuelTanks
	local TankID = acfmenupanel.FuelTankData.Id
	local FuelID = acfmenupanel.FuelTankData.FuelID
	local Dims = Tanks[TankID].dims
	local Wall = 0.03937 --wall thickness in inches (1mm)
	local Volume = Dims.V - (Dims.S * Wall) -- total volume of tank (cu in), reduced by wall thickness
	local Capacity = Volume * ACF.CuIToLiter * ACF.TankVolumeMul * 0.4774 --internal volume available for fuel in liters, with magic realism number
	local EmptyMass = ((Dims.S * Wall) * 16.387) * (7.9 / 1000) -- total wall volume * cu in to cc * density of steel (kg/cc)
	local Mass = EmptyMass + Capacity * ACF.FuelDensity[FuelID] -- weight of tank + weight of fuel

	--fuel and tank info
	if FuelID == "Electric" then
		local kwh = Capacity * ACF.LiIonED
		acfmenupanel:CPanelText("TankName", Tanks[TankID].name .. " Li-Ion Battery")
		acfmenupanel:CPanelText("TankDesc", Tanks[TankID].desc .. "\n")
		acfmenupanel:CPanelText("Cap", "Charge: " .. math.Round(kwh, 1) .. " kW hours / " .. math.Round(kwh * 3.6, 1) .. " MJ")
		acfmenupanel:CPanelText("Mass", "Mass: " .. math.Round(Mass, 1) .. " kg")
	else
		acfmenupanel:CPanelText("TankName", Tanks[TankID].name .. " fuel tank")
		acfmenupanel:CPanelText("TankDesc", Tanks[TankID].desc .. "\n")
		acfmenupanel:CPanelText("Cap", "Capacity: " .. math.Round(Capacity, 1) .. " liters / " .. math.Round(Capacity * 0.264172, 1) .. " gallons")
		acfmenupanel:CPanelText("Mass", "Full mass: " .. math.Round(Mass, 1) .. " kg, Empty mass: " .. math.Round(EmptyMass, 1) .. " kg")
	end

	local text = "\n"

	if Tanks[TankID].nolinks then
		text = "\nThis fuel tank won\'t link to engines. It's intended to resupply fuel to other fuel tanks."
	end

	acfmenupanel:CPanelText("Links", text)

	--fuel tank model display
	if not acfmenupanel.CData.DisplayModel then
		acfmenupanel.CData.DisplayModel = vgui.Create("DModelPanel", acfmenupanel.CustomDisplay)
		acfmenupanel.CData.DisplayModel:SetModel(Tanks[TankID].model)
		acfmenupanel.CData.DisplayModel:SetCamPos(Vector(250, 500, 200))
		acfmenupanel.CData.DisplayModel:SetLookAt(Vector(0, 0, 0))
		acfmenupanel.CData.DisplayModel:SetFOV(10)
		acfmenupanel.CData.DisplayModel:SetSize(acfmenupanel:GetWide(), acfmenupanel:GetWide())
		acfmenupanel.CData.DisplayModel.LayoutEntity = function() end
		acfmenupanel.CustomDisplay:AddItem(acfmenupanel.CData.DisplayModel)
	end

	acfmenupanel.CData.DisplayModel:SetModel(Tanks[TankID].model)
end