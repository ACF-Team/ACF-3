local hook      = hook
local ACF       = ACF
local Classes   = ACF.Classes
local AmmoTypes = Classes.AmmoTypes
local BoxSize   = Vector()
local Ammo, BulletData
local GhostData = {Secondary = {
	Model = "models/holograms/hq_rcube_thin.mdl",
	Material = "phoenix_storms/Future_vents",
	Scale = Vector(1, 1, 1),
}}

-- Shared graph colors, referenced by each ammo type's PlotAmmoGraph method
ACF.GraphColors = ACF.GraphColors or {
	Red    = Color(200, 65, 65),
	Blue   = Color(65, 65, 200),
	RedAlt = Color(255, 65, 65),
}

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

---Computes the crate/drum size for the given shape and projectile counts.
---@param Shape string
---@param CountX number
---@param CountY number
---@param CountZ number
---@param Class table
---@param ToolData table<string, any>
---@param BulletData table
local function GetSizeForShape(Shape, CountX, CountY, CountZ, Class, ToolData, BulletData)
	local HexPack = ACF.GetClientBool("HexPacking", false)

	if ACF.IsDrumShape(Shape) then
		-- For drums: X = rounds per ring, Z = the layout's secondary axis
		return ACF.GetDrumCrateSizeFromProjectileCounts(CountX, CountZ, Class, ToolData, BulletData, HexPack, Shape)
	end

	return ACF.GetCrateSizeFromProjectileCounts(CountX, CountY, CountZ, Class, ToolData, BulletData, HexPack)
end

---Returns how many complete rounds a crate of the given projectile counts holds.
---Mirrors the server's own count in UpdateCrateSize: the counts are cells, and two piece ammo
---stows the charge and the projectile in a cell each, so it takes two of them to make a round.
---@param Shape string
---@param CountX number
---@param CountY number
---@param CountZ number
---@param TwoPiece boolean
---@return number Rounds
local function GetRoundCount(Shape, CountX, CountY, CountZ, TwoPiece)
	local Layout = ACF.GetDrumLayout(Shape)
	local Rounds

	if Layout then
		-- For drums X is the layout's primary count, which is not always a round count:
		-- a vertical drum reads it as rings, so the layout works out the rounds per disk
		Rounds = Layout.GetPerDisk(CountX) * CountZ
	else
		Rounds = CountX * CountY * CountZ
	end

	if TwoPiece then
		Rounds = math.floor(Rounds * 0.5)
	end

	return Rounds
end

---Calculates the maximum count values for all axes based on round dimensions and packing
---@param ToolData table The current tool data
---@param BulletData table The current bullet data
---@return number, number, number MaxX, MaxY, MaxZ
local function CalculateMaxCounts(ToolData, BulletData)
	local Class = GetWeaponClass(ToolData)
	if not (Class and BulletData) then return 50, 50, 50 end

	local roundSize = ACF.GetCrateSizeFromProjectileCounts(1, 1, 1, Class, ToolData, BulletData)
	if not roundSize then return 50, 50, 50 end

	return ACF.GetMaxCounts(roundSize, ACF.AmmoMaxLength, ACF.AmmoMaxWidth, ACF.GetClientBool("HexPacking", false))
end

-- Store references to the count sliders so we can update them
local CountSliders = {}

---Updates the min/max values for the projectile count sliders based on current round dimensions
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
	local Shape = ACF.GetClientString("AmmoShape", "Box")
	local HexPack = ACF.GetClientBool("HexPacking", false)

	local MinX = 1
	local MaxX, MaxY, MaxZ

	local Layout = ACF.GetDrumLayout(Shape)

	if Layout then
		local Class = GetWeaponClass(ToolData)

		if Class and BulletData then
			local roundSize = ACF.GetRoundProperties(Class, ToolData, BulletData)

			if roundSize then
				MinX = Layout.MinPrimary
				MaxX = Layout.GetMaxPrimary(roundSize, ACF.AmmoMaxWidth, HexPack)
				MaxZ = Layout.GetMaxStacks(roundSize, ACF.AmmoMaxLength, HexPack)
			else
				MaxX = 50
				MaxZ = 50
			end
		else
			MaxX = 50
			MaxZ = 50
		end

		MaxY = 1
	else
		-- Standard box crate
		MaxX, MaxY, MaxZ = CalculateMaxCounts(ToolData, BulletData)
	end

	CountSliders.X:SetMin(MinX)
	CountSliders.X:SetMax(MaxX)
	CountSliders.Y:SetMax(MaxY)
	CountSliders.Z:SetMax(MaxZ)

	-- Clamp current values to valid range
	if CurrentX < MinX then
		CountSliders.X:SetValue(MinX)
		ACF.SetClientData("CrateProjectilesX", MinX)
	elseif CurrentX > MaxX then
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
	local Shape  = ACF.GetClientString("AmmoShape", "Box")

	if Class and BulletData then
		BoxSize = GetSizeForShape(Shape, CountX, CountY, CountZ, Class, ToolData, BulletData)
		-- Set the ammo size client data so it gets sent to the server
		ACF.SetClientData("AmmoSizeX", BoxSize.x)
		ACF.SetClientData("AmmoSizeY", BoxSize.y)
		ACF.SetClientData("AmmoSizeZ", BoxSize.z)

		GhostData.Secondary.Scale = BoxSize
		ACF.UpdateGhostEntity(GhostData)
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

		ACF.SetClientData("RoundLength", BulletData.RoundLength)
		ACF.SetClientData("PropRatio", BulletData.PropRatio)

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
	RoundLength:TrackClientData("RoundLength", "SetText", "GetText")
	RoundLength:TrackClientData("PropRatio")
	RoundLength:DefineSetter(function()
		local Text = language.GetPhrase("acf.menu.ammo.round_length")
		local CurLength = math.Round(BulletData.RoundLength, 2)
		local MaxLength = BulletData.MaxRoundLength

		return Text:format(CurLength, MaxLength)
	end)

	-- What makes a round's stowed diameter exceed its caliber
	local RoundDiameter = Base:AddLabel()
	RoundDiameter:TrackClientData("Caliber", "SetText", "GetText")
	RoundDiameter:TrackClientData("Weapon")
	RoundDiameter:TrackClientData("CaseScale")
	RoundDiameter:DefineSetter(function()
		local Text      = language.GetPhrase("acf.menu.ammo.round_diameter")
		local Caliber   = BulletData.Caliber or 0
		local CaseScale = BulletData.CaseScale or 1

		return Text:format(math.Round(Caliber * CaseScale, 2), math.Round(CaseScale, 2))
	end)

	-- RoundLength and PropRatio are the actual stored/networked round dimensions (see
	-- round_functions.lua's ACF.UpdateRoundSpecs) -- ProjLength/PropLength are just derived from
	-- them for display and mass/volume math. Each slider is bound straight to its own real
	-- ClientVar and only has to worry about its own value; ACF.UpdateRoundSpecs handles clamping
	-- PropRatio's valid window against the current RoundLength (and vice versa) on its own, so
	-- there's no cross-slider pushback needed here anymore.
	local TotalLength = Base:AddSlider("#acf.menu.ammo.total_length", BulletData.MinProjLength + BulletData.MinPropLength, BulletData.MaxRoundLength, 2)
	TotalLength:SetClientData("RoundLength", "OnValueChanged")
	TotalLength:DefineSetter(function(Panel, _, _, Value)
		ToolData.RoundLength = Value

		Ammo:UpdateRoundData(ToolData, BulletData)

		Panel:SetValue(BulletData.RoundLength)

		-- Update projectile count limits when round dimensions change (skip for missiles)
		UpdateProjectileCountLimits(ToolData, BulletData, true)

		return BulletData.RoundLength
	end)

	local PropRatio = Base:AddSlider("#acf.menu.ammo.propellant_ratio", 0, 1, 3)
	PropRatio:SetClientData("PropRatio", "OnValueChanged")
	PropRatio:DefineSetter(function(Panel, _, _, Value)
		ToolData.PropRatio = Value

		Ammo:UpdateRoundData(ToolData, BulletData)

		Panel:SetValue(BulletData.PropRatio)

		-- Update projectile count limits when round dimensions change (skip for missiles)
		UpdateProjectileCountLimits(ToolData, BulletData, true)

		return BulletData.PropRatio
	end)

	-- Classes allowing no necking cap at 1, leaving DNumSlider a degenerate min == max range
	local CaseScale = Base:AddSlider("#acf.menu.ammo.case_scale", 1, BulletData.MaxCaseScale, 2)
	CaseScale:SetClientData("CaseScale", "OnValueChanged")
	CaseScale:DefineSetter(function(Panel, _, _, Value)
		ToolData.CaseScale = Value

		Ammo:UpdateRoundData(ToolData, BulletData)

		Panel:SetValue(BulletData.CaseScale)

		-- A wider case is a wider round, so the crate's projectile counts have to be refit
		UpdateProjectileCountLimits(ToolData, BulletData, true)

		return BulletData.CaseScale
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

---Returns the point cost of a single round, mirroring acf_ammo's GetRoundCost.
---Guidance and fuze are read live rather than from a ToolData snapshot, since
---they can change without the surrounding menu being rebuilt.
---@return number Cost The cost of one round in points.
local function GetRoundCost()
	local Cost = Ammo:GetCost(BulletData)

	-- Only missile ammo carries guidance and fuze, and both are charged per round.
	if ACF.GetClientString("Destiny") ~= "Missiles" then return Cost end

	local Guidance = Classes.Guidances.Get(ACF.GetClientString("Guidance"))
	local Fuze     = Classes.Fuzes.Get(ACF.GetClientString("Fuze"))

	if Guidance then Cost = Cost + Guidance:GetCost() end
	if Fuze then Cost = Cost + Fuze:GetCost() end

	return Cost
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
	Crate:TrackClientData("AmmoShape")
	Crate:TrackClientData("HexPacking")
	Crate:TrackClientData("TwoPiece")
	-- Track projectile dimensions so crate size updates when ammo config changes
	Crate:TrackClientData("RoundLength")
	Crate:TrackClientData("PropRatio")
	Crate:TrackClientData("CaseScale")
	Crate:TrackClientData("Tracer")
	-- Missile ammo folds guidance and fuze cost into every round
	Crate:TrackClientData("Guidance")
	Crate:TrackClientData("Fuze")
	Crate:DefineSetter(function()
		UpdateBoxSizeFromProjectileCounts(ToolData, BulletData)

		local CrateText = language.GetPhrase("acf.menu.ammo.crate_stats")
		local Shape = ACF.GetClientString("AmmoShape", "Box")

		-- Calculate rounds based on shape
		local CountX   = ACF.GetClientNumber("CrateProjectilesX", 3)
		local CountY   = ACF.GetClientNumber("CrateProjectilesY", 3)
		local CountZ   = ACF.GetClientNumber("CrateProjectilesZ", 3)
		local TwoPiece = ACF.GetClientBool("TwoPiece", false)
		local Rounds   = GetRoundCount(Shape, CountX, CountY, CountZ, TwoPiece)

		-- CartMass is the mass of a whole round, so it multiplies complete rounds, not cells
		local Load      = math.floor(BulletData.CartMass * Rounds)
		local Mass      = ACF.FormatMass(Load)
		local Cost      = ACF.FormatCost(Rounds * GetRoundCost())

		return CrateText:format(Mass, Cost, Rounds)
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
	PenTable:TrackClientData("RoundLength", "SetText")
	PenTable:TrackClientData("PropRatio")
	PenTable:TrackClientData("CaseScale")
	PenTable:TrackClientData("FillerRatio")
	PenTable:TrackClientData("LinerAngle")
	PenTable:TrackClientData("LinerAngleRatio")
	PenTable:TrackClientData("StandoffRatio")
	PenTable:TrackClientData("TelescopeRatio")

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

---Creates the bullet visualizer panel on the ACF menu, drawing a schematic side profile of the current round.
---@param Base userdata The panel being populated with the visualizer.
---@param ToolData table<string, any> The copy of the local player's client data variables.
local function AddVisual(Base, ToolData)
	if Ammo.PreCreateAmmoVisual then
		local Result = Ammo:PreCreateAmmoVisual(Base, ToolData, BulletData)

		if not Result then return end
	end

	local Result = hook.Run("ACF_PreCreateAmmoVisual", Base, ToolData, Ammo, BulletData)

	if not Result then return end

	local Visual = Base:AddVisualizer()
	Base.Visual = Visual
	local MenuSizeX = Base:GetParent():GetParent():GetWide() -- Parent of the parent of this item should be the menu panel
	Visual:SetSize(MenuSizeX, MenuSizeX * 0.3)

	Visual:TrackClientData("RoundLength")
	Visual:TrackClientData("PropRatio")
	Visual:TrackClientData("CaseScale")
	Visual:TrackClientData("Tracer")
	Visual:TrackClientData("FillerRatio")
	Visual:TrackClientData("LinerAngle")
	Visual:TrackClientData("LinerAngleRatio")
	Visual:TrackClientData("StandoffRatio")
	Visual:TrackClientData("SmokeWPRatio")
	Visual:TrackClientData("TelescopeRatio")

	Visual:DefineSetter(function(Panel)
		local Ammo = AmmoTypes.Get(ToolData.AmmoType)

		-- Each ammo type draws its own bullet; see Ammo:DrawAmmoVisual in the respective ammo_types file
		if Ammo.DrawAmmoVisual then
			Panel:SetDrawFunc(function(self, w, h)
				Ammo:DrawAmmoVisual(self, w, h, ToolData, BulletData)
			end)
		else
			Panel:Clear()
		end
	end)

	if Ammo.OnCreateAmmoVisual then
		Ammo:OnCreateAmmoVisual(Base, ToolData, BulletData)
	end

	hook.Run("ACF_OnCreateAmmoVisual", Base, ToolData, Ammo, BulletData)
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

	Graph:TrackClientData("RoundLength")
	Graph:TrackClientData("PropRatio")
	Graph:TrackClientData("CaseScale")
	Graph:TrackClientData("FillerRatio")
	Graph:TrackClientData("LinerAngle")
	Graph:TrackClientData("LinerAngleRatio")
	Graph:TrackClientData("StandoffRatio")
	Graph:TrackClientData("SmokeWPRatio")
	Graph:TrackClientData("TelescopeRatio")

	Graph:DefineSetter(function(Panel)
		Panel:Clear()

		Panel:SetXLabel("#acf.menu.ammo.distance")
		Panel:SetFidelity(8)

		Graph:SetXSpacing(100)
		Graph:SetYSpacing(50)

		local Ammo = AmmoTypes.Get(ToolData.AmmoType)

		-- Each ammo type draws its own graph; see Ammo:PlotAmmoGraph in the respective ammo_types file
		if Ammo.PlotAmmoGraph then
			Ammo:PlotAmmoGraph(Panel, ToolData, BulletData)
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
	AddVisual(Base, ToolData)
	AddControls(Base, ToolData)
	AddInformation(Base, ToolData)
	AddPenetrationTable(Base, ToolData)
	AddGraph(Base, ToolData)

	Menu:EndTemporal(Base)

	-- Update projectile count limits after menu is created
	UpdateProjectileCountLimits(ToolData, BulletData)
end

---Updates the shape selector visibility. Both Crate and Drum are available for every weapon type.
---@param Menu userdata The menu containing the shape selector.
local function UpdateShapeSelector(Menu)
	local ShapeList = Menu.AmmoShapeList
	if not ShapeList then return end

	ShapeList:SetVisible(true)
end

---Creates the basic information and panels on the ammunition menu.
---@param Menu userdata The panel in which the entire ACF menu is being placed on.
function ACF.CreateAmmoMenu(Menu)
	-- ============================================
	-- Container Settings Section
	-- ============================================
	local ContainerBase = Menu:AddCollapsible("Container Settings", true, "icon16/box.png")

	-- Set default projectile count values before creating controls to prevent nil value errors
	local DefaultCountX = ACF.GetClientNumber("CrateProjectilesX", 3)
	local DefaultCountY = ACF.GetClientNumber("CrateProjectilesY", 3)
	local DefaultCountZ = ACF.GetClientNumber("CrateProjectilesZ", 3)
	ACF.SetClientData("CrateProjectilesX", DefaultCountX, true)
	ACF.SetClientData("CrateProjectilesY", DefaultCountY, true)
	ACF.SetClientData("CrateProjectilesZ", DefaultCountZ, true)

	-- Shape selector (Crate, or one of the drum layouts)
	local ShapeList = ContainerBase:AddComboBox()
	local ShapeIDs  = { Box = 1 }

	ShapeList:AddChoice("Crate", "Box")

	do
		-- Drum shapes come from the layout registry so adding one only touches round_functions
		local Keys = {}

		for Key in pairs(ACF.DrumLayouts) do Keys[#Keys + 1] = Key end

		table.sort(Keys)

		for Index, Key in ipairs(Keys) do
			ShapeList:AddChoice(ACF.DrumLayouts[Key].Name, Key)
			ShapeIDs[Key] = Index + 1 -- "Crate" occupies slot 1
		end
	end

	-- Store references for later updates
	Menu.AmmoShapeList = ShapeList

	-- Set default shape
	local DefaultShape = ACF.GetClientString("AmmoShape", "Box")

	if DefaultShape ~= "Box" and not ACF.IsDrumShape(DefaultShape) then DefaultShape = "Box" end

	ACF.SetClientData("AmmoShape", DefaultShape, true)
	ShapeList:ChooseOptionID(ShapeIDs[DefaultShape] or 1)

	---Both packing options only change how rounds are stowed, never how they fly, so they share
	---a setter: re-derive the bullet data and let the crate resize around the new cell size.
	local function ApplyPackingChange(Panel, Value)
		Panel:SetValue(Value)

		local ToolData = ACF.GetAllClientData()
		local Class    = GetWeaponClass(ToolData)

		if Class then
			local CurrentAmmo = ACF.Classes.AmmoTypes.Get(ToolData.AmmoType)

			if CurrentAmmo then
				local NewBulletData = CurrentAmmo:ClientConvert(ToolData)

				UpdateProjectileCountLimits(ToolData, NewBulletData)
				UpdateBoxSizeFromProjectileCounts(ToolData, NewBulletData)
			end
		end

		return Value
	end

	-- Hex packing staggers alternating rows/layers so they nest, trading arrangement for a tighter fit
	ACF.SetClientData("HexPacking", false, true)

	local HexPacking = ContainerBase:AddCheckBox(language.GetPhrase("acf.menu.ammo.hex_packing"))
	HexPacking:SetClientData("HexPacking", "OnChange")
	HexPacking:DefineSetter(function(Panel, _, _, Value)
		return ApplyPackingChange(Panel, Value)
	end)

	-- Two piece ammo stows the charge and projectile separately, halving the length of a cell.
	-- Seed the data var first: SetClientData only takes the checkbox's own value when the var is
	-- nil, so without this the box comes back ticked from whatever it was left on earlier.
	ACF.SetClientData("TwoPiece", false, true)

	local TwoPiece = ContainerBase:AddCheckBox(language.GetPhrase("acf.menu.ammo.two_piece"))
	TwoPiece:SetClientData("TwoPiece", "OnChange")
	TwoPiece:DefineSetter(function(Panel, _, _, Value)
		return ApplyPackingChange(Panel, Value)
	end)

	-- Labels that change based on shape
	local CountXLabel = "#acf.menu.ammo.projectiles_length"
	local CountYLabel = "#acf.menu.ammo.projectiles_width"
	local CountZLabel = "#acf.menu.ammo.projectiles_height"

	local CountX = ContainerBase:AddSlider(CountXLabel, 1, 50, 0)
	CountX:SetClientData("CrateProjectilesX", "OnValueChanged")
	CountX:DefineSetter(function(Panel, _, _, Value)
		local Min = Panel:GetMin() or 1
		local Count = math.max(Min, math.Round(Value))
		Panel:SetValue(Count)
		return Count
	end)

	local CountY = ContainerBase:AddSlider(CountYLabel, 1, 50, 0)
	CountY:SetClientData("CrateProjectilesY", "OnValueChanged")
	CountY:DefineSetter(function(Panel, _, _, Value)
		local Min = Panel:GetMin() or 1
		local Count = math.max(Min, math.Round(Value))
		Panel:SetValue(Count)
		return Count
	end)

	local CountZ = ContainerBase:AddSlider(CountZLabel, 1, 50, 0)
	CountZ:SetClientData("CrateProjectilesZ", "OnValueChanged")
	CountZ:DefineSetter(function(Panel, _, _, Value)
		local Min = Panel:GetMin() or 1
		local Count = math.max(Min, math.Round(Value))
		Panel:SetValue(Count)
		return Count
	end)

	---Relabels the count sliders for the given shape. Drums drop the Y axis entirely and let
	---their layout name both remaining axes, since they mean different things per layout.
	local function ApplyShapeToSliders(Shape)
		local Layout = ACF.GetDrumLayout(Shape)

		CountX:SetVisible(true)

		if Layout then
			CountX:SetText(Layout.PrimaryLabel)
			CountX:SetMin(Layout.MinPrimary)
			CountY:SetVisible(false)
			CountZ:SetText(Layout.SecondaryLabel)
		else
			CountX:SetText(language.GetPhrase(CountXLabel))
			CountX:SetMin(1) -- Reset to crate minimum
			CountY:SetVisible(true)
			CountZ:SetText(language.GetPhrase(CountZLabel))
		end
	end

	-- Handle shape selection changes
	function ShapeList:OnSelect(_, _, Data)
		ACF.SetClientData("AmmoShape", Data)

		ApplyShapeToSliders(Data)

		-- Update slider limits when shape changes (drums have different min/max)
		local ToolData = ACF.GetAllClientData()
		local Class = GetWeaponClass(ToolData)
		if Class then
			local CurrentAmmo = ACF.Classes.AmmoTypes.Get(ToolData.AmmoType)
			if CurrentAmmo then
				local BulletData = CurrentAmmo:ClientConvert(ToolData)
				UpdateProjectileCountLimits(ToolData, BulletData)
			end
		end
	end

	-- Apply initial visibility based on default shape
	if ACF.IsDrumShape(DefaultShape) then
		ApplyShapeToSliders(DefaultShape)
	end

	local Capacity = ContainerBase:AddLabel("")
	Capacity:TrackClientData("CrateProjectilesX", "SetText")
	Capacity:TrackClientData("CrateProjectilesY", "SetText")
	Capacity:TrackClientData("CrateProjectilesZ", "SetText")
	Capacity:TrackClientData("AmmoShape")
	Capacity:TrackClientData("TwoPiece")
	Capacity:DefineSetter(function()
		local CountX   = ACF.GetClientNumber("CrateProjectilesX", 3)
		local CountY   = ACF.GetClientNumber("CrateProjectilesY", 3)
		local CountZ   = ACF.GetClientNumber("CrateProjectilesZ", 3)
		local Shape    = ACF.GetClientString("AmmoShape", "Box")
		local TwoPiece = ACF.GetClientBool("TwoPiece", false)

		local RoundCount = GetRoundCount(Shape, CountX, CountY, CountZ, TwoPiece)

		return "Capacity: " .. RoundCount .. (RoundCount == 1 and " round" or " rounds")
	end)

	local Size = ContainerBase:AddLabel("")
	Size:TrackClientData("CrateProjectilesX", "SetText")
	Size:TrackClientData("CrateProjectilesY", "SetText")
	Size:TrackClientData("CrateProjectilesZ", "SetText")
	Size:TrackClientData("AmmoShape")
	Size:TrackClientData("HexPacking")
	Size:TrackClientData("TwoPiece")
	Size:TrackClientData("RoundLength") -- Update when round dimensions change
	Size:TrackClientData("PropRatio")
	Size:TrackClientData("CaseScale")
	Size:TrackClientData("Tracer")
	Size:DefineSetter(function()
		-- Recalculate BoxSize to ensure we have the latest values
		local ToolData = ACF.GetAllClientData()
		local Class = GetWeaponClass(ToolData)
		if Class then
			local CurrentAmmo = ACF.Classes.AmmoTypes.Get(ToolData.AmmoType)
			if CurrentAmmo then
				local BulletData = CurrentAmmo:ClientConvert(ToolData)
				local CountX = ACF.GetClientNumber("CrateProjectilesX", 3)
				local CountY = ACF.GetClientNumber("CrateProjectilesY", 3)
				local CountZ = ACF.GetClientNumber("CrateProjectilesZ", 3)
				local Shape = ACF.GetClientString("AmmoShape", "Box")

				BoxSize = GetSizeForShape(Shape, CountX, CountY, CountZ, Class, ToolData, BulletData)
			end
		end

		local Shape  = ACF.GetClientString("AmmoShape", "Box")
		local Layout = ACF.GetDrumLayout(Shape)

		if Layout then
			local SizeText = Layout.Name .. " Size: Diameter %.2f x Height %.2f"
			return SizeText:format(math.Round(BoxSize.x, 2), math.Round(BoxSize.z, 2))
		else
			local SizeText = "Crate Size: %.2f x %.2f x %.2f"
			return SizeText:format(math.Round(BoxSize.x, 2), math.Round(BoxSize.y, 2), math.Round(BoxSize.z, 2))
		end
	end)

	-- Store references for updating max values later
	CountSliders.X = CountX
	CountSliders.Y = CountY
	CountSliders.Z = CountZ

	-- ============================================
	-- Ammo Settings Section
	-- ============================================
	local Base = Menu:AddCollapsible("#acf.menu.ammo.ammo_info", true, "icon16/chart_bar_edit.png")

	-- Ammo type selector (moved inside the collapsible)
	local List = Base:AddComboBox()
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

		-- Update shape selector visibility based on whether weapon is automatic
		UpdateShapeSelector(Menu)

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