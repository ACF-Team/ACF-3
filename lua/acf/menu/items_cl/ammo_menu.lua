
local ACF       = ACF
local Classes   = ACF.Classes
local AmmoTypes = Classes.AmmoTypes
local BoxSize   = Vector()
local Ammo, BulletData

local CrateText = [[
	Crate Armor: %s mm
	Crate Mass : %s
	Crate Capacity : %s round(s)]]

local function CopySettings(Settings)
	local Copy = {}

	if Settings then
		for K, V in pairs(Settings) do
			Copy[K] = V
		end
	end

	return Copy
end

local function GetAmmoList(Class)
	local Entries = AmmoTypes.GetEntries()
	local Result  = {}

	for K, V in pairs(Entries) do
		if V.Unlistable then continue end
		if V.Blacklist[Class] then continue end

		Result[K] = V
	end

	return Result
end

local function GetWeaponClass(ToolData)
	local Destiny = Classes[ToolData.Destiny or "Weapons"]

	return Classes.GetGroup(Destiny, ToolData.Weapon)
end

local function GetEmptyMass()
	local Armor          = ACF.AmmoArmor * 0.039 -- Millimeters to inches
	local ExteriorVolume = BoxSize.x * BoxSize.y * BoxSize.z
	local InteriorVolume = (BoxSize.x - Armor) * (BoxSize.y - Armor) * (BoxSize.z - Armor)

	return math.Round((ExteriorVolume - InteriorVolume) * 0.13, 2)
end

local function AddPreview(Base, Settings, ToolData)
	if Settings.SuppressPreview then return end

	local Preview = Base:AddModelPreview(nil, true)
	local Setup   = {}

	if Ammo.AddAmmoPreview then
		Ammo:AddAmmoPreview(Preview, Setup, ToolData, BulletData)
	end

	hook.Run("ACF_AddAmmoPreview", Preview, Setup, ToolData, Ammo, BulletData)

	Preview:UpdateModel(Setup.Model)
	Preview:UpdateSettings(Setup)
end

local function AddControls(Base, Settings, ToolData)
	if Settings.SuppressControls then return end

	local RoundLength = Base:AddLabel()
	RoundLength:TrackClientData("Projectile", "SetText", "GetText")
	RoundLength:TrackClientData("Propellant")
	RoundLength:TrackClientData("Tracer")
	RoundLength:DefineSetter(function()
		local Text = "Round Length: %s / %s cm"
		local CurLength = BulletData.ProjLength + BulletData.PropLength + BulletData.Tracer
		local MaxLength = BulletData.MaxRoundLength

		return Text:format(CurLength, MaxLength)
	end)

	local Projectile = Base:AddSlider("Projectile Length", 0, BulletData.MaxRoundLength, 2)
	Projectile:SetClientData("Projectile", "OnValueChanged")
	Projectile:DefineSetter(function(Panel, _, _, Value, IsTracked)
		ToolData.Projectile = Value

		if not IsTracked then
			BulletData.Priority = "Projectile"
		end

		Ammo:UpdateRoundData(ToolData, BulletData)

		ACF.SetClientData("Propellant", BulletData.PropLength)

		Panel:SetValue(BulletData.ProjLength)

		return BulletData.ProjLength
	end)

	local Propellant = Base:AddSlider("Propellant Length", 0, BulletData.MaxRoundLength, 2)
	Propellant:SetClientData("Propellant", "OnValueChanged")
	Propellant:DefineSetter(function(Panel, _, _, Value, IsTracked)
		ToolData.Propellant = Value

		if not IsTracked then
			BulletData.Priority = "Propellant"
		end

		Ammo:UpdateRoundData(ToolData, BulletData)

		ACF.SetClientData("Projectile", BulletData.ProjLength)

		Panel:SetValue(BulletData.PropLength)

		return BulletData.PropLength
	end)

	if Ammo.AddAmmoControls then
		Ammo:AddAmmoControls(Base, ToolData, BulletData)
	end

	hook.Run("ACF_AddAmmoControls", Base, ToolData, Ammo, BulletData)

	-- We'll create the tracer checkbox after all the other controls
	if not Settings.SuppressTracer then
		local Tracer = Base:AddCheckBox("Tracer")
		Tracer:SetClientData("Tracer", "OnChange")
		Tracer:DefineSetter(function(Panel, _, _, Value)
			ToolData.Tracer = Value

			Ammo:UpdateRoundData(ToolData, BulletData)

			ACF.SetClientData("Projectile", BulletData.ProjLength)
			ACF.SetClientData("Propellant", BulletData.PropLength)

			Panel:SetText("Tracer : " .. BulletData.Tracer .. " cm")
			Panel:SetValue(ToolData.Tracer)

			return ToolData.Tracer
		end)
	else
		ACF.SetClientData("Tracer", false) -- Disabling the tracer, as it takes up spaces on ammo.
	end
end

local function AddInformation(Base, Settings, ToolData)
	if Settings.SuppressInformation then return end

	if not Settings.SuppressCrateInformation then
		local Trackers = {}

		local Crate = Base:AddLabel()
		Crate:TrackClientData("Weapon", "SetText")
		Crate:TrackClientData("CrateSizeX")
		Crate:TrackClientData("CrateSizeY")
		Crate:TrackClientData("CrateSizeZ")
		Crate:DefineSetter(function()
			local Class  = GetWeaponClass(ToolData)
			local Rounds = ACF.GetAmmoCrateCapacity(BoxSize, Class, ToolData, BulletData)
			local Empty  = GetEmptyMass()
			local Load   = math.floor(BulletData.CartMass * Rounds)
			local Mass   = ACF.GetProperMass(math.floor(Empty + Load))

			return CrateText:format(ACF.AmmoArmor, Mass, Rounds)
		end)

		if Ammo.AddCrateDataTrackers then
			Ammo:AddCrateDataTrackers(Trackers, ToolData, BulletData)
		end

		hook.Run("ACF_AddCrateDataTrackers", Trackers, ToolData, Ammo, BulletData)

		for Tracker in pairs(Trackers) do
			Crate:TrackClientData(Tracker)
		end
	end

	if Ammo.AddAmmoInformation then
		Ammo:AddAmmoInformation(Base, ToolData, BulletData)
	end

	hook.Run("ACF_AddAmmoInformation", Base, ToolData, Ammo, BulletData)
end

local function AddGraph(Base, ToolData)
	local Graph = Base:AddGraph()
	Base.Graph = Graph
	local MenuSizeX = Base:GetParent():GetParent():GetWide() -- Parent of the parent of this item should be the menu panel
	Graph:SetSize(MenuSizeX, MenuSizeX * 0.5)

	Graph:SetXRange(0,1000)
	Graph:SetXLabel("Distance (m)")
	Graph:SetYLabel("Pen (mm)")

	Graph:SetXSpacing(100)
	Graph:SetYSpacing(50)
	Graph:SetFidelity(16)

	Graph:TrackClientData("Projectile")
	Graph:TrackClientData("Propellant")
	Graph:TrackClientData("FillerRatio")
	Graph:TrackClientData("LinerAngle")
	Graph:TrackClientData("StandoffRatio")
	Graph:TrackClientData("SmokeWPRatio")

	Graph:DefineSetter(function(Panel)
		Panel:Clear()

		Panel:SetXLabel("Distance (m)")
		Panel:SetFidelity(8)

		Graph:SetXSpacing(100)
		Graph:SetYSpacing(50)

		local Ammo = AmmoTypes.Get(ToolData.AmmoType)

		if ToolData.AmmoType == "HEAT" or ToolData.AmmoType == "HEATFS" then
			local PassiveStandoffPen = Ammo:GetPenetration(BulletData, BulletData.Standoff)
			local BreakupDistPen = Ammo:GetPenetration(BulletData, BulletData.BreakupDist)

			Panel:SetYRange(0,math.max(BreakupDistPen, PassiveStandoffPen) * 1.5)
			Panel:SetXRange(0,BulletData.BreakupDist * 1000 * 2.5) -- HEAT/HEATFS doesn't care how long the shell has been flying for penetration, just the instant it detonates
			--Panel:SetXRange(0,60000)

			Panel:SetXLabel("Standoff (mm)")

			--Panel:PlotLimitLine("Passive", false, BulletData.Standoff * 1000, Color(65,65,200))
			--Panel:PlotLimitLine("Breakup", false, BulletData.BreakupDist * 1000, Color(200,65,65))

			Panel:PlotPoint("Passive", BulletData.Standoff * 1000, PassiveStandoffPen, Color(65,65,200))
			Panel:PlotPoint("Breakup", BulletData.BreakupDist * 1000, BreakupDistPen, Color(200,65,65))

			Panel:PlotFunction("mm Pen", Color(255,65,65), function(X)
				return Ammo:GetPenetration(BulletData, X / 1000)
			end)
		elseif ToolData.AmmoType == "HE" then
			Panel:SetYLabel("Blast Radius")
			Panel:SetXLabel("")

			Panel:SetYSpacing(10)

			Panel:SetXRange(0,10)
			Panel:SetYRange(0,BulletData.BlastRadius * 2)

			Panel:PlotLimitLine("Blast Radius", true, BulletData.BlastRadius, Color(200,65,65))

			Panel:PlotFunction("Blast Radius", Color(200,65,65), function(_)
				return BulletData.BlastRadius
			end)
		elseif ToolData.AmmoType == "SM" then
			Panel:SetYLabel("Smoke Radius (m)")
			Panel:SetXLabel("Time (s)")

			Panel:SetYSpacing(10)
			Panel:SetXSpacing(5)

			local WPTime = BulletData.WPLife or 0
			local SFTime = BulletData.SMLife or 0

			local MinWP = BulletData.WPRadiusMin or 0
			local MaxWP = BulletData.WPRadiusMax or 0

			local MinSF = BulletData.SMRadiusMin or 0
			local MaxSF = BulletData.SMRadiusMax or 0

			Panel:SetXRange(0,math.max(WPTime,SFTime) * 1.1)
			Panel:SetYRange(0,math.max(MaxWP,MaxSF) * 1.1)

			if WPTime > 0 then
				Panel:PlotLimitFunction("WP Filler", 0, WPTime, Color(65,65,200), function(X)
					return Lerp(X / WPTime, MinWP, MaxWP)
				end)

				Panel:PlotPoint("WP Max Radius", WPTime, MaxWP, Color(65,65,200))
			end

			if SFTime > 0 then
				Panel:PlotLimitFunction("Smoke Filler", 0, SFTime, Color(200,65,65), function(X)
					return Lerp(X / SFTime, MinSF, MaxSF)
				end)

				Panel:PlotPoint("SM Max Radius", SFTime, MaxSF, Color(200,65,65))
			end
		else
			Panel:SetYRange(0,math.ceil(BulletData.MaxPen or 0) * 1.1)

			Panel:PlotPoint("300m", 300, Ammo:GetRangedPenetration(BulletData, 300), Color(65,65,200))
			Panel:PlotPoint("800m", 800, Ammo:GetRangedPenetration(BulletData, 800), Color(65,65,200))

			Panel:PlotFunction("Pen", Color(255,65,65), function(X)
				return Ammo:GetRangedPenetration(BulletData, X)
			end)
		end
	end)
end

function ACF.GetCurrentAmmoData()
	return BulletData
end

function ACF.UpdateAmmoMenu(Menu, Settings)
	if not Ammo then return end

	local ToolData = ACF.GetAllClientData()
	local Base = Menu.AmmoBase

	BulletData = Ammo:ClientConvert(ToolData)
	Settings   = CopySettings(Settings)

	if Ammo.SetupAmmoMenuSettings then
		Ammo:SetupAmmoMenuSettings(Settings, ToolData, BulletData)
	end

	hook.Run("ACF_SetupAmmoMenuSettings", Settings, ToolData, Ammo, BulletData)

	Menu:ClearTemporal(Base)
	Menu:StartTemporal(Base)

	if not Settings.SuppressMenu then
		AddPreview(Base, Settings, ToolData)
		AddControls(Base, Settings, ToolData)
		AddInformation(Base, Settings, ToolData)
		AddGraph(Base, ToolData)
	end

	Menu:EndTemporal(Base)
end

function ACF.CreateAmmoMenu(Menu, Settings)
	Menu:AddTitle("Ammo Settings")

	local List = Menu:AddComboBox()
	local Min  = ACF.AmmoMinSize
	local Max  = ACF.AmmoMaxSize

	local SizeX = Menu:AddSlider("Crate Length", Min, Max)
	SizeX:SetClientData("CrateSizeX", "OnValueChanged")
	SizeX:DefineSetter(function(Panel, _, _, Value)
		local X = math.Round(Value)

		Panel:SetValue(X)

		BoxSize.x = X

		return X
	end)

	local SizeY = Menu:AddSlider("Crate Width", Min, Max)
	SizeY:SetClientData("CrateSizeY", "OnValueChanged")
	SizeY:DefineSetter(function(Panel, _, _, Value)
		local Y = math.Round(Value)

		Panel:SetValue(Y)

		BoxSize.y = Y

		return Y
	end)

	local SizeZ = Menu:AddSlider("Crate Height", Min, Max)
	SizeZ:SetClientData("CrateSizeZ", "OnValueChanged")
	SizeZ:DefineSetter(function(Panel, _, _, Value)
		local Z = math.Round(Value)

		Panel:SetValue(Z)

		BoxSize.z = Z

		return Z
	end)

	local Base = Menu:AddCollapsible("Ammo Information")
	local Desc = Base:AddLabel()

	function List:LoadEntries(Class)
		ACF.LoadSortedList(self, GetAmmoList(Class), "Name")
	end

	function List:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.ListData.Index = Index
		self.Selected = Data

		Ammo = Data

		ACF.SetClientData("AmmoType", Data.ID)

		Desc:SetText(Data.Description)

		ACF.UpdateAmmoMenu(Menu, Settings)
	end

	Menu.AmmoBase = Base

	return List
end
