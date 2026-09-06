local hook      = hook
local ACF       = ACF
local Classes   = ACF.Classes
local BoxSize   = Vector()

-- The crate keeps its drum/box UI logic keyed on a short shape string, but the entity's inherited
-- "Shape" field wants a ContainerShapes class FQN. This maps between them.
local SHAPE_FQN = {
	Box      = "ACF.ContainerShapes.Box",
	Cylinder = "ACF.ContainerShapes.Cylinder",
}
local FQN_SHAPE = {
	["ACF.ContainerShapes.Box"]      = "Box",
	["ACF.ContainerShapes.Cylinder"] = "Cylinder",
}

-- Menu state. AmmoCtx is the acf_ammo EntityContext this menu edits; Sub wraps its nested "AmmoType"
-- field (the live ammo-type instance, which holds Projectile/Propellant/Tracer/... ). BulletData is the
-- converted round data, recomputed whenever the config changes.
local AmmoCtx, Sub, Ammo, BulletData
local CountSliders = {}

local GhostData = {Secondary = {
	Model = "models/holograms/hq_rcube_thin.mdl",
	Material = "phoenix_storms/Future_vents",
	Scale = Vector(1, 1, 1),
}}

local GraphRed    = Color(200, 65, 65)
local GraphBlue   = Color(65, 65, 200)
local GraphRedAlt = Color(255, 65, 65)

-- Removes a panel's context callback when the panel is destroyed (menu rebuilds).
local function BindCleanup(Panel, Context, Field)
	local Old = Panel.OnRemove
	function Panel:OnRemove()
		if Old then Old(self) end
		if IsValid(Context) or Context then Context:RemoveCallback(self, Field) end
	end
end

-- Helpers exposed to ammo-type OnCreate* methods so per-type controls bind to the ammo context
-- instead of the old :SetClientData/:TrackClientData/:DefineSetter widget system:
--   ACF.AmmoMenu.Set(Field, Value)   -- write a field on the nested ammo instance (coerce + persist,
--                                       and fire the reactive labels via the ammo context's change event)
--   ACF.AmmoMenu.Reactive(Panel, fn) -- run fn() now and on every ammo change; auto-unbinds on remove
-- These read the module's current Sub/AmmoCtx upvalues, which are re-pointed whenever the ammo type
-- changes, so a control created for one ammo type always talks to that build's context.
ACF.AmmoMenu = ACF.AmmoMenu or {}

function ACF.AmmoMenu.Set(Field, Value)
	if Sub then Sub:Set(Field, Value) end
end

-- The acf_ammo EntityContext the menu is currently editing. Exposed so the missile menu (acfm_roundinject)
-- can reach the crate's nested Weapon -> Guidance/Fuze fields and write selections into the context.
function ACF.AmmoMenu.GetContext()
	return AmmoCtx
end

function ACF.AmmoMenu.Reactive(Panel, Refresh)
	Refresh(Panel)

	if AmmoCtx then
		AmmoCtx:OnChange(Panel, nil, function()
			if IsValid(Panel) then Refresh(Panel) end
		end)
		BindCleanup(Panel, AmmoCtx)
	end

	return Panel
end

-- A slider bound to an ammo field. Apply(Value) mutates the ammo instance (set the field + recompute
-- via UpdateRoundData); the field is then committed through the sub-context (persist + reactivity).
-- Snap(Panel) is optional and runs now + on every ammo change: use it for controls whose displayed
-- value/range depends on other fields (e.g. a HEAT liner angle that re-clamps as the round changes).
function ACF.AmmoMenu.Slider(Base, Title, Min, Max, Dec, Field, Apply, Snap)
	local Panel = Base:AddSlider(Title, Min, Max, Dec)
	if Sub then Panel:SetValue(Sub:Get(Field) or 0) end

	function Panel:OnValueChanged(Value)
		if self._Suppress then return end
		Apply(Value)
		ACF.AmmoMenu.Set(Field, Sub and Sub:Get(Field))
	end

	if Snap then
		ACF.AmmoMenu.Reactive(Panel, function()
			Panel._Suppress = true
			Snap(Panel)
			Panel._Suppress = false
		end)
	end

	return Panel
end

---Gets a key-value table of all the ammo type objects a given weapon class can make use of.
local function GetAmmoList(WeaponType)
	local Entries = Classes.GetSubtypes("ACF.Ammunition.BaseAmmo")
	local Result  = {}

	for K, V in pairs(Entries) do
		if V.Unlistable then continue end
		if V.Blacklist[Classes.GetTypeName(WeaponType)] then continue end
		if WeaponType and WeaponType.Blacklist and WeaponType.Blacklist[Classes.GetTypeName(V)] then continue end

		Result[K] = V
	end

	return Result
end

---Returns the weapon group object for the current context's weapon.
local function GetWeaponClass(ToolData)
	return Classes.GetSubtypeByName("ACF.Weapons.BaseWeapon", ToolData.Weapon)
end

-- ---------------------------------------------------------------------------------------------------
-- Per-weapon-class ammo memory. Each weapon class remembers its own selected ammo type + that type's
-- tuned params (so e.g. Autocannon-HE and Howitzer-HE stay separate). The live selection stays in the
-- ammo context as usual; here we mirror it into a per-class store (persist_cl) and restore from it
-- whenever the weapon class changes -- driven from List:LoadEntries via ScopeAmmo. The active scope is
-- stored ON the context (Ctx.AmmoScope), not module-wide, since the weapons and missiles pages each own
-- a separate acf_ammo context -- a module upvalue would flush one page's ammo under the other's key.
-- ---------------------------------------------------------------------------------------------------

local SaveTimer = "acf_menu_ammo_scope_save"

-- Writes a context's current ammo type ({ Type, Data }) under its scope. Ctx/Scope are passed explicitly
-- so a queued save still targets the right context+class even after the active menu has switched pages.
local function SaveScopedAmmo(Ctx, Scope)
	if ACF.AmmoMenu.SuppressPersist then return end -- dev selftest builds menus offscreen; don't touch the store
	if not (Ctx and Scope) then return end
	local Data = Ctx:Serialize().AmmoType
	if Data then ACF.Menu.SetAmmoForWeapon(Scope, Data) end
end

-- Debounced so dragging a slider doesn't hammer the disk (mirrors persist_cl's 0.5s gate). Binds the
-- context + scope at schedule time so the write is correct even if the page changes before it fires.
local function QueueScopedSave()
	if ACF.AmmoMenu.SuppressPersist then return end
	local Ctx   = AmmoCtx
	local Scope = Ctx and Ctx.AmmoScope
	if not (Ctx and Scope) then return end
	if timer.Exists(SaveTimer) then return end
	timer.Create(SaveTimer, 0.5, 1, function() SaveScopedAmmo(Ctx, Scope) end)
end

-- Re-keys the ammo memory to WeaponType's class: flushes the outgoing class's ammo, then restores this
-- class's saved ammo (type + params) -- or starts fresh for a class not configured before, so one class's
-- ammo never bleeds into another. Re-points the Sub/Ammo upvalues to the (possibly new) instance; the
-- caller (List:LoadEntries) then selects the type and rebuilds the controls.
local function ScopeAmmo(WeaponType)
	local Scope = WeaponType and Classes.GetTypeName(WeaponType)
	if not Scope or Scope == AmmoCtx.AmmoScope then return end

	local First = AmmoCtx.AmmoScope == nil

	if not First then
		if timer.Exists(SaveTimer) then timer.Remove(SaveTimer) end
		SaveScopedAmmo(AmmoCtx, AmmoCtx.AmmoScope) -- remember the outgoing class's ammo before switching
	end

	AmmoCtx.AmmoScope = Scope

	local Saved = ACF.Menu.GetAmmoForWeapon(Scope)
	if Saved then
		-- Visited class: restore its remembered ammo type + tuned params (silent -- LoadEntries rebuilds
		-- the controls right after).
		AmmoCtx:Set("AmmoType", Saved, true)
	elseif not First then
		-- Unseen class after a switch: keep the ammo TYPE the user is on (e.g. HE -> HE), but drop the
		-- previous class's tuned params so each class starts from defaults and diverges independently.
		local Cur     = AmmoCtx:Get("AmmoType")
		local CurType = (Cur and Cur.GetType) and Classes.GetTypeName(Cur:GetType()) or nil
		if CurType then AmmoCtx:Set("AmmoType", { Type = CurType, Data = {} }, true) end
	end
	-- First open with no saved data keeps whatever the context hydrated; it's saved under this class on edit.

	Sub  = ACF.Menu.SubContext(AmmoCtx, "AmmoType")
	Ammo = AmmoCtx:Get("AmmoType")

	if Ammo then
		Ammo.Weapon = AmmoCtx:Get("Weapon")
		BulletData  = Ammo:ClientConvert()
	end
end

-- Builds a flat snapshot of the current config for the pure round-math helpers (which expect the old
-- ToolData shape). Read-only: the context remains the source of truth for writes.
local function BuildToolData()
	local Weapon = AmmoCtx and AmmoCtx:Get("Weapon")
	local ShapeI = AmmoCtx and AmmoCtx:Get("Shape")
	local ShapeFQN = (ShapeI and ShapeI.GetType) and Classes.GetTypeName(ShapeI:GetType()) or SHAPE_FQN.Box

	local Data = {
		Weapon            = (Weapon and Weapon.GetType) and Classes.GetTypeName(Weapon:GetType()) or nil,
		Caliber           = (Weapon and Weapon.Caliber) or 0,
		AmmoType          = (Ammo and Ammo.GetType) and Classes.GetTypeName(Ammo:GetType()) or nil,
		CrateProjectilesX = AmmoCtx and AmmoCtx:Get("CrateProjectilesX") or 3,
		CrateProjectilesY = AmmoCtx and AmmoCtx:Get("CrateProjectilesY") or 3,
		CrateProjectilesZ = AmmoCtx and AmmoCtx:Get("CrateProjectilesZ") or 3,
		AmmoShape         = FQN_SHAPE[ShapeFQN] or "Box",
		Destiny           = AmmoCtx and AmmoCtx.Destiny or nil,
	}

	if Ammo then
		for _, Field in ipairs(Classes.GetTypeFields(Ammo:GetType())) do
			if Field.Menu then Data[Field.Name] = Ammo[Field.Name] end
		end
	end

	return Data
end

-- Convenience accessors backed by the context.
local function GetCount(Axis) return math.Round(AmmoCtx:Get("CrateProjectiles" .. Axis) or 3) end
local function IsDrum()
	local ShapeI = AmmoCtx:Get("Shape")
	local FQN = (ShapeI and ShapeI.GetType) and Classes.GetTypeName(ShapeI:GetType()) or SHAPE_FQN.Box
	return FQN == SHAPE_FQN.Cylinder
end

---Returns the mass of a hollow box given the current BoxSize and container armor.
local function GetEmptyMass()
	local Armor          = ACF.ContainerArmor * ACF.MmToInch
	local ExteriorVolume = BoxSize.x * BoxSize.y * BoxSize.z
	local InteriorVolume = math.max(0, (BoxSize.x - 2 * Armor) * (BoxSize.y - 2 * Armor) * (BoxSize.z - 2 * Armor))

	return math.Round((ExteriorVolume - InteriorVolume) * 0.13, 2)
end

local function CalculateMaxCounts(CountY, CountZ, ToolData)
	local Class = GetWeaponClass(ToolData)
	if not (Class and BulletData) then return 50, 50, 50 end

	local roundSize = ACF.GetCrateSizeFromProjectileCounts(1, 1, 1, Class, ToolData, BulletData)
	if not roundSize then return 50, 50, 50 end

	return ACF.GetMaxCounts(roundSize, ACF.AmmoMaxLength, ACF.AmmoMaxWidth, CountY, CountZ)
end

---Updates the min/max values for the projectile count sliders based on current round dimensions.
local function UpdateProjectileCountLimits(ToolData, SkipMissiles)
	-- IsValid (not just non-nil): after a rebuild these can point at removed panels, which are NULL --
	-- truthy but without slider methods -- so a plain nil check would still let :SetMin below crash.
	if not (IsValid(CountSliders.X) and IsValid(CountSliders.Y) and IsValid(CountSliders.Z)) then return end
	if SkipMissiles and ToolData.Destiny == "Missiles" then return end

	local CurrentX = GetCount("X")
	local CurrentY = GetCount("Y")
	local CurrentZ = GetCount("Z")

	local MinX = 1
	local MaxX, MaxY, MaxZ

	if IsDrum() then
		local Class = GetWeaponClass(ToolData)

		if Class and BulletData then
			local roundSize = ACF.GetRoundProperties(Class, ToolData, BulletData)

			if roundSize then
				MinX = ACF.GetMinRoundsPerRing()
				MaxX = ACF.GetMaxRoundsPerRing(roundSize, ACF.AmmoMaxWidth)
				MaxZ = ACF.GetMaxDrumLayers(roundSize, ACF.AmmoMaxLength)
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
		MaxX, MaxY, MaxZ = CalculateMaxCounts(CurrentY, CurrentZ, ToolData)
	end

	CountSliders.X:SetMin(MinX)
	CountSliders.X:SetMax(MaxX)
	CountSliders.Y:SetMax(MaxY)
	CountSliders.Z:SetMax(MaxZ)

	if CurrentX < MinX then
		CountSliders.X:SetValue(MinX)
		AmmoCtx:Set("CrateProjectilesX", MinX)
	elseif CurrentX > MaxX then
		CountSliders.X:SetValue(MaxX)
		AmmoCtx:Set("CrateProjectilesX", MaxX)
	end
	if CurrentY > MaxY then
		CountSliders.Y:SetValue(MaxY)
		AmmoCtx:Set("CrateProjectilesY", MaxY)
	end
	if CurrentZ > MaxZ then
		CountSliders.Z:SetValue(MaxZ)
		AmmoCtx:Set("CrateProjectilesZ", MaxZ)
	end
end

---Recomputes BoxSize from the current projectile counts + round data, and refreshes the ghost.
local function UpdateBoxSizeFromProjectileCounts(ToolData)
	local CountX = GetCount("X")
	local CountY = GetCount("Y")
	local CountZ = GetCount("Z")
	local Class  = GetWeaponClass(ToolData)

	if Class and BulletData then
		if IsDrum() then
			BoxSize = ACF.GetDrumCrateSizeFromProjectileCounts(CountX, CountZ, Class, ToolData, BulletData)
		else
			BoxSize = ACF.GetCrateSizeFromProjectileCounts(CountX, CountY, CountZ, Class, ToolData, BulletData)
		end

		GhostData.Secondary.Scale = BoxSize
		ACF.UpdateGhostEntity(GhostData)
	end
end

---Sets up the current ammo instance for menu display: weapon back-reference + converted round data.
local function RefreshBulletData()
	if not Ammo then return end

	Ammo.Weapon = AmmoCtx:Get("Weapon")
	BulletData  = Ammo:ClientConvert()
end

---Creates the entity preview panel on the ACF menu.
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
		if not Result then Sub:Set("Tracer", false) return end
	end

	local Result = hook.Run("ACF_PreCreateTracerControls", Base, ToolData, Ammo, BulletData)
	if not Result then Sub:Set("Tracer", false) return end

	local Tracer = Base:AddCheckBox(language.GetPhrase("acf.menu.ammo.tracer"))
	Tracer:SetValue(Ammo.Tracer and true or false)

	function Tracer:OnChange(Value)
		if self._Suppress then return end

		Ammo.Tracer = Value
		Ammo:UpdateRoundData()

		Sub:Set("Tracer", Value)
		-- Non-silent sub sets bubble to the ammo context's "any" event, refreshing all reactive labels.
		Sub:Set("Projectile", BulletData.ProjLength)
		Sub:Set("Propellant", BulletData.PropLength)
	end

	if Ammo.OnCreateTracerControls then
		Ammo:OnCreateTracerControls(Base, ToolData, BulletData)
	end

	hook.Run("ACF_OnCreateTracerControls", Base, ToolData, Ammo, BulletData)
end

---Creates the ammunition control panels on the ACF menu.
local function AddControls(Base, ToolData)
	if Ammo.PreCreateAmmoControls then
		local Result = Ammo:PreCreateAmmoControls(Base, ToolData, BulletData)
		if not Result then return end
	end

	local Result = hook.Run("ACF_PreCreateAmmoControls", Base, ToolData, Ammo, BulletData)
	if not Result then return end

	local RoundLength = Base:AddLabel()
	local function UpdateRoundLength()
		local Text = language.GetPhrase("acf.menu.ammo.round_length")
		return Text:format(BulletData.ProjLength + BulletData.PropLength, Ammo.GUIData.MaxRoundLength)
	end
	RoundLength:SetText(UpdateRoundLength())
	AmmoCtx:OnChange(RoundLength, nil, function() if IsValid(RoundLength) then RoundLength:SetText(UpdateRoundLength()) end end)
	BindCleanup(RoundLength, AmmoCtx)

	local Projectile = Base:AddSlider("#acf.menu.ammo.projectile_length", 0, Ammo.GUIData.MaxRoundLength, 2)
	local Propellant = Base:AddSlider("#acf.menu.ammo.propellant_length", 0, Ammo.GUIData.MaxRoundLength, 2)

	Projectile:SetValue(Ammo.Projectile or BulletData.ProjLength)
	function Projectile:OnValueChanged(Value)
		if self._Suppress then return end

		Ammo.Projectile = Value
		BulletData.Priority = "Projectile"
		Ammo:UpdateRoundData()

		Propellant._Suppress = true
		Propellant:SetValue(BulletData.PropLength)
		Propellant._Suppress = false
		self._Suppress = true
		self:SetValue(BulletData.ProjLength)
		self._Suppress = false

		Sub:Set("Projectile", BulletData.ProjLength)
		Sub:Set("Propellant", BulletData.PropLength)

		UpdateProjectileCountLimits(BuildToolData(), true)
	end

	Propellant:SetValue(Ammo.Propellant or BulletData.PropLength)
	function Propellant:OnValueChanged(Value)
		if self._Suppress then return end

		Ammo.Propellant = Value
		BulletData.Priority = "Propellant"
		Ammo:UpdateRoundData()

		Projectile._Suppress = true
		Projectile:SetValue(BulletData.ProjLength)
		Projectile._Suppress = false
		self._Suppress = true
		self:SetValue(BulletData.PropLength)
		self._Suppress = false

		Sub:Set("Projectile", BulletData.ProjLength)
		Sub:Set("Propellant", BulletData.PropLength)

		UpdateProjectileCountLimits(BuildToolData(), true)
	end

	if Ammo.OnCreateAmmoControls then
		Ammo:OnCreateAmmoControls(Base, ToolData, BulletData)
	end

	hook.Run("ACF_OnCreateAmmoControls", Base, ToolData, Ammo, BulletData)

	AddTracer(Base, ToolData)

	local AmmoStage = Base:AddNumberWang("#acf.menu.ammo.stage", ACF.AmmoStageMin, ACF.AmmoStageMax)
	AmmoStage:SetValue(AmmoCtx:Get("AmmoStage") or 1)
	function AmmoStage:OnValueChanged(Value)
		AmmoCtx:Set("AmmoStage", Value)
	end
end

---Creates the ammunition information panels on the ACF menu.
local function AddCrateInformation(Base, ToolData)
	if Ammo.PreCreateCrateInformation then
		local Result = Ammo:PreCreateCrateInformation(Base, ToolData, BulletData)
		if not Result then return end
	end

	local Result = hook.Run("ACF_PreCreateCrateInformation", Base, ToolData, Ammo, BulletData)
	if not Result then return end

	local Crate = Base:AddLabel()

	local function UpdateCrateText()
		local Data = BuildToolData()
		UpdateBoxSizeFromProjectileCounts(Data)

		local CrateText = language.GetPhrase("acf.menu.ammo.crate_stats")
		local CountX, CountY, CountZ = GetCount("X"), GetCount("Y"), GetCount("Z")
		local Rounds = IsDrum() and (CountX * CountZ) or (CountX * CountY * CountZ)

		local Empty = GetEmptyMass()
		local Load  = math.floor(BulletData.CartMass * Rounds)
		local Mass  = ACF.GetProperMass(math.floor(Empty + Load))

		return CrateText:format(ACF.ContainerArmor, Mass, Rounds)
	end

	Crate:SetText(UpdateCrateText())
	AmmoCtx:OnChange(Crate, nil, function() if IsValid(Crate) then Crate:SetText(UpdateCrateText()) end end)
	BindCleanup(Crate, AmmoCtx)

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
	if ToolData.AmmoType == "ACF.Ammunition.SM" or ToolData.AmmoType == "ACF.Ammunition.HE" then return end

	local PenTable = Base:AddTable(5, 6)
	PenTable.SetCellsSize(55, 20)
	PenTable.SetCellValue(1, 1, "Range")
	PenTable.SetCellValue(2, 1, "Velocity")
	PenTable.SetCellValue(3, 1, "0 " .. language.GetPhrase("acf.menu.ammo.pen_table_deg"))
	PenTable.SetCellValue(4, 1, "30 " .. language.GetPhrase("acf.menu.ammo.pen_table_deg"))
	PenTable.SetCellValue(5, 1, "60 " .. language.GetPhrase("acf.menu.ammo.pen_table_deg"))

	local function UpdatePenTable()
		local Ranges = {0, 100, 250, 500, 800}
		for index, range in pairs(Ranges) do
			local Penetration, Velocity = Ammo:GetRangedPenetration(BulletData, range)

			if ToolData.AmmoType == "ACF.Ammunition.HEAT" or ToolData.AmmoType == "ACF.Ammunition.HEATFS" then
				Penetration = Ammo:GetPenetration(BulletData, BulletData.Standoff)
			end

			PenTable.SetCellValue(1, 1 + index, math.floor(range) .. " " .. language.GetPhrase("acf.menu.ammo.pen_table_m"))
			PenTable.SetCellValue(2, 1 + index, math.Round(Velocity) .. " " .. language.GetPhrase("acf.menu.ammo.pen_table_ms"))
			PenTable.SetCellValue(3, 1 + index, math.Round(Penetration) .. " " .. language.GetPhrase("acf.menu.ammo.pen_table_mm"))
			PenTable.SetCellValue(4, 1 + index, math.Round(Penetration / 1.1547) .. " " .. language.GetPhrase("acf.menu.ammo.pen_table_mm"))
			PenTable.SetCellValue(5, 1 + index, math.Round(Penetration / 2) .. " " .. language.GetPhrase("acf.menu.ammo.pen_table_mm"))
		end
	end

	UpdatePenTable()
	AmmoCtx:OnChange(PenTable, nil, function() if IsValid(PenTable) then UpdatePenTable() end end)
	BindCleanup(PenTable, AmmoCtx)

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
	local MenuSizeX = Base:GetParent():GetParent():GetWide()
	Graph:SetSize(MenuSizeX, MenuSizeX * 0.5)

	local PenetrationText = language.GetPhrase("acf.menu.ammo.penetration")

	Graph:SetXRange(0, 1000)
	Graph:SetXLabel("#acf.menu.ammo.distance")
	Graph:SetYLabel(PenetrationText)
	Graph:SetXSpacing(100)
	Graph:SetYSpacing(50)
	Graph:SetFidelity(16)

	local function Replot()
		local Panel = Graph
		Panel:Clear()
		Panel:SetXLabel("#acf.menu.ammo.distance")
		Panel:SetFidelity(8)
		Graph:SetXSpacing(100)
		Graph:SetYSpacing(50)

		-- Fresh instance for the graph so its BulletData/GUIData are self-contained.
		local Data       = BuildToolData()
		local GraphAmmo  = Classes.GetSubtypeByName("ACF.Ammunition.BaseAmmo", Data.AmmoType)()
		GraphAmmo.Weapon = AmmoCtx:Get("Weapon")
		for _, Field in ipairs(Classes.GetTypeFields(GraphAmmo:GetType())) do
			if Field.Menu and Data[Field.Name] ~= nil then GraphAmmo[Field.Name] = Data[Field.Name] end
		end
		local GraphBullet = GraphAmmo:ClientConvert()

		if Data.AmmoType == "ACF.Ammunition.HEAT" or Data.AmmoType == "ACF.Ammunition.HEATFS" then
			local PassiveStandoffPen = GraphAmmo:GetPenetration(GraphBullet, GraphBullet.Standoff)
			local BreakupDistPen     = GraphAmmo:GetPenetration(GraphBullet, GraphBullet.BreakupDist)

			Panel:SetYRange(0, math.max(BreakupDistPen, PassiveStandoffPen) * 1.5)
			Panel:SetXRange(0, GraphBullet.BreakupDist * 1000 * 2.5)
			Panel:SetXLabel("#acf.menu.ammo.standoff")

			Panel:PlotPoint(language.GetPhrase("acf.menu.ammo.passive"), GraphBullet.Standoff * 1000, PassiveStandoffPen, GraphBlue)
			Panel:PlotPoint(language.GetPhrase("acf.menu.ammo.breakup"), GraphBullet.BreakupDist * 1000, BreakupDistPen, GraphRed)

			Panel:PlotFunction(PenetrationText, GraphRedAlt, function(X)
				return GraphAmmo:GetPenetration(GraphBullet, X / 1000)
			end)
		elseif Data.AmmoType == "ACF.Ammunition.HE" then
			local BlastRadiusText = language.GetPhrase("acf.menu.ammo.blast_radius")

			Panel:SetYLabel(BlastRadiusText)
			Panel:SetXLabel("")
			Panel:SetYSpacing(10)
			Panel:SetXRange(0, 10)
			Panel:SetYRange(0, GraphAmmo.GUIData.BlastRadius * 2)

			Panel:PlotLimitLine(BlastRadiusText, true, GraphAmmo.GUIData.BlastRadius, GraphRed)
			Panel:PlotFunction(BlastRadiusText, GraphRed, function()
				return GraphAmmo.GUIData.BlastRadius
			end)
		elseif Data.AmmoType == "ACF.Ammunition.SM" then
			Panel:SetYLabel("#acf.menu.ammo.smoke_radius")
			Panel:SetXLabel("#acf.menu.ammo.time")
			Panel:SetYSpacing(10)
			Panel:SetXSpacing(5)

			local WPTime = GraphAmmo.GUIData.WPLife or 0
			local SFTime = GraphAmmo.GUIData.SMLife or 0
			local MinWP  = GraphAmmo.GUIData.WPRadiusMin or 0
			local MaxWP  = GraphAmmo.GUIData.WPRadiusMax or 0
			local MinSF  = GraphAmmo.GUIData.SMRadiusMin or 0
			local MaxSF  = GraphAmmo.GUIData.SMRadiusMax or 0

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
			Panel:SetYRange(0, math.ceil(GraphAmmo.GUIData.MaxPen or 0) * 1.1)

			Panel:PlotPoint(language.GetPhrase("acf.menu.ammo.300m"), 300, GraphAmmo:GetRangedPenetration(GraphBullet, 300), GraphBlue)
			Panel:PlotPoint(language.GetPhrase("acf.menu.ammo.800m"), 800, GraphAmmo:GetRangedPenetration(GraphBullet, 800), GraphBlue)

			Panel:PlotFunction(PenetrationText, GraphRedAlt, function(X)
				return GraphAmmo:GetRangedPenetration(GraphBullet, X)
			end)
		end
	end

	Replot()
	AmmoCtx:OnChange(Graph, nil, function() if IsValid(Graph) then Replot() end end)
	BindCleanup(Graph, AmmoCtx)

	if Ammo.OnCreateAmmoGraph then
		Ammo:OnCreateAmmoGraph(Base, ToolData, BulletData)
	end
end

---Returns the client bullet data currently being used by the menu.
function ACF.GetCurrentAmmoData()
	return BulletData
end

---Updates and populates the current ammunition menu.
function ACF.UpdateAmmoMenu(Menu)
	if not Ammo then return end

	local ToolData = BuildToolData()
	local Base = Menu.AmmoBase

	RefreshBulletData()

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

	UpdateProjectileCountLimits(BuildToolData())
end

---Updates the shape selector visibility based on whether the current weapon is automatic.
local function UpdateShapeSelector(Menu)
	local ShapeList = Menu.AmmoShapeList
	if not ShapeList then return end

	local ToolData = BuildToolData()
	local Class = GetWeaponClass(ToolData)
	local IsAutomatic = Class and Class.IsAutomatic

	if IsAutomatic then
		ShapeList:SetVisible(true)
	else
		ShapeList:SetVisible(false)

		if IsDrum() then
			AmmoCtx:Set("Shape", SHAPE_FQN.Box)
			ShapeList:ChooseOptionID(1)

			if CountSliders.X and CountSliders.Y and CountSliders.Z then
				CountSliders.X:SetVisible(true)
				CountSliders.X:SetMin(1)
				CountSliders.Y:SetVisible(true)
			end
		end
	end
end

---Creates the basic information and panels on the ammunition menu.
---@param Menu userdata The panel in which the entire ACF menu is being placed on.
---@param Context table The acf_ammo EntityContext this menu edits.
function ACF.CreateAmmoMenu(Menu, Context)
	AmmoCtx = Context
	Sub     = ACF.Menu.SubContext(AmmoCtx, "AmmoType")
	Ammo    = AmmoCtx:Get("AmmoType")

	-- Mirror the ammo type + its params into the active weapon class's memory whenever they change.
	AmmoCtx:OnChange("ScopedAmmoSave", "AmmoType", QueueScopedSave)

	local ContainerBase = Menu:AddCollapsible("Container Settings", true, "icon16/box.png")

	local ShapeList = ContainerBase:AddComboBox()
	ShapeList:AddChoice("Crate", "Box")
	ShapeList:AddChoice("Drum", "Cylinder")
	Menu.AmmoShapeList = ShapeList
	ShapeList:ChooseOptionID(IsDrum() and 2 or 1)

	local CountXLabel = "#acf.menu.ammo.projectiles_length"
	local CountYLabel = "#acf.menu.ammo.projectiles_width"
	local CountZLabel = "#acf.menu.ammo.projectiles_height"

	local function MakeCount(Label, Axis)
		local Slider = ContainerBase:AddSlider(Label, 1, 50, 0)
		Slider:SetValue(GetCount(Axis))
		function Slider:OnValueChanged(Value)
			if self._Suppress then return end
			local Min = self:GetMin() or 1
			local Count = math.max(Min, math.Round(Value))
			self._Suppress = true
			self:SetValue(Count)
			self._Suppress = false
			AmmoCtx:Set("CrateProjectiles" .. Axis, Count)
		end
		return Slider
	end

	local CountX = MakeCount(CountXLabel, "X")
	local CountY = MakeCount(CountYLabel, "Y")
	local CountZ = MakeCount(CountZLabel, "Z")

	function ShapeList:OnSelect(_, _, Data)
		AmmoCtx:Set("Shape", SHAPE_FQN[Data] or SHAPE_FQN.Box)

		if Data == "Cylinder" then
			CountX:SetVisible(true)
			CountX:SetText("Projectiles (Per Ring)")
			CountX:SetMin(6)
			CountY:SetVisible(false)
			CountZ:SetText("Projectiles (Stacks)")
		else
			CountX:SetVisible(true)
			CountX:SetText(language.GetPhrase(CountXLabel))
			CountX:SetMin(1)
			CountY:SetVisible(true)
			CountZ:SetText(language.GetPhrase(CountZLabel))
		end

		UpdateProjectileCountLimits(BuildToolData())
	end

	if IsDrum() then
		CountX:SetText("Projectiles (Per Ring)")
		CountX:SetMin(6)
		CountY:SetVisible(false)
		CountZ:SetText("Projectiles (Stacks)")
	end

	local Capacity = ContainerBase:AddLabel("")
	local function CapText()
		local RoundCount = IsDrum() and (GetCount("X") * GetCount("Z")) or (GetCount("X") * GetCount("Y") * GetCount("Z"))
		return "Capacity: " .. RoundCount .. (RoundCount == 1 and " round" or " rounds")
	end
	Capacity:SetText(CapText())
	AmmoCtx:OnChange(Capacity, nil, function() if IsValid(Capacity) then Capacity:SetText(CapText()) end end)
	BindCleanup(Capacity, AmmoCtx)

	local Size = ContainerBase:AddLabel("")
	local function SizeText()
		UpdateBoxSizeFromProjectileCounts(BuildToolData())
		if IsDrum() then
			return ("Drum Size: Diameter %.2f x Height %.2f"):format(math.Round(BoxSize.x, 2), math.Round(BoxSize.z, 2))
		end
		return ("Crate Size: %.2f x %.2f x %.2f"):format(math.Round(BoxSize.x, 2), math.Round(BoxSize.y, 2), math.Round(BoxSize.z, 2))
	end
	Size:SetText(SizeText())
	AmmoCtx:OnChange(Size, nil, function() if IsValid(Size) then Size:SetText(SizeText()) end end)
	BindCleanup(Size, AmmoCtx)

	CountSliders.X = CountX
	CountSliders.Y = CountY
	CountSliders.Z = CountZ

	local Base = Menu:AddCollapsible("#acf.menu.ammo.ammo_info", true, "icon16/chart_bar_edit.png")

	local List  = Base:AddComboBox()
	local Title = Base:AddTitle()
	local Desc  = Base:AddLabel()
	Desc:SetText("")

	local function UpdateTitle()
		local Weapon  = AmmoCtx:Get("Weapon")
		local Caliber = (Weapon and Weapon.Caliber) or 0
		return language.GetPhrase("acf.menu.weapons.name_text"):format(Caliber, Ammo and Ammo.Name or "")
	end
	Title:SetText(UpdateTitle())
	AmmoCtx:OnChange(Title, nil, function() if IsValid(Title) then Title:SetText(UpdateTitle()) end end)
	BindCleanup(Title, AmmoCtx)

	function List:LoadEntries(WeaponType)
		-- Point the ammo memory at this weapon class first, so we restore this class's ammo (see ScopeAmmo).
		ScopeAmmo(WeaponType)

		-- Populate WITHOUT auto-firing OnSelect: AddChoice's select flag would otherwise fire OnSelect for
		-- the first ammo type and reset the restored type's params (see ACF.Menu.PopulateCombo).
		ACF.Menu.PopulateCombo(self, GetAmmoList(WeaponType), "Name", "SpawnIcon")

		-- Restore the crate's current ammo type (from this class's memory) instead of defaulting to the
		-- first entry. Falls back to the first entry if that type isn't valid for this weapon.
		local Current = AmmoCtx:Get("AmmoType")
		local WantFQN = (Current and Current.GetType) and Classes.GetTypeName(Current:GetType()) or nil
		local Choices = self.ListData and self.ListData.Choices
		local Target  = 1

		if WantFQN and Choices then
			for I, Data in ipairs(Choices) do
				if Classes.GetTypeName(Data) == WantFQN then
					Target = I
					break
				end
			end
		end

		-- Clear the remembered selection so OnSelect always runs (rebuilds the controls) even when the
		-- restored type matches what the previous weapon class showed -- its tuned params may differ.
		self.Selected = nil
		if Choices and Choices[1] ~= nil then self:ChooseOptionID(Target) end

		UpdateShapeSelector(Menu)
	end

	function List:OnSelect(Index, _, Data)
		if self.Selected == Data then return end
		self.ListData.Index = Index
		self.Selected = Data

		-- Swap the crate's nested AmmoType to the chosen type -- but ONLY when it actually changes.
		-- Re-selecting the already-set type (e.g. restoring it on menu reopen) must keep the hydrated
		-- instance, otherwise its persisted settings (Projectile/Propellant/HollowRatio/...) would be
		-- reset to defaults (and then re-saved as defaults).
		local Current = AmmoCtx:Get("AmmoType")
		local CurType = (Current and Current.GetType) and Current:GetType() or nil

		if CurType ~= Data then
			AmmoCtx:Set("AmmoType", { Type = Classes.GetTypeName(Data), Data = {} })
		end

		Sub  = ACF.Menu.SubContext(AmmoCtx, "AmmoType")
		Ammo = AmmoCtx:Get("AmmoType")

		Title:SetText(UpdateTitle())
		Desc:SetText(Data.Description)

		ACF.UpdateAmmoMenu(Menu)
	end

	Menu.AmmoBase = Base

	return List
end
