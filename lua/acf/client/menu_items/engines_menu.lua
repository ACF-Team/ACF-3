local ACF         = ACF
local EngineTypes = ACF.Classes.EngineTypes
local FuelTypes   = ACF.Classes.FuelTypes
local FuelTanks   = ACF.Classes.FuelTanks
local Engines     = ACF.Classes.Engines
local RPMText = [[
	Idle RPM : %s RPM
	Powerband : %s-%s RPM
	Redline : %s RPM
	Mass : %s
	
	This entity can be fully parented.
	%s
	%s]]
local PowerText  = [[
	Peak Torque : %s n/m - %s ft-lb
	Peak Power : %s kW - %s HP @ %s RPM]]
local ConsumptionText = [[
	%s Consumption :
	%s L/min - %s gal/min @ %s RPM]]

-- Fuel consumption is increased on competitive servers
local function GetEfficiencyMult()
	return ACF.Gamemode == 3 and ACF.CompFuelRate or 1
end

local function UpdateEngineStats(Label, Data)
	local RPM        = Data.RPM
	local PeakkW     = Data.Torque * RPM.PeakMax / 9548.8
	local PeakkWRPM  = RPM.PeakMax
	local MinPower   = RPM.PeakMin
	local MaxPower   = RPM.PeakMax
	local Mass       = ACF.GetProperMass(Data.Mass)
	local Torque     = math.floor(Data.Torque)
	local TorqueFeet = math.floor(Data.Torque * 0.73)
	local Type       = EngineTypes[Data.Type]
	local Efficiency = Type.Efficiency * GetEfficiencyMult()
	local FuelList   = ""

	-- Electric motors and turbines get peak power in middle of rpm range
	if Data.IsElectric then
		PeakkW = Data.Torque * (1 + RPM.PeakMax / RPM.Limit) * RPM.Limit / (4 * 9548.8)
		PeakkWRPM = math.floor(RPM.Limit * 0.5)
		MinPower = RPM.Idle
		MaxPower = PeakkWRPM
	end

	for K in pairs(Data.Fuel) do
		if not FuelTypes[K] then continue end

		local Fuel = FuelTypes[K]
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

	local Power = PowerText:format(Torque, TorqueFeet, math.floor(PeakkW), math.floor(PeakkW * 1.34), PeakkWRPM)

	Label:SetText(RPMText:format(RPM.Idle, MinPower, MaxPower, RPM.Limit, Mass, FuelList, Power))
end

local function CreateMenu(Menu)
	Menu:AddTitle("Engine Settings")

	local EngineClass = Menu:AddComboBox()
	local EngineList = Menu:AddComboBox()

	local EngineBase = Menu:AddCollapsible("Engine Information")
	local EngineName = EngineBase:AddTitle()
	local EngineDesc = EngineBase:AddLabel()
	local EnginePreview = EngineBase:AddModelPreview()
	local EngineStats = EngineBase:AddLabel()

	Menu:AddTitle("Fuel Tank Settings")

	local FuelClass = Menu:AddComboBox()
	local FuelList = Menu:AddComboBox()
	local FuelType = Menu:AddComboBox()
	local FuelBase = Menu:AddCollapsible("Fuel Tank Information")
	local FuelDesc = FuelBase:AddLabel()
	local FuelPreview = FuelBase:AddModelPreview()
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

		local Preview = Data.Preview
		local ClassData = EngineClass.Selected
		local ClassDesc = ClassData.Description

		ACF.SetClientData("Engine", Data.ID)

		EngineName:SetText(Data.Name)
		EngineDesc:SetText((ClassDesc and (ClassDesc .. "\n\n") or "") .. Data.Description)

		EnginePreview:SetModel(Data.Model)
		EnginePreview:SetCamPos(Preview and Preview.Offset or Vector(45, 60, 45))
		EnginePreview:SetLookAt(Preview and Preview.Position or Vector())
		EnginePreview:SetHeight(Preview and Preview.Height or 80)
		EnginePreview:SetFOV(Preview and Preview.FOV or 75)

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

		local Preview = Data.Preview
		local ClassData = FuelClass.Selected
		local ClassDesc = ClassData.Description

		self.Description = (ClassDesc and (ClassDesc .. "\n\n") or "") .. Data.Description

		ACF.SetClientData("FuelTank", Data.ID)

		FuelPreview:SetModel(Data.Model)
		FuelPreview:SetCamPos(Preview and Preview.Offset or Vector(45, 60, 45))
		FuelPreview:SetLookAt(Preview and Preview.Position or Vector())
		FuelPreview:SetHeight(Preview and Preview.Height or 80)
		FuelPreview:SetFOV(Preview and Preview.FOV or 75)

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

		local Wall		= 0.03937 --wall thickness in inches (1mm)
		local Volume	= FuelTank.Volume - (FuelTank.SurfaceArea * Wall) -- total volume of tank (cu in), reduced by wall thickness
		local Capacity	= Volume * ACF.CuIToLiter * ACF.TankVolumeMul * 0.4774 --internal volume available for fuel in liters, with magic realism number
		local EmptyMass	= FuelTank.SurfaceArea * Wall * 16.387 * 0.0079 -- total wall volume * cu in to cc * density of steel (kg/cc)
		local Mass		= EmptyMass + Capacity * self.Selected.Density -- weight of tank + weight of fuel

		if TextFunc then
			FuelText = FuelText .. TextFunc(Capacity, Mass, EmptyMass)
		else
			local Text = "Capacity : %s L - %s gal\nFull Mass : %s\nEmpty Mass : %s\n\nThis entity can be fully parented."
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

	ACF.LoadSortedList(EngineClass, Engines, "ID")
	ACF.LoadSortedList(FuelClass, FuelTanks, "ID")
end

ACF.AddMenuItem(201, "Entities", "Engines", "car", CreateMenu)
