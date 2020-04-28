local AmmoTypes = ACF.Classes.AmmoTypes
local Weapons = ACF.Classes.Weapons
local Crates = ACF.Classes.Crates
local AmmoLists = {}
local Selected = {}
local Sorted = {}

local function GetAmmoList(Class)
	if not Class then return {} end
	if AmmoLists[Class] then return AmmoLists[Class] end

	local Result = {}

	for K, V in pairs(AmmoTypes) do
		if V.Unlistable then continue end
		if V.Blacklist[Class] then continue end

		Result[K] = V
	end

	AmmoLists[Class] = Result

	return Result
end

local function LoadSortedList(Panel, List, Member)
	local Choices = Sorted[List]

	if not Choices then
		Choices = {}

		local Count = 0
		for _, V in pairs(List) do
			Count = Count + 1
			Choices[Count] = V
		end

		table.SortByMember(Choices, Member, true)

		Sorted[List] = Choices
		Selected[Choices] = 1
	end

	Panel:Clear()

	for _, V in pairs(Choices) do
		Panel:AddChoice(V.Name, V)
	end

	Panel:ChooseOptionID(Selected[Choices])
end

local function CreateMenu(Menu)
	local EntText = "Mass : %s kg\nFirerate : %s rpm\nSpread : %s degrees%s"
	local MagText = "\nRounds : %s rounds\nReload : %s seconds"
	local AmmoData

	local ClassList = Menu:AddComboBox()
	local EntList = Menu:AddComboBox()
	local EntName = Menu:AddTitle()
	local ClassDesc = Menu:AddLabel()
	local EntData = Menu:AddLabel()

	Menu:AddTitle("Ammo Settings")

	local CrateList = Menu:AddComboBox()
	local AmmoList = Menu:AddComboBox()

	ACF.WriteValue("PrimaryClass", "acf_gun")
	ACF.WriteValue("SecondaryClass", "acf_ammo")

	ACF.SetToolMode("acf_menu2", "Main", "Spawner")

	function ClassList:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.Selected = Data

		local Choices = Sorted[Weapons]
		Selected[Choices] = Index

		ACF.WriteValue("WeaponClass", Data.ID)

		ClassDesc:SetText(Data.Description)

		LoadSortedList(EntList, Data.Items, "Caliber")
		LoadSortedList(AmmoList, GetAmmoList(Data.ID), "Name")
	end

	function EntList:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.Selected = Data

		local ClassData = ClassList.Selected
		local Choices = Sorted[ClassData.Items]
		Selected[Choices] = Index

		ACF.WriteValue("Weapon", Data.ID)

		EntName:SetText(Data.Name)

		AmmoList:UpdateMenu()
	end

	EntData:TrackDataVar("Projectile", "SetText")
	EntData:TrackDataVar("Propellant")
	EntData:TrackDataVar("Tracer")
	EntData:SetValueFunction(function()
		local Class = ClassList.Selected
		local Data = EntList.Selected

		if not Class then return "" end
		if not Data then return "" end

		local ReloadTime = AmmoData and (ACF.BaseReload + (AmmoData.ProjMass + AmmoData.PropMass) * ACF.MassToTime) or 60
		local Firerate = Data.Cyclic or 60 / ReloadTime
		local Magazine = Data.MagSize and MagText:format(Data.MagSize, Data.MagReload) or ""

		return EntText:format(Data.Mass, math.Round(Firerate, 2), Class.Spread * 100, Magazine)
	end)

	function CrateList:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.Selected = Data

		local Choices = Sorted[Crates]
		Selected[Choices] = Index

		ACF.WriteValue("Crate", Data.ID)
	end

	function AmmoList:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.Selected = Data

		local Choices = Sorted[GetAmmoList(ClassList.Selected.ID)]
		Selected[Choices] = Index

		ACF.WriteValue("Ammo", Data.ID)

		self:UpdateMenu()
	end

	function AmmoList:UpdateMenu()
		if not self.Selected then return end

		local Ammo = self.Selected
		local ToolData = Ammo:GetToolData()

		AmmoData = Ammo:ClientConvert(Menu, ToolData)

		Menu:ClearTemporal(self)
		Menu:StartTemporal(self)

		Menu:AddLabel(Ammo.Description)

		if not Ammo.SupressDefaultMenu then
			local RoundLength = Menu:AddLabel()
			RoundLength:TrackDataVar("Projectile", "SetText")
			RoundLength:TrackDataVar("Propellant")
			RoundLength:TrackDataVar("Tracer")
			RoundLength:SetValueFunction(function()
				local Text = "Round Length: %s / %s cm"
				local CurLength = AmmoData.ProjLength + AmmoData.PropLength + AmmoData.Tracer
				local MaxLength = AmmoData.MaxRoundLength

				return Text:format(CurLength, MaxLength)
			end)

			local Projectile = Menu:AddSlider("Projectile Length", 0, AmmoData.MaxRoundLength, 2)
			Projectile:SetDataVar("Projectile", "OnValueChanged")
			Projectile:SetValueFunction(function(Panel, IsTracked)
				ToolData.Projectile = ACF.ReadNumber("Projectile")

				if not IsTracked then
					AmmoData.Priority = "Projectile"
				end

				Ammo:UpdateRoundData(ToolData, AmmoData)

				ACF.WriteValue("Propellant", AmmoData.PropLength)

				Panel:SetValue(AmmoData.ProjLength)

				return AmmoData.ProjLength
			end)

			local Propellant = Menu:AddSlider("Propellant Length", 0, AmmoData.MaxRoundLength, 2)
			Propellant:SetDataVar("Propellant", "OnValueChanged")
			Propellant:SetValueFunction(function(Panel, IsTracked)
				ToolData.Propellant = ACF.ReadNumber("Propellant")

				if not IsTracked then
					AmmoData.Priority = "Propellant"
				end

				Ammo:UpdateRoundData(ToolData, AmmoData)

				ACF.WriteValue("Projectile", AmmoData.ProjLength)

				Panel:SetValue(AmmoData.PropLength)

				return AmmoData.PropLength
			end)
		end

		if Ammo.MenuAction then
			Ammo:MenuAction(Menu, ToolData, AmmoData)
		end

		Menu:EndTemporal(self)
	end

	LoadSortedList(ClassList, Weapons, "Name")
	LoadSortedList(CrateList, Crates, "ID")
end

ACF.AddOptionItem("Entities", "Weapons", "gun", CreateMenu)
