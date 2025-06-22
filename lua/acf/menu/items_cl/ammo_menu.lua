local hook      = hook
local ACF       = ACF
local Classes   = ACF.Classes
local AmmoTypes = Classes.AmmoTypes
local BoxSize   = Vector()
local Ammo, BulletData

local GraphRed    = Color(200, 65, 65)
local GraphBlue   = Color(65, 65, 200)
local GraphRedAlt = Color(255, 65, 65)

---Gets a key-value table of all the ammo type objects a given weapon class can make use of.
---@param Class string The ammo type ID that will be checked.
---@return table<string, table> Result The ammo type objects said weapon class can use.
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

---Returns the weapon group object depending on what Destiny and Weapons a player has set on their client data variables.
---@param ToolData table<string, any> The copy of the local player's client data variables.
---@return table<string, any> Group The weapon group object expected by the player's menu.
local function GetWeaponClass(ToolData)
	local Destiny = Classes[ToolData.Destiny or "Weapons"]

	return Classes.GetGroup(Destiny, ToolData.Weapon)
end

---Returns the mass of a hollow box given the current size and armor thickness expected for it.
---The size of the box will be defined by CrateSizeX, CrateSizeY and CrateSizeZ client data variables.
---The thickness of the empty box will be defined by the ACF.AmmoArmor global variable.
---@return number Mass The mass of the hollow box.
local function GetEmptyMass()
	local Armor          = ACF.AmmoArmor * ACF.MmToInch
	local ExteriorVolume = BoxSize.x * BoxSize.y * BoxSize.z
	local InteriorVolume = (BoxSize.x - Armor) * (BoxSize.y - Armor) * (BoxSize.z - Armor)

	return math.Round((ExteriorVolume - InteriorVolume) * 0.13, 2)
end

---Creates the entity preview panel on the ACF menu.
---@param Base userdata The panel being populated with the preview.
---This function will only use SuppressPreview. If it's defined, this function will effectively do nothing.
---@param ToolData table<string, any> The copy of the local player's client data variables.
local function AddPreview(Base, ToolData)
	if Ammo.PreCreateAmmoPreview then
		local Result = Ammo:PreCreateAmmoPreview(Base, ToolData, BulletData)

		if not Result then return end
	end

	local Result = hook.Run("ACF_PreCreateAmmoPreview", Base, ToolData, Ammo, BulletData)

	if not Result then return end

	local Preview = Base:AddModelPreview(nil, true)
	local Setup   = {}

	if Ammo.OnCreateAmmoPreview then
		Ammo:OnCreateAmmoPreview(Preview, Setup, ToolData, BulletData)
	end

	hook.Run("ACF_OnCreateAmmoPreview", Preview, Setup, ToolData, Ammo, BulletData)

	Preview:UpdateModel(Setup.Model)
	Preview:UpdateSettings(Setup)
end

local function AddTracer(Base, ToolData)
	if Ammo.PreCreateTracerControls then
		local Result = Ammo:PreCreateTracerControls(Base, ToolData, BulletData)

		if not Result then
			ACF.SetClientData("Tracer", false)

			return
		end
	end

	local Result = hook.Run("ACF_PreCreateTracerControls", Base, ToolData, Ammo, BulletData)

	if not Result then
		ACF.SetClientData("Tracer", false)

		return
	end

	local TracerText = language.GetPhrase("acf.menu.ammo.tracer")
	local Tracer = Base:AddCheckBox(TracerText:format(0))
	Tracer:SetClientData("Tracer", "OnChange")
	Tracer:DefineSetter(function(Panel, _, _, Value)
		ToolData.Tracer = Value

		Ammo:UpdateRoundData(ToolData, BulletData)

		ACF.SetClientData("Projectile", BulletData.ProjLength)
		ACF.SetClientData("Propellant", BulletData.PropLength)

		Panel:SetText(TracerText:format(BulletData.Tracer))
		Panel:SetValue(ToolData.Tracer)

		return ToolData.Tracer
	end)

	if Ammo.OnCreateTracerControls then
		Ammo:OnCreateTracerControls(Base, ToolData, BulletData)
	end

	hook.Run("ACF_OnCreateTracerControls", Base, ToolData, Ammo, BulletData)
end

---Creates the ammunition control panels on the ACF menu.
---@param Base userdata The panel being populated with the ammunition controls.
---This function makes use of SuppressControls and SuppressTracer.
---If the first is defined, this function will effectively do nothing.
---If the latter is defined, only the Tracer checkbox will be omitted and the Tracer client data variable will be set to false.
---@param ToolData table<string, any> The copy of the local player's client data variables.
local function AddControls(Base, ToolData)
	if Ammo.PreCreateAmmoControls then
		local Result = Ammo:PreCreateAmmoControls(Base, ToolData, BulletData)

		if not Result then return end
	end

	local Result = hook.Run("ACF_PreCreateAmmoControls", Base, ToolData, Ammo, BulletData)

	if not Result then return end

	local RoundLength = Base:AddLabel()
	RoundLength:TrackClientData("Projectile", "SetText", "GetText")
	RoundLength:TrackClientData("Propellant")
	RoundLength:TrackClientData("Tracer")
	RoundLength:DefineSetter(function()
		local Text = language.GetPhrase("acf.menu.ammo.round_length")
		local CurLength = BulletData.ProjLength + BulletData.PropLength + BulletData.Tracer
		local MaxLength = BulletData.MaxRoundLength

		return Text:format(CurLength, MaxLength)
	end)

	local Projectile = Base:AddSlider("#acf.menu.ammo.projectile_length", 0, BulletData.MaxRoundLength, 2)
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

	local Propellant = Base:AddSlider("#acf.menu.ammo.propellant_length", 0, BulletData.MaxRoundLength, 2)
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

	if Ammo.OnCreateAmmoControls then
		Ammo:OnCreateAmmoControls(Base, ToolData, BulletData)
	end

	hook.Run("ACF_OnCreateAmmoControls", Base, ToolData, Ammo, BulletData)

	AddTracer(Base, ToolData)

	-- Control for the stowage stage (priority) of the ammo
	local AmmoStage = Base:AddNumberWang("#acf.menu.ammo.stage", ACF.AmmoStageMin, ACF.AmmoStageMax)
	AmmoStage:SetClientData("AmmoStage", "OnValueChanged")
	AmmoStage:SetValue(1)
end

---Creates the ammunition information panels on the ACF menu.
---@param Base userdata The panel being populated with the ammunition information.
---This function makes use of SuppressInformation and SuppressCrateInformation
---If the first is defined, this function will effectively do nothing.
---If the latter is defined, only the information regarding the ammo crate (armor, mass and capacity by default) will be omitted.
---@param ToolData table<string, any> The copy of the local player's client data variables.
local function AddCrateInformation(Base, ToolData)
	if Ammo.PreCreateCrateInformation then
		local Result = Ammo:PreCreateCrateInformation(Base, ToolData, BulletData)

		if not Result then return end
	end

	local Result = hook.Run("ACF_PreCreateCrateInformation", Base, ToolData, Ammo, BulletData)

	if not Result then return end

	local Crate = Base:AddLabel()
	Crate:TrackClientData("Weapon", "SetText")
	Crate:TrackClientData("CrateSizeX")
	Crate:TrackClientData("CrateSizeY")
	Crate:TrackClientData("CrateSizeZ")
	Crate:DefineSetter(function()
		local CrateText = language.GetPhrase("acf.menu.ammo.crate_stats")
		local Class     = GetWeaponClass(ToolData)
		local Rounds    = ACF.GetAmmoCrateCapacity(BoxSize, Class, ToolData, BulletData)
		local Empty     = GetEmptyMass()
		local Load      = math.floor(BulletData.CartMass * Rounds)
		local Mass      = ACF.GetProperMass(math.floor(Empty + Load))

		return CrateText:format(ACF.AmmoArmor, Mass, Rounds)
	end)

	if Ammo.OnCreateCrateInformation then
		Ammo:OnCreateCrateInformation(Base, Crate, ToolData, BulletData)
	end

	hook.Run("ACF_OnCreateCrateInformation", Base, Crate, ToolData, Ammo, BulletData)
end

local function AddInformation(Base, ToolData)
	if Ammo.PreCreateAmmoInformation then
		local Result = Ammo:PreCreateAmmoInformation(Base, ToolData, BulletData)

		if not Result then return end
	end

	local Result = hook.Run("ACF_PreCreateAmmoInformation", Base, ToolData, Ammo, BulletData)

	if not Result then return end

	AddCrateInformation(Base, ToolData)

	if Ammo.OnCreateAmmoInformation then
		Ammo:OnCreateAmmoInformation(Base, ToolData, BulletData)
	end

	hook.Run("ACF_OnCreateAmmoInformation", Base, ToolData, Ammo, BulletData)
end

local function AddGraph(Base, ToolData)
	if Ammo.PreCreateAmmoGraph then
		local Result = Ammo:PreCreateAmmoGraph(Base, ToolData, BulletData)

		if not Result then return end
	end

	local Graph = Base:AddGraph()
	Base.Graph = Graph
	local MenuSizeX = Base:GetParent():GetParent():GetWide() -- Parent of the parent of this item should be the menu panel
	Graph:SetSize(MenuSizeX, MenuSizeX * 0.5)

	local PenetrationText = language.GetPhrase("acf.menu.ammo.penetration")

	Graph:SetXRange(0, 1000)
	Graph:SetXLabel("#acf.menu.ammo.distance")
	Graph:SetYLabel(PenetrationText)

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

		Panel:SetXLabel("#acf.menu.ammo.distance")
		Panel:SetFidelity(8)

		Graph:SetXSpacing(100)
		Graph:SetYSpacing(50)

		local Ammo = AmmoTypes.Get(ToolData.AmmoType)

		if ToolData.AmmoType == "HEAT" or ToolData.AmmoType == "HEATFS" then
			local PassiveStandoffPen = Ammo:GetPenetration(BulletData, BulletData.Standoff)
			local BreakupDistPen = Ammo:GetPenetration(BulletData, BulletData.BreakupDist)

			Panel:SetYRange(0, math.max(BreakupDistPen, PassiveStandoffPen) * 1.5)
			Panel:SetXRange(0, BulletData.BreakupDist * 1000 * 2.5) -- HEAT/HEATFS doesn't care how long the shell has been flying for penetration, just the instant it detonates
			--Panel:SetXRange(0,60000)

			Panel:SetXLabel("#acf.menu.ammo.standoff")

			--Panel:PlotLimitLine(language.GetPhrase("acf.menu.ammo.passive"), false, BulletData.Standoff * 1000, GraphBlue)
			--Panel:PlotLimitLine(language.GetPhrase("acf.menu.ammo.breakup"), false, BulletData.BreakupDist * 1000, GraphRed)

			Panel:PlotPoint(language.GetPhrase("acf.menu.ammo.passive"), BulletData.Standoff * 1000, PassiveStandoffPen, GraphBlue)
			Panel:PlotPoint(language.GetPhrase("acf.menu.ammo.breakup"), BulletData.BreakupDist * 1000, BreakupDistPen, GraphRed)

			Panel:PlotFunction(PenetrationText, GraphRedAlt, function(X)
				return Ammo:GetPenetration(BulletData, X / 1000)
			end)
		elseif ToolData.AmmoType == "HE" then
			local BlastRadiusText = language.GetPhrase("acf.menu.ammo.blast_radius")

			Panel:SetYLabel(BlastRadiusText)
			Panel:SetXLabel("")

			Panel:SetYSpacing(10)

			Panel:SetXRange(0, 10)
			Panel:SetYRange(0, BulletData.BlastRadius * 2)

			Panel:PlotLimitLine(BlastRadiusText, true, BulletData.BlastRadius, GraphRed)

			Panel:PlotFunction(BlastRadiusText, GraphRed, function()
				return BulletData.BlastRadius
			end)
		elseif ToolData.AmmoType == "SM" then
			Panel:SetYLabel("#acf.menu.ammo.smoke_radius")
			Panel:SetXLabel("#acf.menu.ammo.time")

			Panel:SetYSpacing(10)
			Panel:SetXSpacing(5)

			local WPTime = BulletData.WPLife or 0
			local SFTime = BulletData.SMLife or 0

			local MinWP = BulletData.WPRadiusMin or 0
			local MaxWP = BulletData.WPRadiusMax or 0

			local MinSF = BulletData.SMRadiusMin or 0
			local MaxSF = BulletData.SMRadiusMax or 0

			Panel:SetXRange(0, math.max(WPTime, SFTime) * 1.1)
			Panel:SetYRange(0, math.max(MaxWP, MaxSF) * 1.1)

			if WPTime > 0 then
				Panel:PlotLimitFunction(language.GetPhrase("acf.menu.ammo.wp_filler"), 0, WPTime, GraphBlue, function(X)
					return Lerp(X / WPTime, MinWP, MaxWP)
				end)

				Panel:PlotPoint(language.GetPhrase("acf.menu.ammo.wp_max_radius"), WPTime, MaxWP, GraphBlue)
			end

			if SFTime > 0 then
				Panel:PlotLimitFunction(language.GetPhrase("acf.menu.ammo.smoke_filler"), 0, SFTime, GraphRed, function(X)
					return Lerp(X / SFTime, MinSF, MaxSF)
				end)

				Panel:PlotPoint(language.GetPhrase("acf.menu.ammo.smoke_max_radius"), SFTime, MaxSF, GraphRed)
			end
		else
			Panel:SetYRange(0, math.ceil(BulletData.MaxPen or 0) * 1.1)

			Panel:PlotPoint(language.GetPhrase("acf.menu.ammo.300m"), 300, Ammo:GetRangedPenetration(BulletData, 300), GraphBlue)
			Panel:PlotPoint(language.GetPhrase("acf.menu.ammo.800m"), 800, Ammo:GetRangedPenetration(BulletData, 800), GraphBlue)

			Panel:PlotFunction(PenetrationText, GraphRedAlt, function(X)
				return Ammo:GetRangedPenetration(BulletData, X)
			end)
		end
	end)

	if Ammo.OnCreateAmmoGraph then
		Ammo:OnCreateAmmoGraph(Base, ToolData, BulletData)
	end
end

---Returns the client bullet data currently being used by the menu.
---@return table<string, any> BulletData The client bullet data.
function ACF.GetCurrentAmmoData()
	return BulletData
end

---Updates and populates the current ammunition menu.
---@param Menu userdata The panel in which the entire ACF menu is being placed on.
function ACF.UpdateAmmoMenu(Menu)
	if not Ammo then return end

	local ToolData = ACF.GetAllClientData()
	local Base = Menu.AmmoBase

	BulletData = Ammo:ClientConvert(ToolData)

	Menu:ClearTemporal(Base)

	if Ammo.PreCreateAmmoMenu then
		local Result = Ammo:PreCreateAmmoMenu(ToolData, BulletData)

		if not Result then return end
	end

	local Result = hook.Run("ACF_PreCreateAmmoMenu", ToolData, Ammo, BulletData)

	if not Result then return end

	Menu:StartTemporal(Base)

	if Ammo.OnCreateAmmoMenu then
		Ammo:OnCreateAmmoMenu(Base, ToolData, BulletData)
	end

	hook.Run("ACF_OnCreateAmmoMenu", Base, ToolData, Ammo, BulletData)

	AddPreview(Base, ToolData)
	AddControls(Base, ToolData)
	AddInformation(Base, ToolData)
	AddGraph(Base, ToolData)

	Menu:EndTemporal(Base)
end

---Creates the basic information and panels on the ammunition menu.
---@param Menu userdata The panel in which the entire ACF menu is being placed on.
function ACF.CreateAmmoMenu(Menu)
	Menu:AddTitle("#acf.menu.ammo.settings")

	local List = Menu:AddComboBox()
	local Min  = ACF.AmmoMinSize
	local Max  = ACF.AmmoMaxSize

	local SizeX = Menu:AddSlider("#acf.menu.ammo.crate_length", Min, Max)
	SizeX:SetClientData("CrateSizeX", "OnValueChanged")
	SizeX:DefineSetter(function(Panel, _, _, Value)
		local X = math.Round(Value)

		Panel:SetValue(X)

		BoxSize.x = X

		return X
	end)

	local SizeY = Menu:AddSlider("#acf.menu.ammo.crate_width", Min, Max)
	SizeY:SetClientData("CrateSizeY", "OnValueChanged")
	SizeY:DefineSetter(function(Panel, _, _, Value)
		local Y = math.Round(Value)

		Panel:SetValue(Y)

		BoxSize.y = Y

		return Y
	end)

	local SizeZ = Menu:AddSlider("#acf.menu.ammo.crate_height", Min, Max)
	SizeZ:SetClientData("CrateSizeZ", "OnValueChanged")
	SizeZ:DefineSetter(function(Panel, _, _, Value)
		local Z = math.Round(Value)

		Panel:SetValue(Z)

		BoxSize.z = Z

		return Z
	end)

	local Base = Menu:AddCollapsible("#acf.menu.ammo.ammo_info", nil, "icon16/chart_bar_edit.png")
	local Desc = Base:AddLabel()
	Desc:SetText("")

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

		ACF.UpdateAmmoMenu(Menu)
	end

	Menu.AmmoBase = Base

	return List
end