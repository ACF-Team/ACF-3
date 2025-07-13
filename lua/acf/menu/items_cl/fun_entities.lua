local ACF     = ACF
local Classes = ACF.Classes

do -- Piledrivers menu
	local Piledrivers = Classes.Piledrivers
	local AmmoTypes   = Classes.AmmoTypes
	local Ammo, BulletData

	local function CreateMenu(Menu)
		local Entries  = Piledrivers.GetEntries()
		local AmmoType = AmmoTypes.Get("HP")

		Menu:AddTitle("#acf.menu.fun.piledrivers.settings")

		local ClassList = Menu:AddComboBox()
		local Caliber = Menu:AddSlider("#acf.menu.caliber", 0, 1, 2)

		local ClassBase = Menu:AddCollapsible("#acf.menu.fun.piledrivers.piledriver_info", nil, "icon16/monitor_edit.png")
		local ClassName = ClassBase:AddTitle()
		local ClassDesc = ClassBase:AddLabel()
		local ClassPreview = ClassBase:AddModelPreview(nil, true)
		local ClassInfo = ClassBase:AddLabel()
		local ClassStats = ClassBase:AddLabel()

		ACF.SetClientData("PrimaryClass", "acf_piledriver")
		ACF.SetClientData("SecondaryClass", "N/A")
		ACF.SetClientData("Destiny", "Piledrivers")
		ACF.SetClientData("AmmoType", "HP")
		ACF.SetClientData("Propellant", 0)
		ACF.SetClientData("Tracer", false)

		ACF.SetToolMode("acf_menu", "Spawner", "Weapon")

		function ClassList:OnSelect(Index, _, Data)
			if self.Selected == Data then return end

			self.ListData.Index = Index
			self.Selected = Data

			local Bounds   = Data.Caliber
			local Min, Max = Bounds.Min, Bounds.Max
			local Current  = math.Clamp(ACF.GetClientNumber("Caliber", Min), Min, Max)

			Ammo = AmmoType()

			ClassDesc:SetText(Data.Description)

			ClassPreview:UpdateModel(Data.Model)
			ClassPreview:UpdateSettings(Data.Preview)

			ACF.SetClientData("Weapon", Data.ID)
			ACF.SetClientData("Caliber", Current, true)

			Caliber:SetMinMax(Min, Max)
		end

		Caliber:SetClientData("Caliber", "OnValueChanged")
		Caliber:DefineSetter(function(Panel, _, _, Value)
			if not ClassList.Selected then return Value end

			local Class  = ClassList.Selected
			local Scale  = Value / Class.Caliber.Base
			local Length = Class.Round.MaxLength * Scale

			Ammo.SpikeLength = Length

			ACF.SetClientData("Projectile", Length)

			BulletData = Ammo:ClientConvert(ACF.GetAllClientData())

			Panel:SetValue(Value)

			return Value
		end)

		ClassName:TrackClientData("Weapon", "SetText")
		ClassName:TrackClientData("Caliber")
		ClassName:DefineSetter(function()
			local Current = math.Round(Caliber:GetValue(), 2)
			local Name    = ClassList.Selected.Name

			return language.GetPhrase("acf.menu.fun.piledrivers.class_name"):format(Current, Name)
		end)

		ClassInfo:TrackClientData("Weapon", "SetText")
		ClassInfo:TrackClientData("Caliber")
		ClassInfo:DefineSetter(function()
			if not BulletData then return "" end

			local Info     = language.GetPhrase("acf.menu.fun.piledrivers.stats")
			local Class    = ClassList.Selected
			local Current  = math.Round(Caliber:GetValue(), 2)
			local Scale    = Current / Class.Caliber.Base
			local Mass     = Class.Mass * Scale
			local FireRate = Class.Cyclic
			local Total    = Class.MagSize
			local Charge   = Class.ChargeRate

			return Info:format(Mass, FireRate, Total, Charge)
		end)

		ClassStats:TrackClientData("Weapon", "SetText")
		ClassStats:TrackClientData("Caliber")
		ClassStats:DefineSetter(function()
			if not BulletData then return "" end

			local Stats     = language.GetPhrase("acf.menu.fun.piledrivers.damage_stats")
			local MaxPen    = math.Round(BulletData.MaxPen, 2)
			local MuzzleVel = math.Round(BulletData.MuzzleVel, 2)
			local Length    = BulletData.ProjLength
			local Mass      = ACF.GetProperMass(BulletData.ProjMass)

			return Stats:format(MaxPen, MuzzleVel, Length, Mass)
		end)

		ACF.LoadSortedList(ClassList, Entries, "Name", "Model")
	end

	ACF.AddMenuItem(1, "#acf.menu.fun", "#acf.menu.fun.piledrivers", "pencil", CreateMenu)
end

do -- Procedural Armor
	local ArmorTypes  = Classes.ArmorTypes
	local PreviewSettings = {
		FOV = 120,
		Height = 160,
	}

	local function CreateMenu(Menu)
		local Entries = ArmorTypes.GetEntries()

		ACF.SetToolMode("acf_menu", "Spawner", "Armor")

		ACF.SetClientData("PrimaryClass", "acf_armor")
		ACF.SetClientData("SecondaryClass", "N/A")

		Menu:AddTitle("#acf.menu.fun.armor.menu_title")
		Menu:AddLabel("#acf.menu.fun.armor.warning")

		local ClassList = Menu:AddComboBox()
		local SizeX     = Menu:AddSlider("#acf.menu.fun.armor.plate_length", 0.25, 420, 2)
		local SizeY     = Menu:AddSlider("#acf.menu.fun.armor.plate_width", 0.25, 420, 2)
		local SizeZ     = Menu:AddSlider("#acf.menu.fun.armor.plate_thickness", 5, 1000)

		local ClassBase    = Menu:AddCollapsible("#acf.menu.fun.armor.material_info")
		local ClassName    = ClassBase:AddTitle()
		local ClassDesc    = ClassBase:AddLabel()
		local ClassPreview = ClassBase:AddModelPreview("models/holograms/hq_rcube_thin.mdl", true)
		local ClassDens    = ClassBase:AddLabel()

		function ClassList:OnSelect(Index, _, Data)
			if self.Selected == Data then return end

			self.ListData.Index = Index
			self.Selected       = Data

			local Density = Data.Density
			local DensityText = language.GetPhrase("acf.menu.fun.armor.stats")

			ClassName:SetText(Data.Name)
			ClassDesc:SetText(Data.Description)
			ClassPreview:UpdateModel("models/holograms/hq_rcube_thin.mdl", "phoenix_storms/metalfloor_2-3")
			ClassPreview:UpdateSettings(PreviewSettings)
			ClassDens:SetText(DensityText:format(Density, math.Round(Density * ACF.gCmToKgIn, 2)))

			ACF.SetClientData("ArmorType", Data.ID)
		end

		SizeX:SetClientData("PlateSizeX", "OnValueChanged")
		SizeX:DefineSetter(function(Panel, _, _, Value)
			local X = math.Round(Value, 2)

			Panel:SetValue(X)

			return X
		end)

		SizeY:SetClientData("PlateSizeY", "OnValueChanged")
		SizeY:DefineSetter(function(Panel, _, _, Value)
			local Y = math.Round(Value, 2)

			Panel:SetValue(Y)

			return Y
		end)

		SizeZ:SetClientData("PlateSizeZ", "OnValueChanged")
		SizeZ:DefineSetter(function(Panel, _, _, Value)
			local Z = math.floor(Value)

			Panel:SetValue(Z)

			return Z
		end)

		ACF.LoadSortedList(ClassList, Entries, "Name")
	end

	ACF.AddMenuItem(2, "#acf.menu.fun", "#acf.menu.fun.armor", "brick", CreateMenu)
end

hook.Add("ACF_OnEnableMenuOption", "Enable Fun Menu", function(Name)
	if Name ~= "#acf.menu.fun" then return end
	if not ACF.GetServerBool("ShowFunMenu") then return false end
end)