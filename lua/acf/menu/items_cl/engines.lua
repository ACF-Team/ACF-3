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
local TankSize    = Vector()

local FuelDescSentences = {
	"Seriously consider walking.",
	"Will keep a kart running all day.",
	"Dinghy.",
	"Outboard motor.",
	"Clown car.",
	"Fuel pancake.",
	"Lawn tractors.",
	"Small tractor tank.",
	"Fuel. Will keep you going for awhile.",
	"Gas stations? We don't need no stinking gas stations!",
	"Beep beep.",
	"Mini Cooper.",
	"Good bit of go-juice.",
	"Land boat.",
	"Conformal fuel tank; fits narrow spaces.",
	"Compact car.",
	"Sedan.",
	"Truck.",
	"With great capacity, comes great responsibili--VROOOOM",
	"Popular with arsonists.",
	"Fire juice.",
	"Trees are gay anyway.",
	"Arson material.",
	"What's a gas station?",
	"\'MURRICA FUCKYEAH!",
	"Got gas?",
	"Drive across the desert without a fuck to give.",
	"May contain Mesozoic ghosts.",
	"Conformal fuel tank; does what all its friends do.",
	"Certified 100% dinosaur juice.",
	"Will last you a while.",
	"Sloshy sloshy!",
	"What's global warming?",
	"Tank Tank.",
}

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
	local FuelType = Menu:AddComboBox()
	local FuelClass = Menu:AddComboBox()

	local Min = ACF.FuelMinSize
	local Max = ACF.FuelMaxSize

	local SizeX = Menu:AddSlider("Tank Length", Min, Max)
	SizeX:SetClientData("TankSizeX", "OnValueChanged")
	SizeX:DefineSetter(function(Panel, _, _, Value)
		local X = math.Round(Value)

		Panel:SetValue(X)

		TankSize.x = X

		FuelType:UpdateFuelText()

		return X
	end)

	local SizeY = Menu:AddSlider("Tank Width", Min, Max)
	SizeY:SetClientData("TankSizeY", "OnValueChanged")
	SizeY:DefineSetter(function(Panel, _, _, Value)
		local Y = math.Round(Value)

		Panel:SetValue(Y)

		TankSize.y = Y

		FuelType:UpdateFuelText()

		return Y
	end)

	local SizeZ = Menu:AddSlider("Tank Height", Min, Max)
	SizeZ:SetClientData("TankSizeZ", "OnValueChanged")
	SizeZ:DefineSetter(function(Panel, _, _, Value)
		local Z = math.Round(Value)

		Panel:SetValue(Z)

		TankSize.z = Z

		FuelType:UpdateFuelText()

		return Z
	end)

	local FuelList = Menu:AddComboBox()
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

		if Data.ID == "FTS_B" then -- Scalable box tanks
			SizeX:SetVisible(true)
			SizeY:SetVisible(true)
			SizeZ:SetVisible(true)
			FuelList:SetVisible(false)

			SizeX:SetText("Tank Length")
			SizeZ:SetText("Tank Height")
		elseif Data.ID == "FTS_D" then -- Scalable drum tanks
			SizeX:SetVisible(true)
			SizeY:SetVisible(false)
			-- Purposely hide height slider before showing to prevent a minor visual bug when switching from box to drum
			SizeZ:SetVisible(false)
			SizeZ:SetVisible(true)
			FuelList:SetVisible(false)

			SizeX:SetText("Drum Diameter")
			SizeZ:SetText("Drum Height")
		else -- Non-scalable tanks
			SizeX:SetVisible(false)
			SizeY:SetVisible(false)
			SizeZ:SetVisible(false)
			FuelList:SetVisible(true)
		end
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
		local FuelDescText = ""

		local Wall = ACF.FuelArmor * ACF.MmToInch -- Wall thickness in inches
		local TankID = FuelTank.ID
		local Volume, Area

		if TankID == "Box" then
			local InteriorVolume = (TankSize.x - Wall) * (TankSize.y - Wall) * (TankSize.z - Wall) -- Math degree
			Area = (2 * TankSize.x * TankSize.y) + (2 * TankSize.y * TankSize.z) + (2 * TankSize.x * TankSize.z)

			Volume = InteriorVolume - (Area * Wall)

			-- Preserving flavor text from older fuel tank sizes
			FuelDescText = FuelDescSentences[math.random(33)]
		elseif TankID == "Drum" then
			local Radius = TankSize.x / 2
			local InteriorVolume = math.pi * ((Radius - Wall) ^ 2) * (TankSize.z - Wall)
			Area = 2 * math.pi * Radius * (Radius + TankSize.z)

			Volume = InteriorVolume - (Area * Wall)

			FuelDescText = ""
		else
			Area = FuelTank.SurfaceArea
			Volume = FuelTank.Volume - (FuelTank.SurfaceArea * Wall) -- Total volume of tank (cu in), reduced by wall thickness

			FuelDescText = ""
		end

		local Capacity	= Volume * ACF.gCmToKgIn * ACF.TankVolumeMul * 0.4774 -- Internal volume available for fuel in liters, with magic realism number
		local EmptyMass	= Area * Wall * 16.387 * 0.0079 -- Total wall volume * cu in to cc * density of steel (kg/cc)
		local Mass		= EmptyMass + Capacity * self.Selected.Density -- Weight of tank + weight of fuel

		if TextFunc then
			FuelText = FuelText .. TextFunc(Capacity, Mass, EmptyMass)
		else
			local Text = "Tank Armor : %s mm\nCapacity : %s L - %s gal\nFull Mass : %s\nEmpty Mass : %s"
			local Liters = math.Round(Capacity, 2)
			local Gallons = math.Round(Capacity * 0.264172, 2)

			FuelText = FuelText .. Text:format(ACF.FuelArmor, Liters, Gallons, ACF.GetProperMass(Mass), ACF.GetProperMass(EmptyMass))
		end

		if not FuelTank.IsExplosive then
			FuelText = FuelText .. "\n\nThis fuel tank won't explode if damaged."
		end

		if FuelTank.Unlinkable then
			FuelText = FuelText .. "\n\nThis fuel tank cannot be linked to other ACF entities."
		end

		FuelDesc:SetText(FuelList.Description .. FuelDescText)
		FuelInfo:SetText(FuelText)
	end

	ACF.LoadSortedList(EngineClass, EngineEntries, "ID")
	ACF.LoadSortedList(FuelClass, FuelEntries, "ID")
end

ACF.AddMenuItem(201, "Entities", "Engines", "car", CreateMenu)