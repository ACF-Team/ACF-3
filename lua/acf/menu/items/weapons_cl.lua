local ACF       = ACF
local Classes   = ACF.Classes
local PAGE      = "acf_gun"

local Current = {}
local IsScalable
local CreateControl

-- Per-weapon-class caliber memory (pairs with the per-class ammo memory): each class keeps the caliber
-- its ammo was tuned at, so switching classes restores a coherent caliber + ammo pair instead of dragging
-- one caliber across every class. Non-scalable classes don't need it -- their caliber comes from the
-- selected variant, which the weaponopt combo already persists.
local CaliberTimer = "acf_menu_weapon_caliber_save"

local function CaliberKey(Class)
	return "caliber." .. Classes.GetTypeName(Class:GetType())
end

local function SaveCaliber(Class, Caliber)
	if Class and Caliber then ACF.Menu.SetUIState(PAGE, CaliberKey(Class), Caliber) end
end

-- Debounced (reads the latest Current.* at fire time) so dragging the caliber slider doesn't hammer disk.
local function QueueCaliberSave()
	if timer.Exists(CaliberTimer) then return end
	timer.Create(CaliberTimer, 0.5, 1, function()
		SaveCaliber(Current.Class, Current.Caliber)
	end)
end

-- Non-scalable weapons expose selectable variants as IsWeaponOption subtypes.
local OptionCache = {}
local function GetWeaponOptions(Class)
	local Cached = OptionCache[Class]
	if Cached then return Cached end

	local Options = {}
	for _, Child in pairs(Classes.GetSubtypes(Classes.GetTypeName(Class))) do
		if Child.IsWeaponOption then Options[#Options + 1] = Child end
	end

	OptionCache[Class] = Options
	return Options
end

-- Writes the selected weapon type + caliber into both the gun and ammo contexts (as nested Weapon
-- instances), then refreshes the ammo sub-menu's round math.
local function ApplyWeapon(Menu, Gun, Ammo, FQN, Caliber)
	Gun:Set("Weapon",  { Type = FQN, Data = { Caliber = Caliber } })
	Ammo:Set("Weapon", { Type = FQN, Data = { Caliber = Caliber } })

	ACF.UpdateAmmoMenu(Menu)
end

local function UpdatePreview(Base, Data)
	local Preview = Base.Preview
	local Class   = Current.Class

	Preview:UpdateModel(Data.Model)
	Preview:UpdateSettings(Data.Preview)

	local Scale = Current.Weapon and 1 or (Current.Caliber / Class.CaliberLimits.Base * (Class.ScaleFactor or 1))
	Preview:SetModelScale(Scale, true)
end

local function UpdateControl(Base)
	local Control = Either(IsScalable, Base.Slider, Base.List)
	local Class   = Current.Class

	if not IsValid(Control) then CreateControl(Base) end

	if IsScalable then
		local Bounds  = Class.CaliberLimits
		local Stored  = Current.Caliber or Bounds.Base
		local Caliber = math.Clamp(Stored, Bounds.Min, Bounds.Max)

		Current.Caliber = Caliber
		Current.Weapon  = nil

		Base.Slider:SetMinMax(Bounds.Min, Bounds.Max)
		Base.Slider:SetValue(Caliber)

		ApplyWeapon(Base.Menu, Base.Gun, Base.Ammo, Classes.GetTypeName(Class:GetType()), Caliber)
		UpdatePreview(Base, Class)
	else
		ACF.Menu.LoadClassCombo(Base.List, GetWeaponOptions(Class), "Caliber", nil, PAGE, "weaponopt")
	end
end

CreateControl = function(Base)
	local Previous = Either(IsScalable, Base.List, Base.Slider)
	local Title    = Base.Title

	if IsValid(Previous) then Previous:Remove() end

	if IsScalable then
		local Bounds = Current.Class.CaliberLimits
		local Slider = Base:AddSlider("#acf.menu.caliber", Bounds.Min, Bounds.Max, 2)

		function Slider:OnValueChanged(Value)
			if self._Suppress then return end

			local Caliber = math.Round(Value, 2)
			self._Suppress = true
			self:SetValue(Caliber)
			self._Suppress = false

			Title:SetText(language.GetPhrase("acf.menu.weapons.name_text"):format(Caliber, Current.Class.Name))
			Current.Caliber = Caliber
			Current.Weapon  = nil

			ApplyWeapon(Base.Menu, Base.Gun, Base.Ammo, Classes.GetTypeName(Current.Class:GetType()), Caliber)
			UpdatePreview(Base, Current.Class)
			QueueCaliberSave()
		end

		Base.Slider = Slider
	else
		local List = Base:AddComboBox()

		function List:OnSelect(Index, _, Data)
			if self.Selected == Data then return end
			self.ListData.Index = Index
			self.Selected = Data
			ACF.Menu.SaveClassCombo(PAGE, "weaponopt", Data)

			Current.Weapon  = Data
			Current.Caliber = Data.Caliber

			Title:SetText(Data.Name)

			ApplyWeapon(Base.Menu, Base.Gun, Base.Ammo, Classes.GetTypeName(Data:GetType()), Data.Caliber)
			UpdatePreview(Base, Data)
		end

		Base.List = List
	end

	UpdateControl(Base)
end

local function UpdateMode(Base, Class)
	local Mode = tobool(Class.IsScalable)

	if Mode ~= IsScalable then
		IsScalable = Mode
		CreateControl(Base)
	else
		UpdateControl(Base)
	end
end

local function GetReloadTime(Caliber, Class, Weapon)
	local BulletData = ACF.GetCurrentAmmoData()
	if not BulletData then return 60 end
	return ACF.CalcReloadTime(Caliber, Class, Weapon, BulletData)
end

local function GetMagazineText(Caliber, Class, Weapon)
	local MagSize = ACF.GetWeaponValue("MagSize", Caliber, Class, Weapon)
	if not MagSize then return "" end

	local BulletData = ACF.GetCurrentAmmoData()
	if not BulletData then return "" end

	local MagText   = language.GetPhrase("acf.menu.weapons.mag_stats")
	local MagReload = ACF.CalcReloadTimeMag(Caliber, Class, Weapon, BulletData)

	return MagText:format(math.floor(MagSize), math.Round(MagReload, 2))
end

local function GetMass(Caliber, Class, Weapon)
	if Weapon then return Weapon.Mass or 0 end

	local Factor = Caliber / Class.CaliberLimits.Base

	return math.Round((Class.Mass or 0) * Factor ^ 3) -- 3d space so scaling has a cubing effect
end

---Returns the point cost of a weapon, mirroring acf_gun's GetCost.
local function GetCost(Caliber, Class)
	return (Class.CostScalar or 1) * Caliber
end

local function Build(Menu, Contexts)
	local Gun  = Contexts.Gun
	local Ammo = Contexts.Ammo

	-- Restore the last caliber (persisted in the gun context's Weapon field) so the scalable slider
	-- reopens where the user left it instead of snapping to the class base.
	local SavedWeapon = Gun:Get("Weapon")
	if SavedWeapon and SavedWeapon.Caliber then
		Current.Caliber = Current.Caliber or SavedWeapon.Caliber
	end

	local Subtypes = Classes.GetSubtypes("ACF.Guns.BaseGun")
	local Entries  = {}
	for ID, Type in pairs(Subtypes) do
		if Type.IsWeapon and not Type.IsWeaponOption then Entries[ID] = Type end
	end

	Menu:AddTitle("#acf.menu.weapons.settings")
	Menu:AddWikiLink("Weapons", "docs/acf_tutorials/weapons.html")

	local WeaponBase = Menu:AddCollapsible("#acf.menu.weapons.weapon_info", true, "icon16/monitor_edit.png")

	local ClassList   = WeaponBase:AddComboBox()
	local ClassBase   = WeaponBase:AddPanel("ACF_Panel")
	local EntName     = WeaponBase:AddTitle()
	local ClassDesc   = WeaponBase:AddLabel()
	local EntPreview  = WeaponBase:AddModelPreview(nil, true, "Primary")
	local EntData     = WeaponBase:AddLabel()
	local BreechIndex = WeaponBase:AddComboBox()

	local AmmoList = ACF.CreateAmmoMenu(Menu, Ammo)

	ClassBase.Menu    = Menu
	ClassBase.Gun     = Gun
	ClassBase.Ammo    = Ammo
	ClassBase.Title   = EntName
	ClassBase.Preview = EntPreview

	function ClassList:OnSelect(Index, _, Data)
		if self.Selected == Data then return end
		self.ListData.Index = Index
		self.Selected = Data
		ACF.Menu.SaveClassCombo(PAGE, "class", Data)

		-- Remember the outgoing class's caliber, then adopt the incoming class's (falling back to the
		-- carried caliber for a class not configured before, mirroring the per-class ammo memory).
		if Current.Class then
			if timer.Exists(CaliberTimer) then timer.Remove(CaliberTimer) end
			SaveCaliber(Current.Class, Current.Caliber)
		end

		Current.Class   = Data
		Current.Caliber = ACF.Menu.GetUIState(PAGE, CaliberKey(Data)) or Current.Caliber

		UpdateMode(ClassBase, Data)

		ClassDesc:SetText(Data.Description)

		AmmoList:LoadEntries(Data:GetType())

		BreechIndex:Clear()
		if Data.BreechConfigs then
			for Idx, Config in ipairs(Data.BreechConfigs.Locations) do
				BreechIndex:AddChoice("Loaded At: " .. Config.Name, Idx)
			end

			BreechIndex:SetVisible(true)
			function BreechIndex:OnSelect(_, _, Value)
				Gun:Set("BreechIndex", Value)
			end
			BreechIndex:ChooseOptionID(Data.BreechIndex or 1)
		else
			BreechIndex:SetVisible(false)
			Gun:Set("BreechIndex", 1)
		end
	end

	-- Reactive weapon stats (mass / fire rate / spread / magazine), refreshed on any ammo change.
	local function UpdateStats()
		local Class = Current.Class
		if not Class then return "" end

		local Caliber = Current.Caliber
		if not Caliber then return "" end

		local Weapon   = Current.Weapon
		local Mass     = ACF.FormatMass(GetMass(Caliber, Class, Weapon))
		local Cost     = ACF.FormatCost(GetCost(Caliber, Class))
		local FireDelay = GetReloadTime(Caliber, Class, Weapon)
		local FireRate = 60 / FireDelay
		local Spread   = ACF.GetWeaponValue("Spread", Caliber, Class, Weapon)
		local Magazine = GetMagazineText(Caliber, Class, Weapon)

		return language.GetPhrase("acf.menu.weapons.weapon_stats"):format(Mass, Cost, math.Round(FireRate), math.Round(FireDelay, 3), Spread, Magazine)
	end
	local function RefreshStats() if IsValid(EntData) then EntData:SetText(UpdateStats()) end end
	Ammo:OnChange(EntData, nil, RefreshStats)
	ClassBase.RefreshStats = RefreshStats

	ACF.Menu.LoadClassCombo(ClassList, Entries, "Name", "Model", PAGE, "class")
	RefreshStats()
end

ACF.Menu.RegisterPage({
	ID       = "acf_gun",
	Category = "#acf.menu.entities",
	Name     = "#acf.menu.weapons",
	Icon     = "gun",
	Order    = 1,

	Contexts = { Gun = "acf_gun", Ammo = "acf_ammo" },

	Actions = {
		{ Bind = "left",       Context = "Gun",  Preview = true, Desc = "Spawn a new weapon, or update the one you're aiming at." },
		{ Bind = "shift+left", Context = "Ammo", Preview = true, Desc = "Spawn a new ammo crate, or update the one you're aiming at." },
		{ Bind = "right",      Commit = "link", Desc = "Select entities, then a weapon/crate, to link them (hold R to unlink)." },
	},

	Build = Build,
})
