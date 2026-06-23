local ACF     = ACF
local Classes = ACF.Classes

do -- Piledrivers menu
	local AmmoTypes = Classes.AmmoTypes
	local Ammo, BulletData

	local function CreateMenu(Menu)
		local EntityClassDef = Classes.GetTypeByName("acf_piledriver")
		local WeaponField    = Classes.GetTypeFieldByName(EntityClassDef, "Weapon")
		local Class          = Classes.GetTypeByName(WeaponField.Options.InstantiateTypeForDefault)
		local ClassID        = Classes.GetTypeName(Class)
		local CaliberOpts    = Classes.GetTypeFieldByName(Class, "Caliber").Options
		local AmmoType       = AmmoTypes.Get("ACF.Ammunition.HP")

		Menu:AddTitle("#acf.menu.fun.piledrivers.settings")

		local Caliber = Menu:AddSlider("#acf.menu.caliber", CaliberOpts.Min, CaliberOpts.Max, CaliberOpts.Decimals)

		local ClassBase = Menu:AddCollapsible("#acf.menu.fun.piledrivers.piledriver_info", nil, "icon16/monitor_edit.png")
		local ClassName = ClassBase:AddTitle()
		local ClassDesc = ClassBase:AddLabel()
		local ClassPreview = ClassBase:AddModelPreview(nil, true, "Primary")
		local ClassInfo = ClassBase:AddLabel()
		local ClassStats = ClassBase:AddLabel()

		ACF.SetClientData("PrimaryClass", "acf_piledriver")
		ACF.SetClientData("SecondaryClass", "N/A")
		ACF.SetClientData("Destiny", "Piledrivers")
		ACF.SetClientData("AmmoType", "ACF.Ammunition.HP")
		ACF.SetClientData("Propellant", 0)
		ACF.SetClientData("Tracer", false)

		ACF.SetToolMode("acf_menu", "Spawner", "Weapon")

		Ammo = AmmoType()

		ClassDesc:SetText(Class.Description)
		ClassPreview:UpdateModel(Class.Model)
		ClassPreview:UpdateSettings(Class.Preview)

		Caliber:SetClientData("Caliber", "OnValueChanged")
		Caliber:DefineSetter(function(Panel, _, _, Value)
			local Scale  = Value / Class.BaseCaliber
			local Length = Class.Round.MaxLength * Scale

			Ammo.SpikeLength = Length

			ACF.SetClientData("Projectile", Length)
			-- The entity's "Weapon" field is a nested class instance...
			ACF.SetClientData("Weapon", { Type = ClassID, Data = { Caliber = Value } })

			-- ...but the round pipeline keys off the class name, so the round preview gets a flat tool data.
			BulletData = Ammo:ClientConvert({
				Weapon     = ClassID,
				Caliber    = Value,
				Destiny    = "Piledrivers",
				AmmoType   = "ACF.Ammunition.HP",
				Projectile = Length,
				Propellant = 0,
				Tracer     = false,
			})

			Panel:SetValue(Value)
			ClassPreview:SetModelScale(Scale, true)

			return Value
		end)

		ClassName:TrackClientData("Caliber", "SetText")
		ClassName:DefineSetter(function()
			local Current = math.Round(Caliber:GetValue(), 2)

			return language.GetPhrase("acf.menu.fun.piledrivers.class_name"):format(Current, Class.Name)
		end)

		ClassInfo:TrackClientData("Caliber", "SetText")
		ClassInfo:DefineSetter(function()
			if not BulletData then return "" end

			local Info     = language.GetPhrase("acf.menu.fun.piledrivers.stats")
			local Current  = math.Round(Caliber:GetValue(), 2)
			local Scale    = Current / Class.BaseCaliber
			local Mass     = Class.Mass * Scale
			local FireRate = Class.Cyclic
			local Total    = Class.MagSize
			local Charge   = Class.ChargeRate

			return Info:format(Mass, FireRate, Total, Charge)
		end)

		ClassStats:TrackClientData("Caliber", "SetText")
		ClassStats:DefineSetter(function()
			if not BulletData then return "" end

			local Stats     = language.GetPhrase("acf.menu.fun.piledrivers.damage_stats")
			local MaxPen    = math.Round(BulletData.MaxPen, 2)
			local MuzzleVel = math.Round(BulletData.MuzzleVel, 2)
			local Length    = BulletData.ProjLength
			local Mass      = ACF.GetProperMass(BulletData.ProjMass)

			return Stats:format(MaxPen, MuzzleVel, Length, Mass)
		end)

		Caliber:SetValue(math.Clamp(ACF.GetClientNumber("Caliber", CaliberOpts.Default or CaliberOpts.Min), CaliberOpts.Min, CaliberOpts.Max))
	end

	ACF.AddMenuItem(1, "#acf.menu.fun", "#acf.menu.fun.piledrivers", "pencil", CreateMenu)
end

hook.Add("ACF_OnEnableMenuOption", "Enable Fun Menu", function(Name)
	if Name ~= "#acf.menu.fun" then return end
	if not ACF.GetServerBool("ShowFunMenu") then return false end
end)