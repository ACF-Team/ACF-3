local ACF     = ACF
local Classes = ACF.Classes
local GetType = Classes.GetTypeByName
local PAGE    = "acf_engine"

local ENGINE_BASE = "ACF.Engines.BaseEngine"

local HPColor     = Color(255, 65, 65)
local TorqueColor = Color(65, 65, 255)
local IdleColor   = Color(127, 0, 0)

local acf_menu_multiplytorquemult = CreateClientConVar("acf_menu_multiplytorquemult", "0", true, false, "If true, engine power/torque elements in the menu & overlay will be multiplied by the internal torque multiplier.\nIt should be noted that the torque multiplier is a temporary stopgap for internal code issues, and will be removed in a future mobility update.")

local function GetTorqueMult() return acf_menu_multiplytorquemult:GetBool() and ACF.GetServerData("TorqueMult") or 1 end

local function GetEngineType(FQN) return Classes.GetSubtypeByName("ACF.EngineTypes.BaseEngineType", FQN) end
local function GetFuelType(FQN)   return Classes.GetSubtypeByName("ACF.FuelTypes.FuelType", FQN) end

local function UpdateEngineStats(Label, Data)
	local RPM        = Data.RPM
	local PeakTqRPM  = math.Round(Data.PeakTqRPM)
	local PeakkW     = Data.PeakPower * GetTorqueMult()
	local PeakkWRPM  = Data.PeakPowerRPM
	local Mass       = ACF.GetProperMass(Data.Mass)
	local Torque     = math.Round(Data.Torque * GetTorqueMult())
	local TorqueFeet = math.Round(Data.Torque * GetTorqueMult() * ACF.NmToFtLb)
	local Type       = GetEngineType(Data.Type)
	local Efficiency = Type.Efficiency
	local FuelList   = ""

	local RPMText         = language.GetPhrase("acf.menu.engines.rpm_stats")
	local PowerText       = language.GetPhrase("acf.menu.engines.power_stats")
	local ConsumptionText = language.GetPhrase("acf.menu.engines.consumption_stats")

	for K in pairs(Data.Fuel) do
		local Fuel = GetFuelType(K)
		if not Fuel then continue end

		local AddText
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

	Label:SetText(RPMText:format(RPM.Idle, RPM.PeakMin, RPM.PeakMax, RPM.Limit, Mass, FuelList, Power))
end

local function Build(Menu, Contexts)
	local Engine = Contexts.Engine
	local Fuel   = Contexts.Fuel
	local TankSize = Vector(Fuel:Get("FuelSizeX") or 24, Fuel:Get("FuelSizeY") or 24, Fuel:Get("FuelSizeZ") or 24)

	Menu:AddTitle("#acf.menu.engines.settings")
	Menu:AddWikiLink("Engines", "docs/acf_tutorials/engines.html")

	local EngineClass = Menu:AddComboBox()
	local EngineList  = Menu:AddComboBox()

	local EngineBase    = Menu:AddCollapsible("#acf.menu.engines.engine_info", nil, "icon16/monitor_edit.png")
	local EngineName    = EngineBase:AddTitle()
	local EngineDesc    = EngineBase:AddLabel()
	local EnginePreview = EngineBase:AddModelPreview(nil, true, "Primary")
	local EngineStats   = EngineBase:AddLabel()

	local PowerGraph = Menu:AddGraph()
	local PGWidth    = Menu:GetWide()
	PowerGraph:SetSize(PGWidth, PGWidth / 2)
	PowerGraph:SetXLabel("#acf.menu.engines.rpm")
	PowerGraph:SetYLabel("#acf.menu.engines.times_100")
	PowerGraph:SetXSpacing(1000)
	PowerGraph:SetYSpacing(100)
	PowerGraph:SetFidelity(24)

	Menu:AddTitle("#acf.menu.fuel.settings")
	local FuelType  = Menu:AddComboBox()
	local FuelShape = Menu:AddComboBox()
	FuelShape:AddChoice("Box", "ACF.ContainerShapes.Box")
	FuelShape:AddChoice("Sphere", "ACF.ContainerShapes.Sphere")
	FuelShape:AddChoice("Cylinder", "ACF.ContainerShapes.Cylinder")

	local Min = ACF.ContainerMinSize
	local Max = ACF.ContainerMaxSize

	local SizeX = Menu:AddSlider("#acf.menu.fuel.tank_length", Min, Max)
	local SizeY = Menu:AddSlider("#acf.menu.fuel.tank_width", Min, Max)
	local SizeZ = Menu:AddSlider("#acf.menu.fuel.tank_height", Min, Max)

	local FuelBase    = Menu:AddCollapsible("#acf.menu.fuel.tank_info", nil, "icon16/cup_edit.png")
	local FuelDesc    = FuelBase:AddLabel()
	local FuelPreview = FuelBase:AddModelPreview(nil, true, "Secondary")
	local FuelInfo    = FuelBase:AddLabel()

	function FuelType:UpdateFuelText()
		if not self.Selected then return end

		local Wall  = ACF.ContainerArmor * ACF.MmToInch
		local ShapeInst = Fuel:Get("Shape")
		local Shape = (ShapeInst and ShapeInst.GetType) and ShapeInst:GetType() or GetType("ACF.ContainerShapes.Box")

		local Volume, Area = Shape.ShapeCalculation(TankSize, Wall)

		local Capacity  = Volume * ACF.gCmToKgIn
		local EmptyMass = Area * Wall * ACF.InchToCmCu * ACF.SteelDensity
		local Mass      = EmptyMass + Capacity * self.Selected.Density

		local FuelText
		if self.Selected.FuelTankText then
			FuelText = self.Selected.FuelTankText(Capacity, Mass, EmptyMass)
		else
			local Text = language.GetPhrase("acf.menu.fuel.tank_stats")
			FuelText = Text:format(ACF.ContainerArmor, math.Round(Capacity, 2), math.Round(Capacity * ACF.LToGal, 2), ACF.GetProperMass(Mass), ACF.GetProperMass(EmptyMass))
		end

		FuelDesc:SetText("Scalable Fuel Tank\n\nShape: " .. (Shape.Name or "Box"))
		FuelInfo:SetText(FuelText)
	end

	local function ScalePreview()
		if IsValid(FuelPreview) then FuelPreview:SetModelScale(TankSize * 12) end
	end

	function EngineClass:OnSelect(Index, _, Data)
		if self.Selected == Data then return end
		self.ListData.Index = Index
		self.Selected = Data
		ACF.Menu.SaveClassCombo(PAGE, "group", Data)

		ACF.Menu.LoadClassCombo(EngineList, Classes.GetChildren(Data), "Mass", nil, PAGE, "engine")
	end

	function EngineList:OnSelect(Index, _, Data)
		if self.Selected == Data then return end
		self.ListData.Index = Index
		self.Selected = Data
		ACF.Menu.SaveClassCombo(PAGE, "engine", Data)

		local ClassDesc = EngineClass.Selected and EngineClass.Selected.Description

		Engine:Set("Engine", Classes.GetTypeName(Data))

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

		ACF.Menu.LoadClassCombo(FuelType, Data.Fuel, "ID", nil, PAGE, "fuel")
	end

	function FuelType:OnSelect(Index, _, Data)
		if self.Selected == Data then return end
		self.ListData.Index = Index
		self.Selected = Data
		ACF.Menu.SaveClassCombo(PAGE, "fuel", Data)

		Fuel:Set("FuelType", Classes.GetTypeName(Data))
		self:UpdateFuelText()
	end

	function FuelShape:OnSelect(_, _, Data)
		Fuel:Set("Shape", Data)

		local ShapeClass = GetType(Data) or GetType("ACF.ContainerShapes.Box")
		if IsValid(FuelPreview) then FuelPreview:UpdateModel(ShapeClass.Model, "models/props_canal/metalcrate001d") end

		FuelType:UpdateFuelText()
	end

	local function BindSize(Slider, Axis, Field)
		function Slider:OnValueChanged(Value)
			local N = math.Round(Value)
			self:SetValue(N)
			TankSize[Axis] = N
			Fuel:Set(Field, N)
			FuelType:UpdateFuelText()
			ScalePreview()
		end
	end

	BindSize(SizeX, "x", "FuelSizeX")
	BindSize(SizeY, "y", "FuelSizeY")
	BindSize(SizeZ, "z", "FuelSizeZ")

	ACF.Menu.LoadClassCombo(EngineClass, Classes.GetChildren(GetType(ENGINE_BASE)), "Name", nil, PAGE, "group")

	-- Restore shape (fires OnSelect) then seed the size sliders (fires their handlers -> context + preview).
	local ShapeInst = Fuel:Get("Shape")
	local ShapeFQN  = (ShapeInst and ShapeInst.GetType) and Classes.GetTypeName(ShapeInst:GetType()) or "ACF.ContainerShapes.Box"
	FuelShape:ChooseOptionID(ShapeFQN == "ACF.ContainerShapes.Sphere" and 2 or ShapeFQN == "ACF.ContainerShapes.Cylinder" and 3 or 1)

	SizeX:SetValue(TankSize.x)
	SizeY:SetValue(TankSize.y)
	SizeZ:SetValue(TankSize.z)
end

ACF.Menu.RegisterPage({
	ID       = "acf_engine",
	Category = "#acf.menu.entities",
	Name     = "#acf.menu.engines",
	Icon     = "car",
	Order    = 201,

	Contexts = { Engine = "acf_engine", Fuel = "acf_fueltank" },

	Actions = {
		{ Bind = "left",       Context = "Engine", Preview = true, Desc = "Spawn a new engine, or update the one you're aiming at." },
		{ Bind = "shift+left", Context = "Fuel",   Preview = true, Desc = "Spawn a new fuel tank, or update the one you're aiming at." },
		{ Bind = "right",      Commit = "link", Desc = "Select entities, then an engine/tank, to link them (hold R to unlink)." },
	},

	Build = Build,
})
