local ACF       = ACF
local Classes   = ACF.Classes
local ModelData = ACF.ModelData
local Current   = {}
local CreateControl, IsScalable

-- Non-scalable weapons expose their concrete, selectable variants as IsWeaponOption subtypes
-- (e.g. ACF.Guns.40mmFlareLauncher under ACF.Guns.FlareLauncher). Cached per category class.
local OptionCache = {}
local function GetWeaponOptions(Class)
	local Cached = OptionCache[Class]
	if Cached then return Cached end

	local Options = {}

	for _, Child in pairs(Classes.GetSubtypes(Classes.GetTypeName(Class))) do
		if Child.IsWeaponOption then
			Options[#Options + 1] = Child
		end
	end

	OptionCache[Class] = Options

	return Options
end

---Wrapper function to update the entity preview panel with a given weapon entry object.
---@param Base userdata The panel in which all the weapon controls and information are being placed on.
---@param Data table<string, any> The weapon entry object selected on the menu.
---Note that this could be a weapon group item if the weapon isn't scalable.
local function UpdatePreview(Base, Data)
	local Preview = Base.Preview
	local Class   = Current.Class
	local Caliber = Current.Caliber
	local Weapon  = Current.Weapon

	Preview:UpdateModel(Data.Model)
	Preview:UpdateSettings(Data.Preview)

	-- Set scale to 1 if Weapon exists (non scaled lmao), or relative caliber otherwise
	local Scale   = Weapon and 1 or (Caliber / Class.CaliberLimits.Base * (Class.ScaleFactor or 1))
	local Preview = Base.Preview

	Preview:SetModelScale(Scale, true)
end

---Updates the current weapon class controls on the menu.
---For scalable weapons, this will update the caliber slider values and the Weapon and Caliber client data variables.
---For non-scalable weapons, this will update the combobox of weapon items.
---@param Base userdata The panel in which all the weapon information and controls are being placed on.
local function UpdateControl(Base)
	local Control = Either(IsScalable, Base.Slider, Base.List)
	local Class   = Current.Class

	-- Needed for when the menu is reloaded
	if not IsValid(Control) then
		CreateControl(Base)
	end

	if IsScalable then
		local Bounds  = Class.CaliberLimits
		local Caliber = ACF.GetClientNumber("Caliber", Bounds.Base)

		ACF.SetClientData("Weapon", Classes.GetTypeName(Class:GetType()))
		ACF.SetClientData("Caliber", Caliber, true)

		Base.Slider:SetMinMax(Bounds.Min, Bounds.Max)

		UpdatePreview(Base, Class)
	else
		ACF.LoadSortedList(Base.List, GetWeaponOptions(Class), "Caliber")
	end
end

---Creates and updates the current weapon class controls on the menu.
---For scalable weapons, this will create a caliber slider.
---For non-scalable weapons, this will create a combobox with all the weapon items of the current weapon group.
---@param Base userdata The panel in which all the weapon information and controls are being placed on.
CreateControl = function(Base)
	local Previous = Either(IsScalable, Base.List, Base.Slider)
	local Title    = Base.Title
	local Menu     = Base.Menu

	-- Remove old control
	if IsValid(Previous) then
		Previous:Remove()
	end

	if IsScalable then -- Scalable
		local Bounds = Current.Class.CaliberLimits
		-- Set default caliber value before creating the slider to prevent nil value errors
		local DefaultCaliber = ACF.GetClientNumber("Caliber", Bounds.Base)
		ACF.SetClientData("Caliber", DefaultCaliber, true)

		local Slider = Base:AddSlider("#acf.menu.caliber", Bounds.Min, Bounds.Max, 2)
		Slider:SetClientData("Caliber", "OnValueChanged")
		Slider:DefineSetter(function(Panel, _, _, Value)
			local Caliber  = math.Round(Value, 2)
			local NameText = language.GetPhrase("acf.menu.weapons.name_text")

			Title:SetText(NameText:format(Caliber, Current.Class.Name))
			Panel:SetValue(Caliber)

			Current.Caliber = Caliber

			ACF.UpdateAmmoMenu(Menu)
			UpdatePreview(Base, Current.Class)

			return Caliber
		end)

		Current.Weapon = nil

		Base.Slider = Slider
	else -- Not scalable
		local List = Base:AddComboBox()

		function List:OnSelect(Index, _, Data)
			if self.Selected == Data then return end

			self.ListData.Index = Index
			self.Selected = Data

			Current.Weapon  = Data
			Current.Caliber = Data.Caliber

			ACF.SetClientData("Weapon", Classes.GetTypeName(Data:GetType()))
			ACF.SetClientData("Caliber", Data.Caliber)

			Title:SetText(Data.Name)

			UpdatePreview(Base, Data)

			ACF.UpdateAmmoMenu(Menu)
		end

		Base.List = List
	end

	UpdateControl(Base)
end

---Updates or recreates the menu depending on the current weapon entry object's scalability being different from the one previously selected.
---@param Base userdata The panel in which all the weapon information and controls are being placed on.
---@param Class table<string, any> The weapon entry object selected on the menu.
local function UpdateMode(Base, Class)
	local Mode = tobool(Class.IsScalable)

	if Mode ~= IsScalable then
		IsScalable = Mode

		CreateControl(Base)
	else
		UpdateControl(Base)
	end
end

---Returns the reload time of the selected weapon entry object using the current ammunition settings.
---@return integer ReloadTime The expected reload time of the weapon with the given ammunition.
local function GetReloadTime(Caliber, Class, Weapon)
	local BulletData = ACF.GetCurrentAmmoData()

	if not BulletData then return 60 end

	return ACF.CalcReloadTime(Caliber, Class, Weapon, BulletData)
end

---Returns a string with the magazine capacity and reload time of a given weapon entry object.
---@param Caliber? number The caliber of the weapon in mm.
---@param Class? table<string, any> The weapon group object to get information from.
---@param Weapon? table<string, any> The weapon item object to get informatio from, not necessary for scalable weapons.
---@return string Text The string to be used in the weapon information label on the menu.
---This can be an empty string if the magazine size can't be found.
local function GetMagazineText(Caliber, Class, Weapon)
	local MagSize = ACF.GetWeaponValue("MagSize", Caliber, Class, Weapon)

	if not MagSize then return "" end

	local MagText    = language.GetPhrase("acf.menu.weapons.mag_stats")
	local BulletData = ACF.GetCurrentAmmoData()
	if not BulletData then return "" end
	local MagReload  = ACF.CalcReloadTimeMag(Caliber, Class, Weapon, BulletData)

	return MagText:format(math.floor(MagSize), math.Round(MagReload, 2))
end

---Returns the expected mass of a weapon that would be created by a given entry object.
---For scalable weapons, this might be 0 at first if the model information hasn't been received from the server.
---The panel will be automatically updated once the information is received.
---@param Panel userdata The label panel in which the weapon information is being listed on.
---@param Caliber? number The caliber of the weapon in mm. Not necessary for non-scalable weapons.
---@param Class? table<string, any> The weapon group object to get information from. Not necessary for non-scalable weapons.
---@param Weapon table<string, any> The weapon item object to get informatio from, not necessary for scalable weapons.
---@return number Mass The expected mass.
local function GetMass(_, Caliber, Class, Weapon)
	if Weapon then return Weapon.Mass end

	local Model = Class.Model
	local Base  = ModelData.GetModelVolume(Model)

	if not Base then
		return 0
	end

	local Scale  = Caliber / Class.CaliberLimits.Base
	local Scaled = ModelData.GetModelVolume(Model, Scale)

	return math.Round(Class.Mass * Scaled / Base)
end

local function CreateMenu(Menu)
	local Subtypes = Classes.GetSubtypes("ACF.Guns.BaseGun") -- This menu name is a lie!!! It only has guns (we probably should fix that, but thats more effort than its worth right now)
	local Entries = {}

	for ID, Type in pairs(Subtypes) do
		if Type.IsWeapon and not Type.IsWeaponOption then
			Entries[ID] = Type
		end
	end

	Menu:AddTitle("#acf.menu.weapons.settings")

	Menu:AddWikiLink("Weapons", "docs/acf_tutorials/weapons.html")

	-- Weapon Settings Section (collapsible)
	local WeaponBase = Menu:AddCollapsible("#acf.menu.weapons.weapon_info", true, "icon16/monitor_edit.png")

	-- Weapon type dropdown (inside collapsible)
	local ClassList  = WeaponBase:AddComboBox()
	ClassList:SetName("WeaponClassList")

	-- Panel for dynamic controls (caliber slider or weapon list)
	local ClassBase  = WeaponBase:AddPanel("ACF_Panel")

	local EntName    = WeaponBase:AddTitle()
	local ClassDesc  = WeaponBase:AddLabel()
	local EntPreview = WeaponBase:AddModelPreview(nil, true, "Primary")
	local EntData    = WeaponBase:AddLabel()
	local BreechIndex = WeaponBase:AddComboBox()
	BreechIndex:SetName("WeaponBreechIndex")
	local AmmoList   = ACF.CreateAmmoMenu(Menu)

	-- Configuring the ACF Spawner tool
	ACF.SetClientData("PrimaryClass", "acf_gun") -- Left click will create an acf_gun entity
	ACF.SetClientData("SecondaryClass", "acf_ammo") -- Right click will create an acf_ammo entity
	ACF.SetToolMode("acf_menu", "Spawner", "Weapon") -- The ACF Menu tool will be set to spawner stage, weapon operation

	function ClassList:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.ListData.Index = Index
		self.Selected = Data

		Current.Class = Data

		UpdateMode(ClassBase, Data)

		ClassDesc:SetText(Data.Description)

		AmmoList:LoadEntries(Data:GetType())

		BreechIndex:Clear()
		if Data.BreechConfigs then
			for Index, Config in ipairs(Data.BreechConfigs.Locations) do
				BreechIndex:AddChoice("Loaded At: " .. Config.Name, Index)
			end

			BreechIndex:SetVisible(true)
			BreechIndex:SetClientData("BreechIndex", "OnSelect")
			BreechIndex:DefineSetter(function(_, _, _, Value)
				ACF.SetClientData("BreechIndex", Value)
				return Value
			end)
			BreechIndex:ChooseOptionID(Data.BreechIndex or 1)
		else
			BreechIndex:SetVisible(false)
		end
	end

	EntData:TrackClientData("Projectile", "SetText")
	EntData:TrackClientData("Propellant")
	EntData:TrackClientData("Tracer")
	EntData:TrackClientData("Caliber")
	local function Update()
		local Class = Current.Class

		if not Class then return "" end

		local Weapon   = Current.Weapon

		local EntText  = language.GetPhrase("acf.menu.weapons.weapon_stats")
		local Caliber  = Current.Caliber
		if not Caliber then return "" end

		local Mass     = ACF.GetProperMass(GetMass(EntData, Caliber, Class, Weapon))
		local FireDelay = GetReloadTime(Caliber, Class, Weapon)
		local FireRate = 60 / FireDelay
		local Spread   = ACF.GetWeaponValue("Spread", Caliber, Class, Weapon)
		local Magazine = GetMagazineText(Caliber, Class, Weapon)

		return EntText:format(Mass, math.Round(FireRate), math.Round(FireDelay, 3), Spread, Magazine)
	end
	EntData:DefineSetter(Update)
	EntData:SetText("")

	ClassBase.Menu    = Menu
	ClassBase.Title   = EntName
	ClassBase.Preview = EntPreview

	ACF.LoadSortedList(ClassList, Entries, "Name", "Model")
end

ACF.AddMenuItem(1, "#acf.menu.entities", "#acf.menu.weapons", "gun", CreateMenu)