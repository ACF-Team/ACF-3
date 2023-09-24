local ACF         = ACF
local Classes     = ACF.Classes
local EngineTypes = Classes.EngineTypes
local FuelTypes   = Classes.FuelTypes
local FuelTanks   = Classes.FuelTanks
local Engines     = Classes.Engines
local RPMText = [[
	Idle RPM : %s RPM
	Powerband : %s-%s RPM
	Redline : %s RPM
	Mass : %s

	%s
	%s]]
local PowerText  = [[
	Peak Torque : %s Nm - %s ft-lb @ %s RPM
	Peak Power : %s kW - %s HP @ %s RPM]]
local ConsumptionText = [[
	%s Consumption :
	%s L/min - %s gal/min @ %s RPM]]

local function UpdateEngineStats(Label, Data)
	local RPM        = Data.RPM
	local PeakTqRPM  = math.Round(Data.PeakTqRPM)
	local PeakkW     = Data.PeakPower
	local PeakkWRPM  = Data.PeakPowerRPM
	local MinPower   = RPM.PeakMin
	local MaxPower   = RPM.PeakMax
	local Mass       = ACF.GetProperMass(Data.Mass)
	local Torque     = math.Round(Data.Torque)
	local TorqueFeet = math.Round(Data.Torque * 0.73)
	local Type       = EngineTypes.Get(Data.Type)
	local Efficiency = Type.Efficiency
	local FuelList   = ""

	for K in pairs(Data.Fuel) do
		local Fuel = FuelTypes.Get(K)

		if not Fuel then continue end

		local AddText = ""

		if Fuel.ConsumptionText then
			AddText = Fuel.ConsumptionText(PeakkW, PeakkWRPM, Efficiency, Type, Fuel)
		else
			local Rate = ACF.FuelRate * Efficiency * PeakkW / (60 * Fuel.Density)

			AddText = ConsumptionText:format(Fuel.Name, math.Round(Rate, 2), math.Round(Rate * 0.264, 2), PeakkWRPM)
		end

		FuelList = FuelList .. "\n" .. AddText .. "\n"

		Data.Fuel[K] = Fuel -- TODO: Replace once engines use the proper class functions
	end

	local Power = PowerText:format(Torque, TorqueFeet, PeakTqRPM, math.Round(PeakkW), math.Round(PeakkW * 1.34), PeakkWRPM)

	Label:SetText(RPMText:format(RPM.Idle, MinPower, MaxPower, RPM.Limit, Mass, FuelList, Power))
end

local function CreateMenu(Menu)
	local EngineEntries = Engines.GetEntries()
	local FuelEntries   = FuelTanks.GetEntries()

	Menu:AddTitle("Engine Settings")

	local EngineClass = Menu:AddComboBox()
	local EngineList = Menu:AddComboBox()

	local EngineBase = Menu:AddCollapsible("Engine Information")
	local EngineName = EngineBase:AddTitle()
	local EngineDesc = EngineBase:AddLabel()
	local EnginePreview = EngineBase:AddModelPreview(nil, true)
	local EngineStats = EngineBase:AddLabel()

	Menu:AddTitle("Fuel Tank Settings")

	local FuelClass = Menu:AddComboBox()
	local FuelList = Menu:AddComboBox()
	local FuelType = Menu:AddComboBox()
	local FuelBase = Menu:AddCollapsible("Fuel Tank Information")
	local FuelDesc = FuelBase:AddLabel()
	local FuelPreview = FuelBase:AddModelPreview(nil, true)
	local FuelInfo = FuelBase:AddLabel()

	ACF.SetClientData("PrimaryClass", "acf_engine")
	ACF.SetClientData("SecondaryClass", "acf_fueltank")

	ACF.SetToolMode("acf_menu", "Spawner", "Engine")

	function EngineClass:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.ListData.Index = Index
		self.Selected = Data

		ACF.SetClientData("EngineClass", Data.ID)

		ACF.LoadSortedList(EngineList, Data.Items, "Mass")
	end

	function EngineList:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.ListData.Index = Index
		self.Selected = Data

		local ClassData = EngineClass.Selected
		local ClassDesc = ClassData.Description

		ACF.SetClientData("Engine", Data.ID)

		EngineName:SetText(Data.Name)
		EngineDesc:SetText((ClassDesc and (ClassDesc .. "\n\n") or "") .. Data.Description)

		EnginePreview:UpdateModel(Data.Model)
		EnginePreview:UpdateSettings(Data.Preview)

		UpdateEngineStats(EngineStats, Data)

		ACF.LoadSortedList(FuelType, Data.Fuel, "ID")
	end

	function FuelClass:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.ListData.Index = Index
		self.Selected = Data

		ACF.LoadSortedList(FuelList, Data.Items, "ID")
	end

	function FuelList:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.ListData.Index = Index
		self.Selected = Data

		local ClassData = FuelClass.Selected
		local ClassDesc = ClassData.Description

		self.Description = (ClassDesc and (ClassDesc .. "\n\n") or "") .. Data.Description

		ACF.SetClientData("FuelTank", Data.ID)

		FuelPreview:UpdateModel(Data.Model)
		FuelPreview:UpdateSettings(Data.Preview)

		FuelType:UpdateFuelText()
	end

	function FuelType:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.ListData.Index = Index
		self.Selected = Data

		ACF.SetClientData("FuelType", Data.ID)

		self:UpdateFuelText()
	end

	function FuelType:UpdateFuelText()
		if not self.Selected then return end
		if not FuelList.Selected then return end

		local FuelTank = FuelList.Selected
		local TextFunc = self.Selected.FuelTankText
		local FuelText = ""

		local Wall		= 0.03937 -- Wall thickness in inches (1mm)
		local Volume	= FuelTank.Volume - (FuelTank.SurfaceArea * Wall) -- Total volume of tank (cu in), reduced by wall thickness
		local Capacity	= Volume * ACF.gCmToKgIn * ACF.TankVolumeMul * 0.4774 -- Internal volume available for fuel in liters, with magic realism number
		local EmptyMass	= FuelTank.SurfaceArea * Wall * 16.387 * 0.0079 -- Total wall volume * cu in to cc * density of steel (kg/cc)
		local Mass		= EmptyMass + Capacity * self.Selected.Density -- Weight of tank + weight of fuel

		if TextFunc then
			FuelText = FuelText .. TextFunc(Capacity, Mass, EmptyMass)
		else
			local Text = "Capacity : %s L - %s gal\nFull Mass : %s\nEmpty Mass : %s\n"
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

		FuelDesc:SetText(FuelList.Description)
		FuelInfo:SetText(FuelText)
	end

	ACF.LoadSortedList(EngineClass, EngineEntries, "ID")
	ACF.LoadSortedList(FuelClass, FuelEntries, "ID")
end

ACF.AddMenuItem(201, "Entities", "Engines", "car", CreateMenu)