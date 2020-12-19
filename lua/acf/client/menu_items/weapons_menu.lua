local ACF = ACF
local Weapons = ACF.Classes.Weapons

local function CreateMenu(Menu)
	local EntText = "Mass : %s kg\nFirerate : %s rpm\nSpread : %s degrees%s\n\nThis entity can be fully parented."
	local MagText = "\nRounds : %s rounds\nReload : %s seconds"

	Menu:AddTitle("Weapon Settings")

	local ClassList = Menu:AddComboBox()
	local EntList = Menu:AddComboBox()

	local WeaponBase = Menu:AddCollapsible("Weapon Information")
	local EntName = WeaponBase:AddTitle()
	local ClassDesc = WeaponBase:AddLabel()
	local EntPreview = WeaponBase:AddModelPreview()
	local EntData = WeaponBase:AddLabel()

	local AmmoList = ACF.CreateAmmoMenu(Menu)

	ACF.SetClientData("PrimaryClass", "acf_gun")
	ACF.SetClientData("SecondaryClass", "acf_ammo")

	ACF.SetToolMode("acf_menu", "Main", "Spawner")

	function ClassList:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.ListData.Index = Index
		self.Selected = Data

		ACF.SetClientData("WeaponClass", Data.ID)

		ClassDesc:SetText(Data.Description)

		ACF.LoadSortedList(EntList, Data.Items, "Caliber")

		AmmoList:LoadEntries(Data.ID)
	end

	function EntList:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.ListData.Index = Index
		self.Selected = Data

		local Preview = Data.Preview

		ACF.SetClientData("Weapon", Data.ID)
		ACF.SetClientData("Destiny", Data.Destiny or "Weapons")

		EntName:SetText(Data.Name)

		EntPreview:SetModel(Data.Model)
		EntPreview:SetCamPos(Preview and Preview.Offset or Vector(45, 60, 45))
		EntPreview:SetLookAt(Preview and Preview.Position or Vector())
		EntPreview:SetHeight(Preview and Preview.Height or 80)
		EntPreview:SetFOV(Preview and Preview.FOV or 75)

		ACF.UpdateAmmoMenu(Menu)
	end

	EntData:TrackClientData("Projectile", "SetText")
	EntData:TrackClientData("Propellant")
	EntData:TrackClientData("Tracer")
	EntData:DefineSetter(function()
		local Class = ClassList.Selected
		local Data  = EntList.Selected

		if not Class then return "" end
		if not Data then return "" end

		local AmmoData   = ACF.GetCurrentAmmoData()
		local ReloadTime = AmmoData and (ACF.BaseReload + (AmmoData.ProjMass + AmmoData.PropMass) * ACF.MassToTime) or 60
		local Firerate   = Data.Cyclic or 60 / ReloadTime
		local Magazine   = Data.MagSize and MagText:format(Data.MagSize, Data.MagReload) or ""

		return EntText:format(Data.Mass, math.Round(Firerate, 2), Class.Spread * 100, Magazine)
	end)

	ACF.LoadSortedList(ClassList, Weapons, "Name")
end

ACF.AddMenuItem(1, "Entities", "Weapons", "gun", CreateMenu)
