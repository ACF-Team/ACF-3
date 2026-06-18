local ACF         = ACF
local Classes     = ACF.Classes
local EngineTypes = Classes.EngineTypes
local Engines     = Classes.Engines
local TankSize    = Vector()
local DefaultShape = "ACF.ContainerShapes.Box"
local HPColor     = Color(255, 65, 65)
local TorqueColor = Color(65, 65, 255)
local IdleColor   = Color(127, 0, 0)

local acf_menu_multiplytorquemult = CreateClientConVar("acf_menu_multiplytorquemult", "0", true, false, "If true, engine power/torque elements in the menu & overlay will be multiplied by the internal torque multiplier.\nIt should be noted that the torque multiplier is a temporary stopgap for internal code issues, and will be removed in a future mobility update.")

local function GetTorqueMult() return acf_menu_multiplytorquemult:GetBool() and ACF.GetServerData("TorqueMult") or 1 end
local function UpdateEngineStats(Label, Data)
	local RPM        = Data.RPM
	local PeakTqRPM  = math.Round(Data.PeakTqRPM)
	local PeakkW     = Data.PeakPower * GetTorqueMult()
	local PeakkWRPM  = Data.PeakPowerRPM
	local MinPower   = RPM.PeakMin
	local MaxPower   = RPM.PeakMax
	local Mass       = ACF.GetProperMass(Data.Mass)
	local Torque     = math.Round(Data.Torque * GetTorqueMult())
	local TorqueFeet = math.Round(Data.Torque * GetTorqueMult() * ACF.NmToFtLb)
	local Type       = EngineTypes.Get(Data.Type)
	local Efficiency = Type.Efficiency
	local FuelList   = ""

	local RPMText         = language.GetPhrase("acf.menu.engines.rpm_stats")
	local PowerText       = language.GetPhrase("acf.menu.engines.power_stats")
	local ConsumptionText = language.GetPhrase("acf.menu.engines.consumption_stats")

	for K in pairs(Data.Fuel) do
		local Fuel = Classes.GetTypeByName("ACF.FuelTypes." .. tostring(K))

		if not Fuel then continue end

		local AddText = ""

		if Fuel.ConsumptionText then
			AddText = Fuel.ConsumptionText(PeakkW, PeakkWRPM, Efficiency, Type, Fuel)
		else
			local Rate = ACF.FuelRate * Efficiency * PeakkW / (60 * Fuel.Density)

			AddText = ConsumptionText:format(Fuel.Name, math.Round(Rate, 2), math.Round(Rate * ACF.LToGal, 2), PeakkWRPM)
		end

		FuelList = FuelList .. "\n" .. AddText .. "\n"

		Data.Fuel[K] = Fuel -- TODO: Replace once engines use the proper class functions
	end

	local Power = PowerText:format(Torque, TorqueFeet, PeakTqRPM, math.Round(PeakkW), math.Round(PeakkW * ACF.KwToHp), PeakkWRPM)

	Label:SetText(RPMText:format(RPM.Idle, MinPower, MaxPower, RPM.Limit, Mass, FuelList, Power))
end

local function CreateMenu(Menu)
	local EngineEntries = Engines.GetEntries()
	-- local FuelEntries   = FuelTanks.GetEntries()

	Menu:AddTitle("#acf.menu.engines.settings")

	Menu:AddWikiLink("Engines", "docs/acf_tutorials/engines.html")

	local EngineClass = Menu:AddComboBox()
	EngineClass:SetName("EngineClass")
	local EngineList = Menu:AddComboBox()
	EngineList:SetName("EngineList")

	local EngineBase = Menu:AddCollapsible("#acf.menu.engines.engine_info", nil, "icon16/monitor_edit.png")
	local EngineName = EngineBase:AddTitle()
	local EngineDesc = EngineBase:AddLabel()
	local EnginePreview = EngineBase:AddModelPreview(nil, true, "Primary")
	local EngineStats = EngineBase:AddLabel()

	local PowerGraph = Menu:AddGraph()
	local PGWidth = Menu:GetWide()
	PowerGraph:SetSize(PGWidth, PGWidth / 2)

	PowerGraph:SetXLabel("#acf.menu.engines.rpm")
	PowerGraph:SetYLabel("#acf.menu.engines.times_100")
	PowerGraph:SetXSpacing(1000)
	PowerGraph:SetYSpacing(100)
	PowerGraph:SetFidelity(24)

	Menu:AddTitle("#acf.menu.fuel.settings")
	local FuelType = Menu:AddComboBox()

	-- Shape selector
	local FuelShape = Menu:AddComboBox()
	local FuelShapeOptions = Classes.GetChildren(Classes.GetTypeByName("ACF.ContainerShapes.BaseContainerShape"))

	do
		local Selected, SelectedShapeType = 1, "ACF.ContainerShapes.Box"
		for _, ShapeType in pairs(FuelShapeOptions) do
			local ID = FuelShape:AddChoice(ShapeType.Name, ShapeType)
			local TypeName = Classes.GetTypeName(ShapeType)
			if TypeName == ACF.GetClientData("Shape") then
				Selected = ID
				SelectedShapeType = TypeName
			end
		end

		-- Set default shape
		ACF.SetClientData("Shape", SelectedShapeType, true)
		FuelShape:ChooseOptionID(Selected)

		-- FuelPreview is created after this combo; re-run OnSelect once it exists to set the model.
		timer.Simple(0, function() if IsValid(FuelShape) then FuelShape:OnSelect(nil, nil, SelectedShapeType) end end)
	end
	local Min = ACF.ContainerMinSize
	local Max = ACF.ContainerMaxSize
	local FuelPreview

	-- Size sliders drive the single Vector "Size" client data var (eager-pushed by the helper).
	TankSize = select(4, Menu:AddSizeSliders("Size", Min, Max, Vector(24, 24, 24), function(Size)
		FuelType:UpdateFuelText()

		if FuelPreview then
			FuelPreview:SetModelScale(Size * 12)
		end
	end, {"#acf.menu.fuel.tank_length", "#acf.menu.fuel.tank_width", "#acf.menu.fuel.tank_height"}))

	local FuelBase = Menu:AddCollapsible("#acf.menu.fuel.tank_info", nil, "icon16/cup_edit.png")
	local FuelDesc = FuelBase:AddLabel()
	FuelPreview = FuelBase:AddModelPreview(nil, true, "Secondary")
	local FuelInfo = FuelBase:AddLabel()

	ACF.SetClientData("PrimaryClass", "acf_engine")
	ACF.SetClientData("SecondaryClass", "acf_fueltank")
	ACF.SetClientData("FuelTank", "ACF.FuelTanks.ScalableFuelTank") -- Set default fuel tank to scalable

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
		EngineDesc:SetText((ClassDesc and (language.GetPhrase(ClassDesc) .. "\n\n") or "") .. language.GetPhrase(Data.Description))

		EnginePreview:UpdateModel(Data.Model)
		EnginePreview:UpdateSettings(Data.Preview)

		UpdateEngineStats(EngineStats, Data)

		PowerGraph:SetXRange(0, Data.RPM.Limit)
		PowerGraph:SetYRange(0, math.max(math.ceil(Data.PeakPower * GetTorqueMult() * ACF.KwToHp), Data.Torque * GetTorqueMult()) * 1.1)
		PowerGraph:SetFidelity(10)

		PowerGraph:Clear()
		PowerGraph:PlotPoint(language.GetPhrase("acf.menu.engines.peak_hp"), Data.PeakPowerRPM, math.Round(Data.PeakPower * GetTorqueMult() * ACF.KwToHp), HPColor)
		PowerGraph:PlotPoint(language.GetPhrase("acf.menu.engines.peak_nm"), Data.PeakTqRPM, math.Round(Data.Torque * GetTorqueMult()), TorqueColor)

		PowerGraph:PlotLimitFunction(language.GetPhrase("acf.menu.engines.torque"), Data.RPM.Idle, Data.RPM.Limit, TorqueColor, function(X)
			return ACF.GetTorque(Data.TorqueCurve, math.Remap(X, Data.RPM.Idle, Data.RPM.Limit, 0, 1)) * Data.Torque * GetTorqueMult()
		end)

		PowerGraph:PlotLimitFunction(language.GetPhrase("acf.menu.engines.hp"), Data.RPM.Idle, Data.RPM.Limit, HPColor, function(X)
			return (ACF.GetTorque(Data.TorqueCurve, math.Remap(X, Data.RPM.Idle, Data.RPM.Limit, 0, 1)) * Data.Torque * GetTorqueMult() * X) * ACF.KwToHp / 9548.8
		end)

		PowerGraph:PlotLimitLine(language.GetPhrase("acf.menu.engines.idle_rpm"), false, Data.RPM.Idle, IdleColor)

		ACF.LoadSortedList(FuelType, Data.Fuel, "ID")
	end

	function FuelShape:OnSelect(_, _, Data)
		-- Data may be a shape class object (real selection) or an FQN string (default re-trigger).
		local ShapeClass = istable(Data) and Data or Classes.GetTypeByName(Data) or Classes.GetTypeByName(DefaultShape)
		local TypeName   = Classes.GetTypeName(ShapeClass)
		local ShapeName  = ShapeClass.Name or "Box"

		ACF.SetClientData("Shape", TypeName)

		-- Update preview model based on shape
		if IsValid(FuelPreview) then
			FuelPreview:UpdateModel(ACF.ContainerShapeModels[ShapeName] or "models/props_canal/metalcrate001d", "models/props_canal/metalcrate001d")
		end

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

		local TextFunc = self.Selected.FuelTankText
		local FuelText = ""

		local Wall = ACF.ContainerArmor * ACF.MmToInch -- Wall thickness in inches
		local ShapeData  = ACF.GetClientData("Shape")
		local ShapeClass = istable(ShapeData) and ShapeData or Classes.GetTypeByName(ShapeData)
		local Shape      = (ShapeClass and ShapeClass.Name) or "Box"

		-- Calculate volume and area using shape calculations
		local Volume, Area = (ACF.ContainerShapes[Shape] or ACF.ContainerShapes.Box)(TankSize, Wall)

		local Capacity	= Volume * ACF.gCmToKgIn -- Internal volume available for fuel in liters
		local EmptyMass	= Area * Wall * ACF.InchToCmCu * ACF.SteelDensity -- Total wall volume * cu in to cc * density of steel (kg/cc)
		local Mass		= EmptyMass + Capacity * self.Selected.Density -- Weight of tank + weight of fuel

		if TextFunc then
			FuelText = FuelText .. TextFunc(Capacity, Mass, EmptyMass)
		else
			local Text = language.GetPhrase("acf.menu.fuel.tank_stats")
			local Liters = math.Round(Capacity, 2)
			local Gallons = math.Round(Capacity * ACF.LToGal, 2)

			FuelText = FuelText .. Text:format(ACF.ContainerArmor, Liters, Gallons, ACF.GetProperMass(Mass), ACF.GetProperMass(EmptyMass))
		end

		FuelDesc:SetText("Scalable Fuel Tank\n\nShape: " .. Shape)
		FuelInfo:SetText(FuelText)
	end

	ACF.LoadSortedList(EngineClass, EngineEntries, "ID")
end

ACF.AddMenuItem(201, "#acf.menu.entities", "#acf.menu.engines", "car", CreateMenu)