local ACF     = ACF
local Classes = ACF.Classes
local PAGE    = "acf_rack"

local MISSILE_BASE = "ACF.Missiles.BaseMissile"
local RACK_BASE    = "ACF.Racks.BaseRack"

local function GetRackClass(ID)
	local Direct = Classes.GetSubtypeByName(RACK_BASE, ID)
	if Direct then return Direct end

	for _, Class in ipairs(Classes.GetSubtypesAsList(RACK_BASE)) do
		if Classes.GetTypeName(Class):match("[^.]+$") == ID then return Class end
	end
end

local function GetRackList(Data)
	local Result = {}

	if Data then
		for Rack in pairs(Data.Racks) do
			local Info = GetRackClass(Rack)
			if Info then Result[Rack] = Info end
		end
	end

	return Result
end

local BaseText    = "Caliber : %s\nMass : %s"
local RackText    = BaseText .. "\nCost : %s\nMunitions : %s%s\n"
local MissileText = BaseText .. "\nArming Delay : %ss%s%s"

local function GetMissileText(Data)
	local Seek = Data.SeekCone and ("\nSeek Cone : " .. Data.SeekCone * 2 .. " degrees") or ""
	local View = Data.ViewCone and ("\nView Cone : " .. Data.ViewCone * 2 .. " degrees") or ""

	return MissileText:format(Data.Caliber .. "mm", ACF.FormatMass(Data.Mass or 10), Data.ArmDelay, Seek, View)
end

local function GetRackText(Data)
	local Caliber = Data.Caliber and (Data.Caliber .. "mm") or "Any caliber"
	local Protect = Data.ProtectMissile and "\n\nThis rack will protect its payload from getting destroyed." or ""

	local Cost = Data.Cost or Data.MagSize * (Data.CostPerSlot or 1.5) -- Mirrors acf_rack's GetCost

	return RackText:format(Caliber, ACF.FormatMass(Data.Mass or 0), ACF.FormatCost(Cost), Data.MagSize, Protect)
end

local function Build(Menu, Contexts)
	local Rack = Contexts.Rack
	local Ammo = Contexts.Ammo

	local Entries = Classes.GetChildren(Classes.GetTypeByName(MISSILE_BASE))

	Menu:AddTitle("Missile Settings")

	local MissileTypes = Menu:AddComboBox()
	local MissileList  = Menu:AddComboBox()

	local MissileBase    = Menu:AddCollapsible("Missile Information")
	local MissileTitle   = MissileBase:AddTitle()
	local MissileClass   = MissileBase:AddLabel()
	local MissileDesc    = MissileBase:AddLabel()
	local MissilePreview = MissileBase:AddModelPreview(nil, true)
	local MissileInfo    = MissileBase:AddLabel()

	Menu:AddTitle("Rack Settings")

	local RackList = Menu:AddComboBox()

	local RackBase    = Menu:AddCollapsible("Rack Information")
	local RackTitle   = RackBase:AddTitle()
	local RackDesc    = RackBase:AddLabel()
	local RackPreview = RackBase:AddModelPreview(nil, true, "Primary")
	local RackInfo    = RackBase:AddLabel()
	local BreechIndex = RackBase:AddComboBox()

	local AmmoList = ACF.CreateAmmoMenu(Menu, Ammo)

	function MissileTypes:OnSelect(Index, _, Data)
		if self.Selected == Data then return end
		self.ListData.Index = Index
		self.Selected = Data
		ACF.Menu.SaveClassCombo(PAGE, "group", Data)

		MissileClass:SetText(Data.Description)

		AmmoList:LoadEntries(Data:GetType())
		ACF.Menu.LoadClassCombo(MissileList, Classes.GetChildren(Data), "Caliber", "Model", PAGE, "missile")
	end

	function MissileList:OnSelect(Index, _, Data)
		if self.Selected == Data then return end
		self.ListData.Index = Index
		self.Selected = Data
		ACF.Menu.SaveClassCombo(PAGE, "missile", Data)

		-- The missile is the ammo crate's weapon back-reference (drives the round math). Only swap the
		-- nested instance when the missile type actually changes, so a re-select / menu reopen keeps the
		-- configured Guidance/Fuze instead of resetting them to defaults.
		Ammo.Destiny = Data.Destiny or "Missiles"
		local CurWeapon = Ammo:Get("Weapon")
		if not (CurWeapon and CurWeapon.GetType and CurWeapon:GetType() == Data) then
			Ammo:Set("Weapon", { Type = Classes.GetTypeName(Data), Data = {} })
		end

		ACF.Menu.LoadClassCombo(RackList, GetRackList(Data), "MagSize", "Model", PAGE, "rack")

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
		ACF.Menu.SaveClassCombo(PAGE, "rack", Data)

		Rack:Set("Rack", Classes.GetTypeName(Data))

		RackTitle:SetText(Data.Name)
		RackDesc:SetText(Data.Description)
		RackInfo:SetText(GetRackText(Data))
		RackPreview:UpdateModel(Data.Model)
		RackPreview:UpdateSettings(Data.Preview)

		BreechIndex:Clear()
		if Data.BreechConfigs then
			for Idx, Config in ipairs(Data.BreechConfigs.Locations) do
				BreechIndex:AddChoice("Loaded At: " .. Config.Name, Idx)
			end

			BreechIndex:SetVisible(true)
			function BreechIndex:OnSelect(_, _, Value)
				Rack:Set("BreechIndex", Value)
			end
			BreechIndex:ChooseOptionID(Data.BreechIndex or 1)
		else
			BreechIndex:SetVisible(false)
			Rack:Set("BreechIndex", 1)
		end
	end

	ACF.Menu.LoadClassCombo(MissileTypes, Entries, "ID", "Model", PAGE, "group")
end

ACF.Menu.RegisterPage({
	ID       = "acf_rack",
	Category = "#acf.menu.entities",
	Name     = "Missiles",
	Icon     = "wand",
	Order    = 101,

	Contexts = { Rack = "acf_rack", Ammo = "acf_ammo" },

	Actions = {
		{ Bind = "left",       Context = "Rack", Preview = true, Desc = "Spawn a new missile rack, or update the one you're aiming at." },
		{ Bind = "shift+left", Context = "Ammo", Preview = true, Desc = "Spawn a new ammo crate, or update the one you're aiming at." },
		{ Bind = "right",      Commit = "link", Desc = "Select entities, then a rack/crate, to link them (hold R to unlink)." },
	},

	Build = Build,
})

-- Missile crates don't use tracers; suppress the ammo menu's tracer checkbox for them.
hook.Add("ACF_PreCreateTracerControls", "ACF Missiles Remove Tracer Checkbox", function(_, ToolData)
	if ToolData.Destiny == "Missiles" then return false end
end)
