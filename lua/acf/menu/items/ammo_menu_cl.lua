local hook      = hook
local ACF       = ACF
local Classes   = ACF.Classes
local BoxSize   = Vector()

-- The crate keeps its drum/box UI logic keyed on a short shape string, but the entity's inherited
-- "Shape" field wants a ContainerShapes class FQN. This maps between them.
local SHAPE_FQN = {Box = "ACF.ContainerShapes.Box"}
local FQN_SHAPE = {["ACF.ContainerShapes.Box"] = "Box"}

for Key in pairs(ACF.DrumLayouts) do
	local FQN = "ACF.ContainerShapes." .. Key

	SHAPE_FQN[Key] = FQN
	FQN_SHAPE[FQN] = Key
end

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

-- Shared graph colors, referenced by each ammo type's PlotAmmoGraph method
ACF.GraphColors = ACF.GraphColors or {
	Red    = Color(200, 65, 65),
	Blue   = Color(65, 65, 200),
	RedAlt = Color(255, 65, 65),
}

local GraphBlue   = ACF.GraphColors.Blue
local GraphRedAlt = ACF.GraphColors.RedAlt

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
local function GetShapeName()
	local ShapeI = AmmoCtx:Get("Shape")
	local FQN = (ShapeI and ShapeI.GetType) and Classes.GetTypeName(ShapeI:GetType()) or SHAPE_FQN.Box

	return FQN_SHAPE[FQN] or "Box"
end

local function IsDrum()
	return ACF.IsDrumShape(GetShapeName())
end

local function GetHexPacking()
	return AmmoCtx and AmmoCtx:Get("HexPacking") or false
end

---Complete rounds held by the given cell counts. Mirrors the server's UpdateCrateSize: two piece
---ammo stows the charge and projectile in a cell each, so it takes two cells to make a round.
local function GetRoundCount(CountX, CountY, CountZ)
	local Layout = ACF.GetDrumLayout(GetShapeName())
	local Rounds

	if Layout then
		-- For drums X is the layout's primary count, which is not always a round count:
		-- a vertical drum reads it as rings, so the layout works out the rounds per disk
		Rounds = Layout.GetPerDisk(CountX) * CountZ
	else
		Rounds = CountX * CountY * CountZ
	end

	if BulletData and BulletData.TwoPiece then Rounds = math.floor(Rounds * 0.5) end

	return Rounds
end

---Returns the cost of a single round, including any per-round missile components.
local function GetRoundCost()
	local Cost = Ammo:GetCost(BulletData)

	-- Only missile ammo carries guidance and fuze, and both are charged per round. They live as
	-- nested instances on the weapon rather than as flat tool data.
	local Weapon = AmmoCtx and AmmoCtx:Get("Weapon")

	if not Weapon then return Cost end

	local Guidance = Weapon.Guidance
	local Fuze     = Weapon.Fuze

	if Guidance and Guidance.GetCost then Cost = Cost + Guidance:GetCost() end
	if Fuze and Fuze.GetCost then Cost = Cost + Fuze:GetCost() end

	return Cost
end

---Returns the mass of the crate's walls for the current BoxSize.
local function GetEmptyMass()
	return math.Round(BoxSize.x * BoxSize.y * BoxSize.z * 0.13, 2)
end

local function CalculateMaxCounts(ToolData)
	local Class = GetWeaponClass(ToolData)
	if not (Class and BulletData) then return 50, 50, 50 end

	local roundSize = ACF.GetCrateSizeFromProjectileCounts(1, 1, 1, Class, ToolData, BulletData, GetHexPacking())
	if not roundSize then return 50, 50, 50 end

	return ACF.GetMaxCounts(roundSize, ACF.AmmoMaxLength, ACF.AmmoMaxWidth, GetHexPacking())
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

	local Layout = ACF.GetDrumLayout(GetShapeName())

	if Layout then
		local Class     = GetWeaponClass(ToolData)
		local roundSize = Class and BulletData and ACF.GetRoundProperties(Class, ToolData, BulletData)

		if roundSize then
			local HexPack = GetHexPacking()

			MinX = Layout.MinPrimary
			MaxX = Layout.GetMaxPrimary(roundSize, ACF.AmmoMaxWidth, HexPack)
			MaxZ = Layout.GetMaxStacks(roundSize, ACF.AmmoMaxLength, HexPack)
		else
			MaxX = 50
			MaxZ = 50
		end

		MaxY = 1
	else
		MaxX, MaxY, MaxZ = CalculateMaxCounts(ToolData)
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
			BoxSize = ACF.GetDrumCrateSizeFromProjectileCounts(CountX, CountZ, Class, ToolData, BulletData, GetHexPacking(), GetShapeName())
		else
			BoxSize = ACF.GetCrateSizeFromProjectileCounts(CountX, CountY, CountZ, Class, ToolData, BulletData, GetHexPacking())
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

---Creates the round cutaway panel on the ACF menu.
local function AddVisual(Base, ToolData)
	if Ammo.PreCreateAmmoVisual then
		local Result = Ammo:PreCreateAmmoVisual(Base, ToolData, BulletData)
		if not Result then return end
	end

	local Result = hook.Run("ACF_PreCreateAmmoVisual", Base, ToolData, Ammo, BulletData)
	if not Result then return end

	local Visual    = Base:AddVisualizer()
	Base.Visual     = Visual
	local MenuSizeX = Base:GetParent():GetParent():GetWide()
	Visual:SetSize(MenuSizeX, MenuSizeX * 0.3)

	local function Redraw()
		if not IsValid(Visual) then return end

		-- Each ammo type draws its own bullet; see CLASS:DrawAmmoVisual in the respective ammo_types file
		if Ammo.DrawAmmoVisual then
			Visual:SetDrawFunc(function(Panel, w, h)
				Ammo:DrawAmmoVisual(Panel, w, h, BuildToolData(), BulletData)
			end)
		else
			Visual:Clear()
		end
	end

	Redraw()
	AmmoCtx:OnChange(Visual, nil, Redraw)
	BindCleanup(Visual, AmmoCtx)

	if Ammo.OnCreateAmmoVisual then
		Ammo:OnCreateAmmoVisual(Base, ToolData, BulletData)
	end

	hook.Run("ACF_OnCreateAmmoVisual", Base, ToolData, Ammo, BulletData)
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
		Sub:Set("RoundLength", BulletData.RoundLength)
		Sub:Set("PropRatio", BulletData.PropRatio)
	end

	-- Two piece ammo stows the charge and projectile separately, so a cell holds half a round.
	local TwoPiece = Base:AddCheckBox(language.GetPhrase("acf.menu.ammo.two_piece"))
	TwoPiece:SetValue(Ammo.TwoPiece and true or false)

	function TwoPiece:OnChange(Value)
		if self._Suppress then return end

		Ammo.TwoPiece = Value
		Ammo:UpdateRoundData()

		Sub:Set("TwoPiece", Value)

		UpdateProjectileCountLimits(BuildToolData(), true)
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

	-- RoundLength and PropRatio are the stored round dimensions (see ACF.UpdateRoundSpecs);
	-- ProjLength/PropLength are derived from them. UpdateRoundSpecs clamps each against the other,
	-- so the sliders are independent and need no cross-pushback.
	local Bounds = Ammo.GUIData
	local Total  = Base:AddSlider("#acf.menu.ammo.total_length", Bounds.MinProjLength + Bounds.MinPropLength, Bounds.MaxRoundLength, 2)

	Total:SetValue(Ammo.RoundLength or BulletData.RoundLength)
	function Total:OnValueChanged(Value)
		if self._Suppress then return end

		Ammo.RoundLength = Value
		Ammo:UpdateRoundData()

		self._Suppress = true
		self:SetValue(BulletData.RoundLength)
		self._Suppress = false

		Sub:Set("RoundLength", BulletData.RoundLength)

		UpdateProjectileCountLimits(BuildToolData(), true)
	end

	local PropRatio = Base:AddSlider("#acf.menu.ammo.propellant_ratio", 0, 1, 3)

	PropRatio:SetValue(Ammo.PropRatio or BulletData.PropRatio)
	function PropRatio:OnValueChanged(Value)
		if self._Suppress then return end

		Ammo.PropRatio = Value
		Ammo:UpdateRoundData()

		self._Suppress = true
		self:SetValue(BulletData.PropRatio)
		self._Suppress = false

		Sub:Set("PropRatio", BulletData.PropRatio)

		UpdateProjectileCountLimits(BuildToolData(), true)
	end

	-- Classes allowing no necking cap at 1, leaving DNumSlider a degenerate min == max range
	local CaseScale = Base:AddSlider("#acf.menu.ammo.case_scale", 1, BulletData.MaxCaseScale or 1, 2)

	CaseScale:SetValue(Ammo.CaseScale or BulletData.CaseScale)
	function CaseScale:OnValueChanged(Value)
		if self._Suppress then return end

		Ammo.CaseScale = Value
		Ammo:UpdateRoundData()

		self._Suppress = true
		self:SetValue(BulletData.CaseScale)
		self._Suppress = false

		Sub:Set("CaseScale", BulletData.CaseScale)

		-- A wider case is a wider round, so the crate's projectile counts have to be refit
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
		local Rounds = GetRoundCount(GetCount("X"), GetCount("Y"), GetCount("Z"))

		-- CartMass is the mass of a whole round, so it multiplies complete rounds, not cells
		local Load = math.floor(BulletData.CartMass * Rounds)
		local Mass = ACF.FormatMass(math.floor(GetEmptyMass() + Load))
		local Cost = ACF.FormatCost(Rounds * GetRoundCost())

		return CrateText:format(Mass, Cost, Rounds)
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

		-- Each ammo type plots its own curve; see CLASS:PlotAmmoGraph in the respective ammo_types file.
		if GraphAmmo.PlotAmmoGraph then
			GraphAmmo:PlotAmmoGraph(Panel, Data, GraphBullet)
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
	AddVisual(Base, ToolData)
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

	local ShapeIDs = {Box = 1}

	for Key, Layout in pairs(ACF.DrumLayouts) do
		ShapeList:AddChoice(Layout.Name, Key)
		ShapeIDs[Key] = table.Count(ShapeIDs) + 1
	end
	Menu.AmmoShapeList = ShapeList
	ShapeList:ChooseOptionID(ShapeIDs[GetShapeName()] or 1)

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

	local HexPacking = ContainerBase:AddCheckBox(language.GetPhrase("acf.menu.ammo.hex_packing"))
	HexPacking:SetValue(GetHexPacking())

	function HexPacking:OnChange(Value)
		if self._Suppress then return end

		AmmoCtx:Set("HexPacking", Value)

		UpdateProjectileCountLimits(BuildToolData(), true)
	end

	function ShapeList:OnSelect(_, _, Data)
		AmmoCtx:Set("Shape", SHAPE_FQN[Data] or SHAPE_FQN.Box)

		local Layout = ACF.GetDrumLayout(Data)

		if Layout then
			CountX:SetVisible(true)
			CountX:SetText(Layout.PrimaryLabel)
			CountX:SetMin(Layout.MinPrimary)
			CountY:SetVisible(false)
			CountZ:SetText(Layout.SecondaryLabel)
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
