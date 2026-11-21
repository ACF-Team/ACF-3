local hook      = hook
local ACF       = ACF
local Classes   = ACF.Classes
local BoxSize   = Vector()

-- The crate keeps its drum/box UI logic keyed on a short shape string, but the entity's inherited
-- "Shape" field wants a ContainerShapes class FQN. This maps between them.
local SHAPE_FQN = {Box = "ACF.ContainerShapes.Box", Cassette = "ACF.ContainerShapes.Cassette"}
local FQN_SHAPE = {["ACF.ContainerShapes.Box"] = "Box", ["ACF.ContainerShapes.Cassette"] = "Cassette"}

for Key in pairs(ACF.DrumLayouts) do
	local FQN = "ACF.ContainerShapes." .. Key

	SHAPE_FQN[Key] = FQN
	FQN_SHAPE[FQN] = Key
end

-- Menu state. AmmoCtx is the acf_ammo EntityContext this menu edits; Sub wraps its nested "AmmoType"
-- field (the live ammo-type instance, which holds Projectile/Propellant/Tracer/... ). BulletData is the
-- converted round data, recomputed whenever the config changes.
-- AmmoType is always the selected row of the round list (the same instance), so everything below edits that row
local AmmoCtx, Sub, Ammo, BulletData
local RoundList, TypeList, MenuRoot
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

-- MARK: Round list helpers

local function GetRounds() return AmmoCtx:Get("Rounds") end
local function GetRoundCounts() return AmmoCtx:Get("RoundCounts") end

-- Rows whose count is locked. Not saved anywhere
local Locks = setmetatable({}, { __mode = "k" })

local function IsLocked(Round) return Locks[Round] == true end

---Points AmmoType at the selected row. Settings saved before the round list only have AmmoType, that becomes the list
local function Rebind()
	local Rounds = GetRounds()

	if not (Rounds and Rounds[1]) then
		AmmoCtx:Set("Rounds", { AmmoCtx:Get("AmmoType") }, true)
		AmmoCtx:Set("RoundCounts", { 1 }, true)

		Rounds = GetRounds()
	end

	local Counts = GetRoundCounts()

	for Index = 1, #Rounds do Counts[Index] = Counts[Index] or 1 end
	for Index = #Counts, #Rounds + 1, -1 do Counts[Index] = nil end

	local Selected = math.Clamp(AmmoCtx.RoundSelected or 1, 1, #Rounds)

	AmmoCtx.RoundSelected     = Selected
	AmmoCtx.Instance.AmmoType = Rounds[Selected]

	Sub  = ACF.Menu.SubContext(AmmoCtx, "AmmoType")
	Ammo = Rounds[Selected]

	Ammo.Weapon = AmmoCtx:Get("Weapon")
	BulletData  = Ammo:ClientConvert()
end

local ROW_FIELDS = { "KindName", "OverrideTracerColor", "TracerColor", "OverrideSmokeColor", "SmokeColor", "TwoPiece" }

local function GetRowFields(Round)
	local Fields = {}

	for _, Name in ipairs(ROW_FIELDS) do Fields[Name] = Round[Name] end

	return Fields
end

-- Picking another ammo type makes a new instance, it takes the row's place and keeps the row's name and color
local function SyncSelectedRound(Ctx)
	local Rounds  = Ctx:Get("Rounds")
	local Current = Ctx.Instance.AmmoType
	local Old     = Rounds and Rounds[Ctx.RoundSelected or 1]

	if not Old or Old == Current or not (Current and Current.GetType) then return end

	for Name, Value in pairs(GetRowFields(Old)) do
		if Classes.GetTypeFieldByName(Current:GetType(), Name) then Current[Name] = Value end
	end

	Locks[Current] = Locks[Old]

	Rounds[Ctx.RoundSelected or 1] = Current
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
	local Data = Ctx:Serialize()
	if not Data.Rounds then return end

	ACF.Menu.SetAmmoForWeapon(Scope, { Rounds = Data.Rounds, RoundCounts = Data.RoundCounts, Selected = Ctx.RoundSelected })
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
	if Saved and Saved.Rounds then
		-- Visited class: restore its remembered round list + tuned params (silent -- LoadEntries rebuilds
		-- the controls right after).
		AmmoCtx:Set("Rounds", Saved.Rounds, true)
		AmmoCtx:Set("RoundCounts", Saved.RoundCounts or {}, true)
		AmmoCtx.RoundSelected = Saved.Selected
	elseif Saved then
		-- Remembered before the round list, a single { Type, Data }
		AmmoCtx:Set("Rounds", { Saved }, true)
		AmmoCtx:Set("RoundCounts", { 1 }, true)
		AmmoCtx.RoundSelected = 1
	elseif not First then
		-- Unseen class after a switch: keep the ammo TYPES the user is on (e.g. HE -> HE), but drop the
		-- previous class's tuned params so each class starts from defaults and diverges independently.
		local Rows = {}

		for _, Round in ipairs(GetRounds() or {}) do
			Rows[#Rows + 1] = { Type = Classes.GetTypeName(Round:GetType()), Data = GetRowFields(Round) }
		end

		if Rows[1] then AmmoCtx:Set("Rounds", Rows, true) end
	end
	-- First open with no saved data keeps whatever the context hydrated; it's saved under this class on edit.

	Rebind()

	-- Rounds this weapon can't fire are dropped, as long as one is left
	local Allowed = GetAmmoList(WeaponType)
	local Rounds, Counts = GetRounds(), GetRoundCounts()
	local Kept, KeptCounts = {}, {}

	for Index, Round in ipairs(Rounds) do
		if Allowed[Classes.GetTypeName(Round:GetType())] then
			Kept[#Kept + 1], KeptCounts[#KeptCounts + 1] = Round, Counts[Index]
		end
	end

	if Kept[1] and #Kept < #Rounds then
		AmmoCtx:Set("Rounds", Kept, true)
		AmmoCtx:Set("RoundCounts", KeptCounts, true)
		AmmoCtx.RoundSelected = 1

		Rebind()
	end
end

--- Saves the crate's ammo under its current weapon class, then points it at another one
--- For copying a crate in, so the copied ammo isn't saved under the old weapon class
function ACF.AmmoMenu.SetScope(Ctx, WeaponType)
	local Scope = WeaponType and Classes.GetTypeName(WeaponType)
	if not Scope or Scope == Ctx.AmmoScope then return end

	if Ctx.AmmoScope then
		if timer.Exists(SaveTimer) then timer.Remove(SaveTimer) end
		SaveScopedAmmo(Ctx, Ctx.AmmoScope)
	end

	Ctx.AmmoScope = Scope
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

local function IsCassette()
	return ACF.IsCassetteShape(GetShapeName())
end

local function CanHexPack(Name)
	local Shape = Classes.GetTypeByName(SHAPE_FQN[Name] or SHAPE_FQN.Box)

	return Shape and Shape.CanHexPack or false
end

local function GetHexPacking()
	return AmmoCtx and AmmoCtx:Get("HexPacking") and CanHexPack(GetShapeName()) or false
end

---Complete rounds held by the given cell counts, the same figure the server uses.
local function GetRoundCount(CountX, CountY, CountZ)
	return ACF.GetCrateCapacity(GetShapeName(), CountX, CountY, CountZ, BulletData and BulletData.TwoPiece)
end

local function GetCapacity()
	return GetRoundCount(GetCount("X"), GetCount("Y"), GetCount("Z"))
end

-- The weapon can't fire these, they're left out of the crate
local function GetInvalidReason(Round)
	local Weapon = AmmoCtx:Get("Weapon")

	if not (Weapon and Weapon.GetType) then return end
	if GetAmmoList(Weapon:GetType())[Classes.GetTypeName(Round:GetType())] then return end

	return "This weapon can't fire " .. (Round.Name or "this round") .. ", it's left out of the crate."
end

-- Locked weights are exact counts, the rest scale to fill what's left
local function FitLockedCounts(Weights, Locked, Capacity)
	local Free, FreeWeights, Taken = {}, {}, 0

	for Position, Weight in ipairs(Weights) do
		if Locked[Position] then
			Taken = Taken + math.max(1, math.floor(Weight))
		else
			Free[#Free + 1]               = Position
			FreeWeights[#FreeWeights + 1] = Weight
		end
	end

	-- Nothing to scale, or the locked ones don't fit anymore
	if not Free[1] or Taken + #Free > Capacity then return ACF.FitRoundCounts(Weights, Capacity) end

	local Fitted = {}

	for Position, Weight in ipairs(Weights) do
		if Locked[Position] then Fitted[Position] = math.max(1, math.floor(Weight)) end
	end

	for Slot, Count in ipairs(ACF.FitRoundCounts(FreeWeights, Capacity - Taken)) do Fitted[Free[Slot]] = Count end

	return Fitted
end

---Each row's round count once fitted to the crate, 0 for rows left out
local function GetFittedCounts()
	local Rounds, Counts = GetRounds(), GetRoundCounts()
	local Valid, Weights, Locked = {}, {}, {}

	for Index, Round in ipairs(Rounds) do
		if not GetInvalidReason(Round) then
			Valid[#Valid + 1]     = Index
			Weights[#Weights + 1] = Counts[Index] or 1
			Locked[#Locked + 1]   = IsLocked(Round)
		end
	end

	local Fitted = {}

	for Index in ipairs(Rounds) do Fitted[Index] = 0 end
	for Position, Count in ipairs(FitLockedCounts(Weights, Locked, GetCapacity())) do Fitted[Valid[Position]] = Count end

	return Fitted, Valid
end

---Converted round data of a row, the selected row's is the one the menu keeps up to date
local function GetRowBullet(Round)
	if Round == Ammo then return BulletData end

	Round.Weapon = AmmoCtx:Get("Weapon")

	return Round:ClientConvert()
end

---The round the crate's slots are sized for, the longest and widest of the rows the crate holds
local function GetSlotBullet()
	local List = {}

	for _, Round in ipairs(GetRounds() or {}) do
		if not GetInvalidReason(Round) then List[#List + 1] = GetRowBullet(Round) end
	end

	return List[1] and ACF.GetSlotBulletData(List) or BulletData
end

-- Named the way the crate will name them, only the rows it holds count
local function GetAutoNames(Rounds, Fitted)
	local Names, Held, CustomNames, AutoNames = {}, {}, {}, {}

	for Index, Round in ipairs(Rounds) do
		Names[Index] = ACF.GetLegacyStyleClassName(Classes.GetTypeName(Round:GetType())) .. (Round.Tracer and "-T" or "")

		if Fitted[Index] > 0 then
			Held[#Held + 1]               = Index
			CustomNames[#CustomNames + 1] = Round.KindName
			AutoNames[#AutoNames + 1]     = Names[Index]
		end
	end

	for Position, Name in ipairs(ACF.NameRoundKinds(CustomNames, AutoNames)) do Names[Held[Position]] = Name end

	return Names
end

-- Rows as the round list shows them
local function GetListKinds()
	local Rounds    = GetRounds()
	local Fitted    = GetFittedCounts()
	local AutoNames = GetAutoNames(Rounds, Fitted)
	local Kinds     = {}

	for Index, Round in ipairs(Rounds) do
		Kinds[Index] = {
			Name                = Round.KindName or "",
			AutoName            = AutoNames[Index],
			Icon                = Round.SpawnIcon or "",
			Count               = Fitted[Index],
			OverrideTracerColor = Round.OverrideTracerColor,
			TracerColor         = Round.TracerColor,
			HasSmoke            = ACF.HasSmokeColor(Round:GetType()),
			OverrideSmokeColor  = Round.OverrideSmokeColor,
			SmokeColor          = Round.SmokeColor,
			Invalid             = GetInvalidReason(Round),
			Locked              = IsLocked(Round),
		}
	end

	return Kinds
end

---Returns the cost of a single round, including any per-round missile components.
local function GetRoundCost(Round, RoundBullet)
	local Cost = (Round or Ammo):GetCost(RoundBullet or BulletData)

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

	local roundSize = ACF.GetCrateSizeFromProjectileCounts(1, 1, 1, Class, ToolData, GetSlotBullet(), GetHexPacking())
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

	local MinX, MinZ = 1, 1
	local MaxX, MaxY, MaxZ

	local Layout = ACF.GetDrumLayout(GetShapeName())

	if Layout then
		local Class     = GetWeaponClass(ToolData)
		local roundSize = Class and BulletData and ACF.GetRoundProperties(Class, ToolData, GetSlotBullet())

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
	elseif IsCassette() then
		local _, GridY, GridZ = CalculateMaxCounts(ToolData)

		MaxX, MaxY, MaxZ = ACF.GetCassetteMaxCounts(CurrentX, GridY, GridZ)
	else
		MaxX, MaxY, MaxZ = CalculateMaxCounts(ToolData)
	end

	-- two piece rounds need a charge and a projectile layer
	if BulletData and BulletData.TwoPiece and not IsCassette() then MinZ = math.min(2, MaxZ) end

	CountSliders.X:SetMin(MinX)
	CountSliders.X:SetMax(MaxX)
	CountSliders.Y:SetMax(MaxY)
	CountSliders.Z:SetMin(MinZ)
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
	if CurrentZ < MinZ then
		CountSliders.Z:SetValue(MinZ)
		AmmoCtx:Set("CrateProjectilesZ", MinZ)
	elseif CurrentZ > MaxZ then
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
		local Slot = GetSlotBullet()

		if IsDrum() then
			BoxSize = ACF.GetDrumCrateSizeFromProjectileCounts(CountX, CountZ, Class, ToolData, Slot, GetHexPacking(), GetShapeName())
		elseif IsCassette() then
			local Grid = ACF.GetCassetteGrid(CountX, CountY, CountZ, BulletData.TwoPiece)

			BoxSize = ACF.GetCrateSizeFromProjectileCounts(Grid.x, Grid.y, Grid.z, Class, ToolData, Slot, false)
		else
			BoxSize = ACF.GetCrateSizeFromProjectileCounts(CountX, CountY, CountZ, Class, ToolData, Slot, GetHexPacking())
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

		-- One setting for the whole crate
		for _, Round in ipairs(GetRounds()) do
			if Round ~= Ammo and Classes.GetTypeFieldByName(Round:GetType(), "TwoPiece") then Round.TwoPiece = Value end
		end

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
		-- Not ProjLength + PropLength, those overlap on telescoped rounds
		return Text:format(math.Round(BulletData.RoundLength, 2), Ammo.GUIData.MaxRoundLength)
	end
	RoundLength:SetText(UpdateRoundLength())
	AmmoCtx:OnChange(RoundLength, nil, function() if IsValid(RoundLength) then RoundLength:SetText(UpdateRoundLength()) end end)
	BindCleanup(RoundLength, AmmoCtx)

	-- RoundLength and PropellantScale are stored, so the sliders need no cross pushback
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

	-- 0 to 1 over the propellant this length allows
	local PropScale = Base:AddSlider("#acf.menu.ammo.propellant_ratio", 0, 1, 3)

	PropScale:SetValue(Ammo.PropellantScale or 0)
	function PropScale:OnValueChanged(Value)
		Ammo.PropellantScale = Value
		Ammo:UpdateRoundData()

		Sub:Set("PropellantScale", Value)
		Sub:Set("PropRatio", BulletData.PropRatio)

		UpdateProjectileCountLimits(BuildToolData(), true)
	end

	-- 0 to 1 up to the class's widest case
	local CaseScale = Base:AddSlider("#acf.menu.ammo.case_scale", 0, 1, 2)

	CaseScale:SetValue(Ammo.NeckingScale or 0)
	function CaseScale:OnValueChanged(Value)
		Ammo.NeckingScale = Value
		Ammo:UpdateRoundData()

		Sub:Set("NeckingScale", Value)
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
		local Rounds    = GetCapacity()
		local Fitted    = GetFittedCounts()
		local Load, Cost = 0, 0

		-- CartMass is the mass of a whole round, so it multiplies complete rounds, not cells
		for Index, Round in ipairs(GetRounds()) do
			local Count = Fitted[Index]

			if Count > 0 then
				local RoundBullet = GetRowBullet(Round)

				Load = Load + RoundBullet.CartMass * Count
				Cost = Cost + GetRoundCost(Round, RoundBullet) * Count
			end
		end

		local Mass = ACF.FormatMass(math.floor(GetEmptyMass() + math.floor(Load)))

		return CrateText:format(Mass, ACF.FormatCost(Cost), Rounds)
	end

	Crate:SetText(UpdateCrateText())
	AmmoCtx:OnChange(Crate, nil, function() if IsValid(Crate) then Crate:SetText(UpdateCrateText()) end end)
	BindCleanup(Crate, AmmoCtx)

	if Ammo.OnCreateCrateInformation then
		Ammo:OnCreateCrateInformation(Base, Crate, ToolData, BulletData)
	end

	hook.Run("ACF_OnCreateCrateInformation", Base, Crate, ToolData, Ammo, BulletData)
end

-- CLASS:GetKineticEnergyData lets each ammo type say what mass/speed its energy is actually carried by
-- (e.g. HEAT's jet instead of the shell), so this doesn't need per-type duplication in the menu.
local function AddKineticEnergyInformation(Base)
	local KineticLabel = Base:AddLabel()
	ACF.AmmoMenu.Reactive(KineticLabel, function()
		local Text = language.GetPhrase("acf.menu.ammo.kinetic_energy_stats")
		local Mass, Vel = Ammo:GetKineticEnergyData(BulletData)

		-- Stored in m/s, but ACF.Kinetic expects in/s and converts back internally
		local Speed   = Vel * ACF.MeterToInch
		local Kinetic = math.Round(ACF.Kinetic(Speed, Mass).Kinetic)

		KineticLabel:SetText(Text:format(Kinetic))
	end)
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

	AddKineticEnergyInformation(Base)

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

---Updates the shape selector visibility. Every shape is available to every weapon type.
local function UpdateShapeSelector(Menu)
	local ShapeList = Menu.AmmoShapeList
	if not ShapeList then return end

	ShapeList:SetVisible(true)
end

-- MARK: Round list

-- The rows are live instances AmmoType points at, so a deep copy would lose them
local function CopyList(List)
	local Copy = {}

	for Index, Value in ipairs(List) do Copy[Index] = Value end

	return Copy
end

local function RefreshRoundList()
	if not IsValid(RoundList) then return end

	RoundList:SetCanAdd(AmmoCtx.Destiny ~= "Missiles") -- Missile crates hold one kind of round
	RoundList:SetCapacity(GetCapacity())
	RoundList:SetSelected(AmmoCtx.RoundSelected or 1)
	RoundList:SetKinds(GetListKinds())
end

-- Shows the selected row in the type combo and the controls below it
local function ShowSelectedRound(Menu)
	if not IsValid(TypeList) then return end

	local Choices = TypeList.ListData and TypeList.ListData.Choices
	local Want    = Classes.GetTypeName(Ammo:GetType())

	for Index, Data in ipairs(Choices or {}) do
		if Classes.GetTypeName(Data) == Want then
			TypeList.Selected = nil
			TypeList:ChooseOptionID(Index)

			return
		end
	end

	-- The weapon can't fire it, so it isn't in the combo
	TypeList.Selected = Ammo:GetType()
	TypeList:SetValue(Ammo.Name or Want)

	ACF.UpdateAmmoMenu(Menu)
end

-- Stores a new list of rows, the counts are weights the crate scales to fit
local function SetRows(Menu, Rounds, Counts, Selected)
	AmmoCtx.RoundSelected = Selected

	AmmoCtx:Set("Rounds", Rounds, true)
	AmmoCtx:Set("RoundCounts", Counts, true)

	Rebind()
	ShowSelectedRound(Menu)

	AmmoCtx:Set("RoundCounts", GetRoundCounts()) -- Now everything listening sees the new list
end

-- Counts as the list shows them, rows left out of the crate keep their weight
local function MergeCounts(Shown)
	local Counts = CopyList(GetRoundCounts())

	for Index, Round in ipairs(GetRounds()) do
		if not GetInvalidReason(Round) then Counts[Index] = Shown[Index] end
	end

	return Counts
end

-- Up to Wanted rounds for a new row out of the unlocked rows, in their proportions. Nil when they can't spare any
local function TakeFromUnlocked(Rounds, Counts, Wanted)
	local Rows, Shown, Pool = {}, {}, 0

	for Index, Round in ipairs(Rounds) do
		if not IsLocked(Round) and not GetInvalidReason(Round) then
			Rows[#Rows + 1]   = Index
			Shown[#Shown + 1] = Counts[Index]
			Pool              = Pool + Counts[Index]
		end
	end

	if Pool <= #Rows then return end

	Shown[#Shown + 1] = 0

	local Split = ACF.SetRoundCount(Shown, #Shown, math.min(Wanted, Pool - #Rows), Pool)

	for Slot, Row in ipairs(Rows) do Counts[Row] = Split[Slot] end

	return Split[#Split]
end

local function SetupRoundList(Menu, Panel)
	local Serialization = Classes.Serialization

	function Panel:OnSelectRound(Index)
		AmmoCtx.RoundSelected = Index

		Rebind()
		ShowSelectedRound(Menu)
		RefreshRoundList()
	end

	-- A copy of the row goes under it and takes half its rounds
	function Panel:OnAddRound(DupeOf)
		local Rounds = CopyList(GetRounds())

		if #Rounds >= ACF.MaxRoundKinds then return end

		local Source = Rounds[DupeOf] or Ammo
		local Type   = Source:GetType()
		local Copy   = Serialization.DeserializePartial(Type, Serialization.Serialize(Type, Source))
		local Counts = MergeCounts(GetFittedCounts())
		local Own    = Counts[DupeOf] or 2
		local Half   = math.max(1, math.floor(Own * 0.5))

		-- Locked, so the unlocked rows pay for the copy instead
		local Taken = IsLocked(Source) and not GetInvalidReason(Source) and TakeFromUnlocked(Rounds, Counts, Half)

		if not Taken then
			Counts[DupeOf] = math.max(1, Own - Half)
			Taken          = Half
		end

		Copy.KindName = ""

		table.insert(Rounds, DupeOf + 1, Copy)
		table.insert(Counts, DupeOf + 1, Taken)

		SetRows(Menu, Rounds, Counts, DupeOf + 1)
	end

	function Panel:OnRemoveRound(Index)
		local Rounds, Counts = CopyList(GetRounds()), CopyList(GetRoundCounts())

		if #Rounds < 2 then return end

		table.remove(Rounds, Index)
		table.remove(Counts, Index)

		local Selected = AmmoCtx.RoundSelected or 1

		if Selected > Index or Selected == Index and Selected > #Rounds then Selected = Selected - 1 end

		SetRows(Menu, Rounds, Counts, math.max(Selected, 1))
	end

	function Panel:OnMoveRound(Index, Step)
		local Rounds, Counts = CopyList(GetRounds()), CopyList(GetRoundCounts())
		local Other          = Index + Step

		if not Rounds[Other] then return end

		Rounds[Index], Rounds[Other] = Rounds[Other], Rounds[Index]
		Counts[Index], Counts[Other] = Counts[Other], Counts[Index]

		local Selected = AmmoCtx.RoundSelected or 1

		if Selected == Index then Selected = Other elseif Selected == Other then Selected = Index end

		SetRows(Menu, Rounds, Counts, Selected)
	end

	-- The typed row gets exactly that many, the unlocked others share the rest
	function Panel:OnCountTyped(Index, Value)
		local Fitted, Valid = GetFittedCounts()
		local Rounds        = GetRounds()
		local Capacity      = GetCapacity()
		local Rows, Shown, Position = {}, {}, nil

		for _, Row in ipairs(Valid) do
			if Row == Index or not IsLocked(Rounds[Row]) then
				Rows[#Rows + 1]   = Row
				Shown[#Shown + 1] = Fitted[Row]

				if Row == Index then Position = #Rows end
			else
				Capacity = Capacity - Fitted[Row]
			end
		end

		if not Position then return end

		local Counts = CopyList(GetRoundCounts())

		for Slot, Count in ipairs(ACF.SetRoundCount(Shown, Position, Value, Capacity)) do
			Counts[Rows[Slot]] = Count
		end

		AmmoCtx:Set("RoundCounts", Counts)
	end

	-- Counts go exact first so the locked row keeps the number it shows
	function Panel:OnLockRound(Index, Locked)
		local Round = GetRounds()[Index]

		if not Round then return end

		local Counts = MergeCounts(GetFittedCounts())

		Locks[Round] = Locked or nil

		AmmoCtx:Set("RoundCounts", Counts)
		RefreshRoundList()
	end

	function Panel:OnCountsChanged(Shown)
		AmmoCtx:Set("RoundCounts", MergeCounts(Shown))
	end

	-- Names and colors don't change anything else the menu shows
	function Panel:OnRename(Index, Name)
		local Round = GetRounds()[Index]

		if not Round then return end

		Round.KindName = Name

		ACF.Menu.QueuePersist(AmmoCtx)
		QueueScopedSave()
		RefreshRoundList()
	end

	function Panel:OnColor(Index, Which, Override, Packed)
		local Round = GetRounds()[Index]

		if not Round then return end
		if not ACF.HasKindColor(Round:GetType(), Which) then return end

		Round["Override" .. Which .. "Color"] = Override
		Round[Which .. "Color"]               = Packed

		ACF.Menu.QueuePersist(AmmoCtx)
		QueueScopedSave()
		RefreshRoundList()
	end

	AmmoCtx:OnChange(Panel, nil, RefreshRoundList)
	BindCleanup(Panel, AmmoCtx)
end

-- Settings loaded over the context (Hydrate) bring their own rows and AmmoType, so AmmoType has to point at the selected row again
local function RepairSelectedRound(Ctx)
	local Rounds = Ctx:Get("Rounds")

	if Ctx ~= AmmoCtx or not (Rounds and Rounds[1]) then return end
	if Ctx.Instance.AmmoType == Rounds[Ctx.RoundSelected or 1] then return end

	Rebind()
	ShowSelectedRound(MenuRoot)
	RefreshRoundList()
end

--- Sends the crate with only the rows it can hold, counted to fill it. AmmoType is the first row
function ACF.AmmoMenu.SendCrate(ClassName, Data)
	if AmmoCtx and istable(Data.Rounds) then
		local Fitted = GetFittedCounts()
		local Rounds, Counts = {}, {}

		for Index in ipairs(GetRounds()) do
			if Fitted[Index] > 0 and Data.Rounds[Index] then
				Rounds[#Rounds + 1] = Data.Rounds[Index]
				Counts[#Counts + 1] = Fitted[Index]
			end
		end

		if Rounds[1] then
			Data.Rounds      = Rounds
			Data.RoundCounts = Counts
			Data.AmmoType    = table.Copy(Rounds[1])
		end
	end

	ACF.Menu.SendSpawn(ClassName, Data)
end

---Creates the basic information and panels on the ammunition menu.
---@param Menu userdata The panel in which the entire ACF menu is being placed on.
---@param Context table The acf_ammo EntityContext this menu edits.
function ACF.CreateAmmoMenu(Menu, Context)
	AmmoCtx  = Context
	MenuRoot = Menu

	Rebind()

	-- Mirror the round list + its params into the active weapon class's memory whenever they change.
	AmmoCtx:OnChange("ScopedAmmoSave", "AmmoType", QueueScopedSave)
	AmmoCtx:OnChange("ScopedAmmoSave", "Rounds", QueueScopedSave)
	AmmoCtx:OnChange("ScopedAmmoSave", "RoundCounts", QueueScopedSave)
	AmmoCtx:OnChange("RoundRepair", RepairSelectedRound)

	local ContainerBase = Menu:AddCollapsible("Container Settings", true, "icon16/box.png")

	local ShapeList = ContainerBase:AddComboBox()
	ShapeList:AddChoice("Crate", "Box")

	local ShapeIDs = {Box = 1}

	do
		-- Sorted so the drum shapes always land in the same slots, pairs order isn't stable
		local Keys = {}
		for Key in pairs(ACF.DrumLayouts) do Keys[#Keys + 1] = Key end
		table.sort(Keys)

		for Index, Key in ipairs(Keys) do
			ShapeList:AddChoice(ACF.DrumLayouts[Key].Name, Key)
			ShapeIDs[Key] = Index + 1 -- "Crate" occupies slot 1
		end
	end

	ShapeList:AddChoice("Cassette", "Cassette")
	ShapeIDs.Cassette = table.Count(ShapeIDs) + 1
	Menu.AmmoShapeList = ShapeList
	ShapeList:ChooseOptionID(ShapeIDs[GetShapeName()] or 1)

	local CountXLabel = "#acf.menu.ammo.projectiles_length"
	local CountYLabel = "#acf.menu.ammo.projectiles_width"
	local CountZLabel = "#acf.menu.ammo.projectiles_height"

	local CassetteXLabel = "Projectiles (Stacks)"
	local CassetteYLabel = "Conveyor Width"
	local CassetteZLabel = "Conveyor Height"

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
	HexPacking:SetValue(AmmoCtx:Get("HexPacking") or false)

	function HexPacking:OnChange(Value)
		if self._Suppress then return end

		AmmoCtx:Set("HexPacking", Value)

		UpdateProjectileCountLimits(BuildToolData(), true)
	end

	-- Labels and shows the count sliders and hex packing for a shape
	local function ShowShapeCounts(Data)
		local Layout = ACF.GetDrumLayout(Data)

		HexPacking:SetVisible(CanHexPack(Data))

		if Layout then
			CountX:SetVisible(true)
			CountX:SetText(Layout.PrimaryLabel)
			CountX:SetMin(Layout.MinPrimary)
			CountY:SetVisible(false)
			CountZ:SetText(Layout.SecondaryLabel)
		elseif ACF.IsCassetteShape(Data) then
			CountX:SetVisible(true)
			CountX:SetText(CassetteXLabel)
			CountX:SetMin(1)
			CountY:SetVisible(true)
			CountY:SetText(CassetteYLabel)
			CountZ:SetText(CassetteZLabel)
		else
			CountX:SetVisible(true)
			CountX:SetText(language.GetPhrase(CountXLabel))
			CountX:SetMin(1)
			CountY:SetVisible(true)
			CountY:SetText(language.GetPhrase(CountYLabel))
			CountZ:SetText(language.GetPhrase(CountZLabel))
		end
	end

	function ShapeList:OnSelect(_, _, Data)
		AmmoCtx:Set("Shape", SHAPE_FQN[Data] or SHAPE_FQN.Box)
		ShowShapeCounts(Data)
		UpdateProjectileCountLimits(BuildToolData())
	end

	ShowShapeCounts(GetShapeName())

	local Capacity = ContainerBase:AddLabel("")
	local function CapText()
		local RoundCount = GetRoundCount(GetCount("X"), GetCount("Y"), GetCount("Z"))
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

	-- Listed per weapon class. Presets leave the crate's size alone, and gun crates keep the menu's caliber
	local CrateFields = { "Shape", "CrateProjectilesX", "CrateProjectilesY", "CrateProjectilesZ", "HexPacking" }
	local GunFields   = { "Weapon", unpack(CrateFields) }

	local Presets = Base:AddPresets(Context, {
		Group = function() return Context.AmmoScope end,
		Keep  = function() return Context.Destiny == "Missiles" and CrateFields or GunFields end,
	})

	RoundList = Base:AddPanel("ACF_RoundList")

	SetupRoundList(Menu, RoundList)

	local List  = Base:AddComboBox()
	TypeList    = List
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
		Presets:Refresh()

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
		RefreshRoundList()
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
			AmmoCtx:Set("AmmoType", { Type = Classes.GetTypeName(Data), Data = {} }, true)

			SyncSelectedRound(AmmoCtx)

			AmmoCtx:Set("Rounds", GetRounds()) -- Now everything listening sees the new round
		end

		Sub  = ACF.Menu.SubContext(AmmoCtx, "AmmoType")
		Ammo = AmmoCtx:Get("AmmoType")

		Title:SetText(UpdateTitle())
		Desc:SetText(Data.Description)

		ACF.UpdateAmmoMenu(Menu)
		RefreshRoundList()
	end

	Menu.AmmoBase = Base

	return List
end
