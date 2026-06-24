local ACF      = ACF
local Classes  = ACF.Classes
local Missiles = Classes.Missiles
local Racks    = Classes.Racks

local function GetRackList(Data)
	local Result = {}

	if Data then
		for Rack in pairs(Data.Racks) do
			local Info = Racks.Get(Rack)

			if Info then
				Result[Rack] = Info
			end
		end
	end

	return Result
end

local BaseText = "Caliber : %s\nMass : %s kg"
local RackText = BaseText .. "\nMunitions : %s%s\n"
local MissileText = BaseText .. "\nArming Delay : %ss%s%s"

local function GetMissileText(Data)
	local Caliber = Data.Caliber .. "mm"
	local Seek = ""
	local View = ""

	if Data.SeekCone then
		Seek = "\nSeek Cone : " .. Data.SeekCone * 2 .. " degrees"
	end

	if Data.ViewCone then
		View = "\nView Cone : " .. Data.ViewCone * 2 .. " degrees"
	end

	return MissileText:format(Caliber, Data.Mass, Data.ArmDelay, Seek, View)
end

local function GetRackText(Data)
	local Caliber = "Any caliber"
	local Protect = ""

	if Data.Caliber then
		Caliber = Data.Caliber .. "mm"
	end

	if Data.ProtectMissile then
		Protect = "\n\nThis rack will protect its payload from getting destroyed."
	end

	return RackText:format(Caliber, Data.Mass, Data.MagSize, Protect)
end

local function CreateMenu(Menu)
	local Entries = Missiles.GetEntries()

	Menu:AddTitle("Missile Settings")

	local MissileTypes = Menu:AddComboBox()
	MissileTypes:SetName("MissileTypes")
	local MissileList = Menu:AddComboBox()
	MissileList:SetName("MissileList")

	local MissileBase = Menu:AddCollapsible("Missile Information")
	local MissileTitle = MissileBase:AddTitle()
	local MissileClass = MissileBase:AddLabel()
	local MissileDesc = MissileBase:AddLabel()
	local MissilePreview = MissileBase:AddModelPreview(nil, true)
	local MissileInfo = MissileBase:AddLabel()

	Menu:AddTitle("Rack Settings")

	local RackList = Menu:AddComboBox()

	local RackBase = Menu:AddCollapsible("Rack Information")
	local RackTitle = RackBase:AddTitle()
	local RackDesc = RackBase:AddLabel()
	local RackPreview = RackBase:AddModelPreview(nil, true, "Primary")
	local RackInfo = RackBase:AddLabel()

	local BreechIndex = RackBase:AddComboBox()

	local AmmoList = ACF.CreateAmmoMenu(Menu)

	ACF.SetClientData("PrimaryClass", "acf_rack")
	ACF.SetClientData("SecondaryClass", "acf_ammo")

	ACF.SetToolMode("acf_menu", "Spawner", "Missile")

	function MissileTypes:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.ListData.Index = Index
		self.Selected = Data

		ACF.SetClientData("WeaponClass", Data.ID)

		MissileClass:SetText(Data.Description)

		ACF.LoadSortedList(MissileList, Data.Items, "Caliber", "Model")

		AmmoList:LoadEntries(Data:GetType())
	end

	function MissileList:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.ListData.Index = Index
		self.Selected = Data

		ACF.SetClientData("Weapon", Data.ID)
		ACF.SetClientData("Destiny", Data.Destiny or "Missiles")

		ACF.LoadSortedList(RackList, GetRackList(Data), "MagSize", "Model")

		MissileTitle:SetText(Data.Name)
		MissileDesc:SetText(Data.Description)

		MissilePreview:UpdateModel(Data.Model)
		MissilePreview:UpdateSettings(Data.Preview)

		MissileInfo:SetText(GetMissileText(Data))

		Menu.AmmoBase.MissileData = Data

		ACF.UpdateAmmoMenu(Menu)
	end

	function RackList:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.ListData.Index = Index
		self.Selected = Data

		ACF.SetClientData("Rack", Data.ID)

		RackTitle:SetText(Data.Name)
		RackDesc:SetText(Data.Description)
		RackInfo:SetText(GetRackText(Data))

		RackPreview:UpdateModel(Data.Model)
		RackPreview:UpdateSettings(Data.Preview)

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

	ACF.LoadSortedList(MissileTypes, Entries, "ID", "Model")
end

ACF.AddMenuItem(101, "#acf.menu.entities", "Missiles", "wand", CreateMenu)

hook.Add("ACF_PreCreateTracerControls", "ACF Missiles Remove Tracer Checkbox", function(_, ToolData)
	if ToolData.PrimaryClass == "acf_rack" then return false end
end)
