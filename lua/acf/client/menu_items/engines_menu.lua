local EngineTypes = ACF.Classes.EngineTypes
local FuelTypes = ACF.Classes.FuelTypes
local FuelTanks = ACF.Classes.FuelTanks
local Engines = ACF.Classes.Engines
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

local function UpdateEngineStats(Label, Data)
	local RPM = Data.RPM
	local PeakkW = Data.Torque * RPM.PeakMax / 9548.8
	local PeakkWRPM = RPM.PeakMax
	local MinPower = RPM.PeakMin
	local MaxPower = RPM.PeakMax

	local RPMText = "Idle RPM : %s RPM\nPowerband : %s-%s RPM\nRedline : %s RPM\nMass : %s"
	local LabelText = ""

	-- Electric motors and turbines get peak power in middle of rpm range
	if Data.IsElectric then
		PeakkW = Data.Torque * (1 + RPM.PeakMax / RPM.Limit) * RPM.Limit / (4 * 9548.8)
		PeakkWRPM = math.floor(RPM.Limit * 0.5)
		MinPower = RPM.Idle
		MaxPower = PeakkWRPM
	end

	LabelText = LabelText .. RPMText:format(RPM.Idle, MinPower, MaxPower, RPM.Limit, ACF.GetProperMass(Data.Mass))

	local TorqueText = "\nPeak Torque : %s n/m - %s ft-lb"
	local PowerText = "\nPeak Power : %s kW - %s HP @ %s RPM"
	local Consumption, Power = "", ""

	for K in pairs(Data.Fuel) do
		if not FuelTypes[K] then continue end

		local Type = EngineTypes[Data.Type]
		local Fuel = FuelTypes[K]
		local AddText = ""

		if Fuel.ConsumptionText then
			AddText = Fuel.ConsumptionText(PeakkW, PeakkWRPM, Type, Fuel)
		else
			local Text = "\n\n%s Consumption :\n%s L/min - %s gal/min @ %s RPM"
			local Rate = ACF.FuelRate * Type.Efficiency * PeakkW / (60 * Fuel.Density)

			AddText = Text:format(Fuel.Name, math.Round(Rate, 2), math.Round(Rate * 0.264, 2), PeakkWRPM)
		end

		Consumption = Consumption .. AddText .. "\n\nThis engine requires fuel."

		Data.Fuel[K] = Fuel -- Replace once engines use the proper class functions
	end

	Power = Power .. "\n" .. PowerText:format(math.floor(PeakkW), math.floor(PeakkW * 1.34), PeakkWRPM)
	Power = Power .. TorqueText:format(math.floor(Data.Torque), math.floor(Data.Torque * 0.73))

	LabelText = LabelText .. Consumption .. Power

	Label:SetText(LabelText)
end

local function CreateMenu(Menu)
	local EngineClass = Menu:AddComboBox()
	local EngineList = Menu:AddComboBox()
	local EngineName = Menu:AddTitle()
	local EngineDesc = Menu:AddLabel()
	local EngineStats = Menu:AddLabel()

	Menu:AddTitle("Fuel Settings")

	local FuelClass = Menu:AddComboBox()
	local FuelList = Menu:AddComboBox()
	local FuelType = Menu:AddComboBox()
	local FuelDesc = Menu:AddLabel()

	ACF.WriteValue("PrimaryClass", "acf_engine")
	ACF.WriteValue("SecondaryClass", "acf_fueltank")

	ACF.SetToolMode("acf_menu2", "Main", "Spawner")

	function EngineClass:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.Selected = Data

		local Choices = Sorted[Engines]
		Selected[Choices] = Index

		ACF.WriteValue("EngineClass", Data.ID)

		LoadSortedList(EngineList, Data.Items, "Mass")
	end

	function EngineList:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.Selected = Data

		local ClassData = EngineClass.Selected
		local ClassDesc = ClassData.Description
		local Choices = Sorted[ClassData.Items]
		Selected[Choices] = Index

		ACF.WriteValue("Engine", Data.ID)

		EngineName:SetText(Data.Name)
		EngineDesc:SetText((ClassDesc and (ClassDesc .. "\n\n") or "") .. Data.Description)

		UpdateEngineStats(EngineStats, Data)

		LoadSortedList(FuelType, Data.Fuel, "ID")
	end

	function FuelClass:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.Selected = Data

		local Choices = Sorted[FuelTanks]
		Selected[Choices] = Index

		LoadSortedList(FuelList, Data.Items, "ID")
	end

	function FuelList:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.Selected = Data

		local ClassData = FuelClass.Selected
		local ClassDesc = ClassData.Description
		local Choices = Sorted[ClassData.Items]
		Selected[Choices] = Index

		self.Description = (ClassDesc and (ClassDesc .. "\n\n") or "") .. Data.Description

		ACF.WriteValue("FuelTank", Data.ID)

		FuelType:UpdateFuelText()
	end

	function FuelType:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.Selected = Data

		local ClassData = EngineList.Selected
		local Choices = Sorted[ClassData.Fuel]
		Selected[Choices] = Index

		ACF.WriteValue("FuelType", Data.ID)

		self:UpdateFuelText()
	end

	function FuelType:UpdateFuelText()
		if not self.Selected then return end
		if not FuelList.Selected then return end

		local FuelTank = FuelList.Selected
		local FuelText = FuelList.Description
		local TextFunc = self.Selected.FuelTankText

		local Wall		= 0.03937 --wall thickness in inches (1mm)
		local Volume	= FuelTank.Volume - (FuelTank.SurfaceArea * Wall) -- total volume of tank (cu in), reduced by wall thickness
		local Capacity	= Volume * ACF.CuIToLiter * ACF.TankVolumeMul * 0.4774 --internal volume available for fuel in liters, with magic realism number
		local EmptyMass	= FuelTank.SurfaceArea * Wall * 16.387 * 0.0079 -- total wall volume * cu in to cc * density of steel (kg/cc)
		local Mass		= EmptyMass + Capacity * self.Selected.Density -- weight of tank + weight of fuel

		if TextFunc then
			FuelText = FuelText .. TextFunc(Capacity, Mass, EmptyMass)
		else
			local Text = "\n\nCapacity : %s L - %s gal\nFull Mass : %s\nEmpty Mass : %s"
			local Liters = math.Round(Capacity, 2)
			local Gallons = math.Round(Capacity * 0.264172, 2)

			FuelText = FuelText .. Text:format(Liters, Gallons, ACF.GetProperMass(Mass), ACF.GetProperMass(EmptyMass))
		end

		if not FuelTank.IsExplosive then
			FuelText = FuelText .. "\n\nThis fuel tank won't explode if damaged."
		end

		if FuelTank.Unlinkable then
			FuelText = FuelText .. "\n\nThis fuel tank cannot be linked to other ACF entities."
		end

		FuelDesc:SetText(FuelText)
	end

	LoadSortedList(EngineClass, Engines, "ID")
	LoadSortedList(FuelClass, FuelTanks, "ID")
end

ACF.AddOptionItem("Entities", "Engines", "car", CreateMenu)
