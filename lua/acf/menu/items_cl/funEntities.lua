local ACF     = ACF
local Classes = ACF.Classes

do -- Piledrivers menu
	local Piledrivers = Classes.Piledrivers
	local AmmoTypes   = Classes.AmmoTypes
	local Info        = "Mass : %s kg\nRate of Fire : %s rpm\nMax Charges : %s\nRecharge Rate : %s charges/s"
	local Stats       = "Penetration : %s mm RHA\nSpike Velocity : %s m/s\nSpike Length : %s cm\nSpike Mass : %s"
	local Ammo, BulletData

	local function CreateMenu(Menu)
		local Entries  = Piledrivers.GetEntries()
		local AmmoType = AmmoTypes.Get("HP")

		Menu:AddTitle("Piledriver Settings")

		local ClassList = Menu:AddComboBox()
		local Caliber = Menu:AddSlider("Caliber", 0, 1, 2)

		local ClassBase = Menu:AddCollapsible("Piledriver Information")
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

			Caliber:SetMinMax(Min, Max)

			ClassDesc:SetText(Data.Description)

			ClassPreview:UpdateModel(Data.Model)
			ClassPreview:UpdateSettings(Data.Preview)

			ACF.SetClientData("Weapon", Data.ID)
			ACF.SetClientData("Caliber", Current, true)
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

			return Current .. "mm " .. Name
		end)

		ClassInfo:TrackClientData("Weapon", "SetText")
		ClassInfo:TrackClientData("Caliber")
		ClassInfo:DefineSetter(function()
			if not BulletData then return "" end

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

			local MaxPen    = math.Round(BulletData.MaxPen, 2)
			local MuzzleVel = math.Round(BulletData.MuzzleVel, 2)
			local Length    = BulletData.ProjLength
			local Mass      = ACF.GetProperMass(BulletData.ProjMass)

			return Stats:format(MaxPen, MuzzleVel, Length, Mass)
		end)

		ACF.LoadSortedList(ClassList, Entries, "Name")
	end

	ACF.AddMenuItem(1, "Fun Stuff", "Piledrivers", "pencil", CreateMenu)
end

do -- Procedural Armor
	local DensityText = "Density: %sg/cm³ (%skg/in³)"
	local ArmorTypes  = Classes.ArmorTypes

	local function CreateMenu(Menu)
		local Entries = ArmorTypes.GetEntries()

		ACF.SetToolMode("acf_menu", "Spawner", "Component")

		ACF.SetClientData("PrimaryClass", "acf_armor")
		ACF.SetClientData("SecondaryClass", "N/A")

		Menu:AddTitle("Procedural Armor")
		Menu:AddLabel("WARNING: EXPERIMENTAL!\nProcedural Armor is an experimental work in progress and may cause crashes, errors, or just not work properly with all of ACF.\n\nProcedural Armor can be prevented from spawning by setting sbox_max_acf_armor to 0")

		local ClassList = Menu:AddComboBox()
		local SizeX     = Menu:AddSlider("Plate Length (gmu)", 0.25, 420, 2)
		local SizeY     = Menu:AddSlider("Plate Width (gmu)", 0.25, 420, 2)
		local SizeZ     = Menu:AddSlider("Plate Thickness (mm)", 5, 1000)

		local ClassBase = Menu:AddCollapsible("Material Information")
		local ClassName = ClassBase:AddTitle()
		local ClassDesc = ClassBase:AddLabel()
		local ClassDens = ClassBase:AddLabel()

		function ClassList:OnSelect(Index, _, Data)
			if self.Selected == Data then return end

			self.ListData.Index = Index
			self.Selected       = Data

			local Density = Data.Density

			ClassName:SetText(Data.Name)
			ClassDesc:SetText(Data.Description)
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

	ACF.AddMenuItem(2, "Fun Stuff", "Armor", "brick", CreateMenu)
end

hook.Add("ACF_AllowMenuOption", "Allow Fun Menu", function(_, Name)
	if Name ~= "Fun Stuff" then return end
	if not ACF.GetServerBool("ShowFunMenu") then return false end
end)
