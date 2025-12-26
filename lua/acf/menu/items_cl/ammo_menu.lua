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
---The size of the box will be calculated from projectile counts and current ammo configuration.
---The thickness of the empty box will be defined by the ACF.ContainerArmor global variable.
---@return number Mass The mass of the hollow box.
local function GetEmptyMass()
	local Armor          = ACF.ContainerArmor * ACF.MmToInch
	local ExteriorVolume = BoxSize.x * BoxSize.y * BoxSize.z
	local InteriorVolume = math.max(0, (BoxSize.x - 2 * Armor) * (BoxSize.y - 2 * Armor) * (BoxSize.z - 2 * Armor))

	return math.Round((ExteriorVolume - InteriorVolume) * 0.13, 2)
end


---Calculates the maximum count values for all axes based on round dimensions and packing
---@param CountY number Current Y count (for Z axis packing)
---@param CountZ number Current Z count (for Y axis packing)
---@param ToolData table The current tool data
---@param BulletData table The current bullet data
---@return number, number, number MaxX, MaxY, MaxZ
local function CalculateMaxCounts(CountY, CountZ, ToolData, BulletData)
	local Class = GetWeaponClass(ToolData)
	if not (Class and BulletData) then return 50, 50, 50 end

	local roundSize = ACF.GetCrateSizeFromProjectileCounts(1, 1, 1, Class, ToolData, BulletData)
	if not roundSize then return 50, 50, 50 end

	return ACF.GetMaxCounts(roundSize, ACF.AmmoMaxLength, ACF.AmmoMaxWidth, CountY, CountZ)
end

-- Store references to the count sliders so we can update them
local CountSliders = {}

---Updates the maximum values for the projectile count sliders based on current round dimensions
---@param ToolData table The current tool data
---@param BulletData table The current bullet data
---@param SkipMissiles boolean If true, skip update for missiles (used when projectile/propellant sliders change)
local function UpdateProjectileCountLimits(ToolData, BulletData, SkipMissiles)
	if not (CountSliders.X and CountSliders.Y and CountSliders.Z) then return end

	-- Skip for missiles only when called from projectile/propellant sliders
	-- (missiles use fixed model dimensions that don't change with those sliders)
	if SkipMissiles and ToolData.Destiny == "Missiles" then return end

	local CurrentX = ACF.GetClientNumber("CrateProjectilesX", 3)
	local CurrentY = ACF.GetClientNumber("CrateProjectilesY", 3)
	local CurrentZ = ACF.GetClientNumber("CrateProjectilesZ", 3)

	local MaxX, MaxY, MaxZ = CalculateMaxCounts(CurrentY, CurrentZ, ToolData, BulletData)

	CountSliders.X:SetMax(MaxX)
	CountSliders.Y:SetMax(MaxY)
	CountSliders.Z:SetMax(MaxZ)

	-- Clamp current values if they exceed new max
	if CurrentX > MaxX then
		CountSliders.X:SetValue(MaxX)
		ACF.SetClientData("CrateProjectilesX", MaxX)
	end
	if CurrentY > MaxY then
		CountSliders.Y:SetValue(MaxY)
		ACF.SetClientData("CrateProjectilesY", MaxY)
	end
	if CurrentZ > MaxZ then
		CountSliders.Z:SetValue(MaxZ)
		ACF.SetClientData("CrateProjectilesZ", MaxZ)
	end
end

---Updates the BoxSize global variable and ammo size client data based on current projectile counts and ammo configuration.
---@param ToolData table The current tool data
---@param BulletData table The current bullet data
local function UpdateBoxSizeFromProjectileCounts(ToolData, BulletData)

	local CountX = ACF.GetClientNumber("CrateProjectilesX", 3)
	local CountY = ACF.GetClientNumber("CrateProjectilesY", 3)
	local CountZ = ACF.GetClientNumber("CrateProjectilesZ", 3)
	local Class  = GetWeaponClass(ToolData)

	if Class and BulletData then
		BoxSize = ACF.GetCrateSizeFromProjectileCounts(CountX, CountY, CountZ, Class, ToolData, BulletData)
		-- Set the ammo size client data so it gets sent to the server
		ACF.SetClientData("AmmoSizeX", BoxSize.x)
		ACF.SetClientData("AmmoSizeY", BoxSize.y)
		ACF.SetClientData("AmmoSizeZ", BoxSize.z)
	end
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
	local Tracer = Base:AddCheckBox(TracerText)
	Tracer:SetClientData("Tracer", "OnChange")
	Tracer:DefineSetter(function(Panel, _, _, Value)
		ToolData.Tracer = Value

		Ammo:UpdateRoundData(ToolData, BulletData)

		ACF.SetClientData("Projectile", BulletData.ProjLength)
		ACF.SetClientData("Propellant", BulletData.PropLength)

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
	RoundLength:DefineSetter(function()
		local Text = language.GetPhrase("acf.menu.ammo.round_length")
		local CurLength = BulletData.ProjLength + BulletData.PropLength
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

		-- Update projectile count limits when round dimensions change (skip for missiles)
		UpdateProjectileCountLimits(ToolData, BulletData, true)

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

		-- Update projectile count limits when round dimensions change (skip for missiles)
		UpdateProjectileCountLimits(ToolData, BulletData, true)

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
	Crate:TrackClientData("CrateProjectilesX")
	Crate:TrackClientData("CrateProjectilesY")
	Crate:TrackClientData("CrateProjectilesZ")
	-- Track projectile dimensions so crate size updates when ammo config changes
	Crate:TrackClientData("Projectile")
	Crate:TrackClientData("Propellant")
	Crate:TrackClientData("Tracer")
	Crate:DefineSetter(function()
		UpdateBoxSizeFromProjectileCounts(ToolData, BulletData)

		local CrateText = language.GetPhrase("acf.menu.ammo.crate_stats")

		-- Calculate rounds directly from projectile counts
		local CountX = ACF.GetClientNumber("CrateProjectilesX", 3)
		local CountY = ACF.GetClientNumber("CrateProjectilesY", 3)
		local CountZ = ACF.GetClientNumber("CrateProjectilesZ", 3)
		local Rounds = CountX * CountY * CountZ

		local Empty     = GetEmptyMass()
		local Load      = math.floor(BulletData.CartMass * Rounds)
		local Mass      = ACF.GetProperMass(math.floor(Empty + Load))

		return CrateText:format(ACF.ContainerArmor, Mass, Rounds)
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

local function AddPenetrationTable(Base, ToolData)
	--HE and Smoke do not support this.
	if ToolData.AmmoType == "SM" or ToolData.AmmoType == "HE" then return end

	-- Setup of penetration statistics table.
	local PenTable = Base:AddTable(5, 6)
	PenTable.SetCellsSize(55, 20)
	PenTable.SetCellValue(1, 1, "Range")
	PenTable.SetCellValue(2, 1, "Velocity")
	PenTable.SetCellValue(3, 1, "0 " .. language.GetPhrase("acf.menu.ammo.pen_table_deg"))
	PenTable.SetCellValue(4, 1, "30 " .. language.GetPhrase("acf.menu.ammo.pen_table_deg"))
	PenTable.SetCellValue(5, 1, "60 " .. language.GetPhrase("acf.menu.ammo.pen_table_deg"))
	PenTable:TrackClientData("Projectile", "SetText")
	PenTable:TrackClientData("Propellant")
	PenTable:TrackClientData("FillerRatio")
	PenTable:TrackClientData("LinerAngle")
	PenTable:TrackClientData("StandoffRatio")

	PenTable:DefineSetter(function()
		local Ranges = {0, 100, 250, 500, 800}
		for index, range in pairs(Ranges) do
			local Penetration, Velocity = Ammo:GetRangedPenetration(BulletData, range)

			-- Chemical rounds require different functions for penetration.
			if ToolData.AmmoType == "HEAT" or ToolData.AmmoType == "HEATFS" then
				Penetration = Ammo:GetPenetration(BulletData, BulletData.Standoff)
			end

			PenTable.SetCellValue(1, 1 + index, math.floor(range) .. " " .. language.GetPhrase("acf.menu.ammo.pen_table_m"))
			PenTable.SetCellValue(2, 1 + index, math.Round(Velocity) .. " " .. language.GetPhrase("acf.menu.ammo.pen_table_ms"))
			PenTable.SetCellValue(3, 1 + index, math.Round(Penetration) .. " " .. language.GetPhrase("acf.menu.ammo.pen_table_mm"))
			PenTable.SetCellValue(4, 1 + index, math.Round(Penetration / 1.1547) .. " " .. language.GetPhrase("acf.menu.ammo.pen_table_mm")) --The magic number here is LOS armor divisor at 30 deg.
			PenTable.SetCellValue(5, 1 + index, math.Round(Penetration / 2) .. " " .. language.GetPhrase("acf.menu.ammo.pen_table_mm")) --The magic number here is LOS armor divisor at 60 deg.
		end
	end)

	Base:AddLabel("#acf.menu.ammo.pen_table_nominal")
	Base:AddLabel("#acf.menu.ammo.approx_pen_warning")
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
	AddPenetrationTable(Base, ToolData)
	AddGraph(Base, ToolData)

	Menu:EndTemporal(Base)

	-- Update projectile count limits after menu is created
	UpdateProjectileCountLimits(ToolData, BulletData)
end

---Creates the basic information and panels on the ammunition menu.
---@param Menu userdata The panel in which the entire ACF menu is being placed on.
function ACF.CreateAmmoMenu(Menu)
	Menu:AddTitle("#acf.menu.ammo.settings")

	local List = Menu:AddComboBox()

	-- Set default projectile count values before creating controls to prevent nil value errors
	local DefaultCountX = ACF.GetClientNumber("CrateProjectilesX", 3)
	local DefaultCountY = ACF.GetClientNumber("CrateProjectilesY", 3)
	local DefaultCountZ = ACF.GetClientNumber("CrateProjectilesZ", 3)
	ACF.SetClientData("CrateProjectilesX", DefaultCountX, true)
	ACF.SetClientData("CrateProjectilesY", DefaultCountY, true)
	ACF.SetClientData("CrateProjectilesZ", DefaultCountZ, true)

	local CountX = Menu:AddSlider("#acf.menu.ammo.projectiles_length", 1, 50, 0)
	CountX:SetClientData("CrateProjectilesX", "OnValueChanged")
	CountX:DefineSetter(function(Panel, _, _, Value)
		local Count = math.max(1, math.Round(Value))
		Panel:SetValue(Count)
		return Count
	end)

	local CountY = Menu:AddSlider("#acf.menu.ammo.projectiles_width", 1, 50, 0)
	CountY:SetClientData("CrateProjectilesY", "OnValueChanged")
	CountY:DefineSetter(function(Panel, _, _, Value)
		local Count = math.max(1, math.Round(Value))
		Panel:SetValue(Count)
		return Count
	end)

	local CountZ = Menu:AddSlider("#acf.menu.ammo.projectiles_height", 1, 50, 0)
	CountZ:SetClientData("CrateProjectilesZ", "OnValueChanged")
	CountZ:DefineSetter(function(Panel, _, _, Value)
		local Count = math.max(1, math.Round(Value))
		Panel:SetValue(Count)
		return Count
	end)

	local Size = Menu:AddLabel("")
	Size:TrackClientData("CrateProjectilesX", "SetText")
	Size:TrackClientData("CrateProjectilesY", "SetText")
	Size:TrackClientData("CrateProjectilesZ", "SetText")
	Size:DefineSetter(function()
		local SizeText = language.GetPhrase("#acf.menu.ammo.crate_size")
		return SizeText:format(math.Round(BoxSize.x, 2), math.Round(BoxSize.y, 2), math.Round(BoxSize.z, 2))
	end)

	-- Store references for updating max values later
	CountSliders.X = CountX
	CountSliders.Y = CountY
	CountSliders.Z = CountZ

	local Base = Menu:AddCollapsible("#acf.menu.ammo.ammo_info", nil, "icon16/chart_bar_edit.png")
	local Title = Base:AddTitle()
	local Desc = Base:AddLabel()
	Desc:SetText("")

	local function UpdateTitle()
		local TitleText = language.GetPhrase("acf.menu.weapons.name_text")
		local Caliber = ACF.GetClientNumber("Caliber", 0)
		local AmmoName = Ammo and Ammo.Name or ""

		return TitleText:format(Caliber, AmmoName)
	end
	Title:TrackClientData("Caliber", "SetText")
	Title:DefineSetter(UpdateTitle)
	Title:SetText("")

	-- Initialize BoxSize and projectile counts
	--[[
	local function InitializeBoxSize()
		local ToolData = ACF.GetAllClientData()
		local Class = GetWeaponClass(ToolData)

		if Class then
			local Ammo = ACF.Classes.AmmoTypes.Get(ToolData.AmmoType)

			if Ammo then
				local BulletData = Ammo:ClientConvert(ToolData)

				-- Always calculate from current projectile counts to ensure consistency
				-- This prevents old Size values from overriding the user's projectile count settings
				UpdateBoxSizeFromProjectileCounts(ToolData, BulletData)
			end
		end
	end
	]]--
	function List:LoadEntries(Class)
		ACF.LoadSortedList(self, GetAmmoList(Class), "Name", "SpawnIcon")

		-- Initialize box size when entries are loaded
		--timer.Simple(0, InitializeBoxSize)
	end

	function List:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.ListData.Index = Index
		self.Selected = Data

		Ammo = Data

		ACF.SetClientData("AmmoType", Data.ID)
		Title:SetText(UpdateTitle())
		Desc:SetText(Data.Description)

		ACF.UpdateAmmoMenu(Menu)
	end

	Menu.AmmoBase = Base

	return List
end