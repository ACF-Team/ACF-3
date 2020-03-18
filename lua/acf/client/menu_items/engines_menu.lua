local FuelTanks = ACF.Classes.FuelTanks
local Engines = ACF.Classes.Engines
local FuelDensity = ACF.FuelDensity
local Efficiency = ACF.Efficiency
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
	local Text = ""

	-- Electric motors and turbines get peak power in middle of rpm range
	if Data.IsElectric then
		PeakkW = Data.Torque * (1 + RPM.PeakMax / RPM.Limit) * RPM.Limit / (4 * 9548.8)
		PeakkWRPM = math.floor(RPM.Limit * 0.5)
		MinPower = RPM.Idle
		MaxPower = PeakkWRPM
	end

	Text = Text .. RPMText:format(RPM.Idle, MinPower, MaxPower, RPM.Limit, ACF.GetProperMass(Data.Mass))

	local TorqueText = "\nPeak Torque : %s n/m - %s ft-lb"
	local PowerText = "\nPeak Power : %s kW - %s HP @ %s RPM"
	local FuelText = "\n\nFuel Type : %s%s%s"
	local Consumption, Power = "", ""
	local Boost = Data.RequiresFuel and ACF.TorqueBoost or 1
	local Fuel = Data.Fuel

	if Fuel == "Electric" then
		local ElecText = "\nPeak Energy Consumption :\n%s kW - %s MJ/min"
		local ElecRate = ACF.ElecRate * PeakkW / Efficiency[Data.Type]

		Consumption = ElecText:format(math.Round(ElecRate, 2), math.Round(ElecRate * 0.06, 2))
	else
		local ConsumptionText = "\n%s Consumption :\n%s L/min - %s gal/min @ %s RPM"

		if Fuel == "Multifuel" or Fuel == "Diesel" then
			local FuelRate = ACF.FuelRate * Efficiency[Data.Type] * ACF.TorqueBoost * PeakkW / (60 * FuelDensity.Diesel)

			Consumption = Consumption .. ConsumptionText:format("Diesel", math.Round(FuelRate, 2), math.Round(FuelRate * 0.264, 2), PeakkWRPM)
		end

		if Fuel == "Multifuel" or Fuel == "Petrol" then
			local FuelRate = ACF.FuelRate * Efficiency[Data.Type] * ACF.TorqueBoost * PeakkW / (60 * FuelDensity.Petrol)

			Consumption = Consumption .. ConsumptionText:format("Petrol", math.Round(FuelRate, 2), math.Round(FuelRate * 0.264, 2), PeakkWRPM)
		end
	end

	Power = Power .. "\n" .. PowerText:format(math.floor(PeakkW * Boost), math.floor(PeakkW * Boost * 1.34), PeakkWRPM)
	Power = Power .. TorqueText:format(math.floor(Data.Torque * Boost), math.floor(Data.Torque * Boost * 0.73))

	if Data.RequiresFuel then
		Consumption = Consumption .. "\n\nThis engine requires fuel."
	else
		Power = Power .. "\n\nWhen Fueled :" .. PowerText:format(math.floor(PeakkW * ACF.TorqueBoost), math.floor(PeakkW * ACF.TorqueBoost * 1.34), PeakkWRPM)
		Power = Power .. TorqueText:format(math.floor(Data.Torque * ACF.TorqueBoost), math.floor(Data.Torque * ACF.TorqueBoost * 0.73))
	end

	Text = Text .. FuelText:format(Fuel, Consumption, Power)

	Label:SetText(Text)
end

local function CreateMenu(Menu)
	local EngineClass = Menu:AddComboBox()
	local EngineList = Menu:AddComboBox()
	local EngineName = Menu:AddTitle()
	local EngineDesc = Menu:AddLabel()
	local EngineStats = Menu:AddLabel()

	local FuelList = Menu:AddComboBox()

	ACF.WriteValue("PrimaryClass", "acf_engine")
	ACF.WriteValue("SecondaryClass", "acf_fueltank")

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
	end

	LoadSortedList(EngineClass, Engines, "ID")
	LoadSortedList(FuelList, FuelTanks, "ID")
end

ACF.AddOptionItem("Entities", "Engines", "car", CreateMenu)
