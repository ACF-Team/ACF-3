local ACF       = ACF
local Weapons   = ACF.Classes.Weapons
local ModelData = ACF.ModelData
local NameText  = "%smm %s"
local EntText   = "Mass : %s\nFirerate : %s rpm\nSpread : %s degrees%s"
local MagText   = "\nRounds : %s rounds\nReload : %s seconds"
local Current   = {}
local CreateControl, IsScalable

---Wrapper function to update the entity preview panel with a given weapon entry object.
---@param Base userdata The panel in which all the weapon controls and information are being placed on.
---@param Data table<string, any> The weapon entry object selected on the menu.
---Note that this could be a weapon group item if the weapon isn't scalable.
local function UpdatePreview(Base, Data)
	local Preview = Base.Preview

	Preview:UpdateModel(Data.Model)
	Preview:UpdateSettings(Data.Preview)
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
		local Bounds  = Class.Caliber
		local Caliber = ACF.GetClientNumber("Caliber", Bounds.Base)

		Base.Slider:SetMinMax(Bounds.Min, Bounds.Max)

		ACF.SetClientData("Weapon", Class.ID)
		ACF.SetClientData("Caliber", Caliber, true)

		UpdatePreview(Base, Class)
	else
		ACF.LoadSortedList(Base.List, Class.Items, "Caliber")
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
		local Bounds = Current.Class.Caliber
		local Slider = Base:AddSlider("Caliber", Bounds.Min, Bounds.Max, 2)
		Slider:SetClientData("Caliber", "OnValueChanged")
		Slider:DefineSetter(function(Panel, _, _, Value)
			local Caliber = math.Round(Value, 2)

			Title:SetText(NameText:format(Caliber, Current.Class.Name))
			Panel:SetValue(Caliber)

			Current.Caliber = Caliber

			ACF.UpdateAmmoMenu(Menu)

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

			ACF.SetClientData("Weapon", Data.ID)
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
local function GetReloadTime()
	local BulletData = ACF.GetCurrentAmmoData()

	if not BulletData then return 60 end

	return ACF.BaseReload + (BulletData.ProjMass + BulletData.PropMass) * ACF.MassToTime
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

	local MagReload = ACF.GetWeaponValue("MagReload", Caliber, Class, Weapon)

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
local function GetMass(Panel, Caliber, Class, Weapon)
	if Weapon then return Weapon.Mass end

	local Model = Class.Model
	local Base  = ModelData.GetModelVolume(Model)

	if not Base then
		if ModelData.IsOnStandby(Model) then
			ModelData.QueueRefresh(Model, Panel, function()
				Panel:SetText(Panel:GetText())
			end)
		end

		return 0
	end

	local Scale  = Caliber / Class.Caliber.Base
	local Scaled = ModelData.GetModelVolume(Model, Scale)

	return math.Round(Class.Mass * Scaled / Base)
end

local function CreateMenu(Menu)
	local Entries = Weapons.GetEntries()

	Menu:AddTitle("Weapon Settings")

	local ClassBase  = Menu:AddPanel("ACF_Panel")
	local ClassList  = ClassBase:AddComboBox()
	local WeaponBase = Menu:AddCollapsible("Weapon Information")
	local EntName    = WeaponBase:AddTitle()
	local ClassDesc  = WeaponBase:AddLabel()
	local EntPreview = WeaponBase:AddModelPreview(nil, true)
	local EntData    = WeaponBase:AddLabel()
	local AmmoList   = ACF.CreateAmmoMenu(Menu)

	-- Configuring the ACF Spawner tool
	ACF.SetClientData("PrimaryClass", "acf_gun") -- Left click will create an acf_gun entity
	ACF.SetClientData("SecondaryClass", "acf_ammo") -- Right click will create an acf_ammo entity
	ACF.SetClientData("Destiny", "Weapons") -- The information of these entities will come from ACF.Classes.Weapons

	ACF.SetToolMode("acf_menu", "Spawner", "Weapon") -- The ACF Menu tool will be set to spawner stage, weapon operation

	function ClassList:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.ListData.Index = Index
		self.Selected = Data

		Current.Class = Data

		UpdateMode(ClassBase, Data)

		ClassDesc:SetText(Data.Description)

		AmmoList:LoadEntries(Data.ID)
	end

	EntData:TrackClientData("Projectile", "SetText")
	EntData:TrackClientData("Propellant")
	EntData:TrackClientData("Tracer")
	EntData:DefineSetter(function()
		local Class = Current.Class

		if not Class then return "" end

		local Weapon   = Current.Weapon
		local Caliber  = Current.Caliber
		local Mass     = ACF.GetProperMass(GetMass(EntData, Caliber, Class, Weapon))
		local Firerate = ACF.GetWeaponValue("Cyclic", Caliber, Class, Weapon) or 60 / GetReloadTime()
		local Spread   = ACF.GetWeaponValue("Spread", Caliber, Class, Weapon)
		local Magazine = GetMagazineText(Caliber, Class, Weapon)

		return EntText:format(Mass, math.Round(Firerate), Spread, Magazine)
	end)

	ClassBase.Menu    = Menu
	ClassBase.Title   = EntName
	ClassBase.Preview = EntPreview

	ACF.LoadSortedList(ClassList, Entries, "Name")
end

ACF.AddMenuItem(1, "Entities", "Weapons", "gun", CreateMenu)
