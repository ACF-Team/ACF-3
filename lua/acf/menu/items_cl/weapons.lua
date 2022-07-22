local ACF       = ACF
local Weapons   = ACF.Classes.Weapons
local ModelData = ACF.ModelData
local NameText  = "%smm %s"
local EntText   = "Mass : %s\nFirerate : %s rpm\nSpread : %s degrees%s\n\nThis entity can be fully parented."
local MagText   = "\nRounds : %s rounds\nReload : %s seconds"
local Current   = {}
local CreateControl, IsScalable

local function UpdatePreview(Base, Data)
	local Preview = Base.Preview

	Preview:UpdateModel(Data.Model)
	Preview:UpdateSettings(Data.Preview)
end

local function UpdateControl(Base)
	local Control = Either(IsScalable, Base.Slider, Base.List)
	local Class   = Current.Class

	-- Needed for when the menu is reloaded
	if not IsValid(Control) then
		CreateControl(Base)
	end

	if IsScalable then -- Scalable
		local Bounds  = Class.Caliber
		local Caliber = ACF.GetClientNumber("Caliber", Bounds.Base)

		Base.Slider:SetMinMax(Bounds.Min, Bounds.Max)

		ACF.SetClientData("Weapon", Class.ID)
		ACF.SetClientData("Caliber", Caliber, true)

		UpdatePreview(Base, Class)
	else -- Not scalable
		ACF.LoadSortedList(Base.List, Class.Items, "Caliber")
	end
end

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

local function UpdateMode(Base, Class)
	local Mode = tobool(Class.IsScalable)

	if Mode ~= IsScalable then
		IsScalable = Mode

		CreateControl(Base)
	else
		UpdateControl(Base)
	end
end

local function GetReloadTime()
	local BulletData = ACF.GetCurrentAmmoData()

	if not BulletData then return 60 end

	return ACF.BaseReload + (BulletData.ProjMass + BulletData.PropMass) * ACF.MassToTime
end

local function GetMagazineText(Caliber, Class, Weapon)
	local MagSize = ACF.GetWeaponValue("MagSize", Caliber, Class, Weapon)

	if not MagSize then return "" end

	local MagReload = ACF.GetWeaponValue("MagReload", Caliber, Class, Weapon)

	return MagText:format(math.floor(MagSize), math.Round(MagReload, 2))
end

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

	ACF.SetClientData("PrimaryClass", "acf_gun")
	ACF.SetClientData("SecondaryClass", "acf_ammo")
	ACF.SetClientData("Destiny", "Weapons")

	ACF.SetToolMode("acf_menu", "Spawner", "Weapon")

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
