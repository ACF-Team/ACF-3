local ACF   	= ACF
local Classes   = ACF.Classes

Classes.DefineClass("ACF.Ammunition.FL", "ACF.Ammunition.AP", function()
	local BASE = BASE

	CLASS.Name		     = "Flechette"
	CLASS.SpawnIcon       = "acf/icons/shell_fl.png"
	CLASS.Bodygroup       = 10 -- CANISTER bodygroup index for crate/menu
	CLASS.FlightBodygroup = 4 -- APFSDS bodygroup for flight (dart-shaped flechettes)
	CLASS.Description     = "#acf.descs.ammo.fl"
	CLASS.Blacklist = {
		["ACF.Guns.Autocannon"] = true,
		["ACF.Guns.GrenadeLauncher"] = true,
		["ACF.Guns.Machinegun"] = true,
		["ACF.Guns.Mortar"] = true,
		["ACF.Guns.SemiautomaticCannon"] = true,
		["ACF.Guns.SmokeLauncher"] = true,
		["ACF.Guns.LightAutocannon"] = true,
		["ACF.Guns.RotaryAutocannon"] = true,
	}

	MENU_FIELD("Number", "Flechettes", {Default = 0})
	MENU_FIELD("Number", "Spread", {Default = 0})

	-- Packing function to get the rough caliber of a flechette
	-- based on the caliber of the full round and the amount of them
	function CLASS:GetFlechetteCaliber(Caliber, Count)
		return (0.95231 * Caliber * 0.5 / Count ^ 0.5) * 2
	end

	function CLASS:GetPenetration(Bullet, Speed)
		if not isnumber(Speed) then
			Speed = Bullet.Flight and Bullet.Flight:Length() / ACF.Scale * ACF.InchToMeter or Bullet.MuzzleVel
		end

		return ACF.Penetration(Speed, Bullet.FlechetteMass, Bullet.FlechetteCaliber * 10)
	end

	function CLASS:GetDisplayData(Data)
		local Display = {
			MaxPen = self:GetPenetration(Data, Data.MuzzleVel)
		}

		hook.Run("ACF_OnRequestDisplayData", self, Data, Display)

		return Display
	end

	function CLASS:UpdateRoundData(ToolData, Data, GUIData)
		GUIData = GUIData or Data

		ACF.UpdateRoundSpecs(ToolData, Data, GUIData)

		local Flechettes = math.Clamp(ToolData.Flechettes, Data.MinFlechettes, Data.MaxFlechettes)

		Data.Flechettes		   = Flechettes
		Data.FlechetteSpread   = math.Clamp(ToolData.Spread, Data.MinSpread, Data.MaxSpread)
		Data.FlechetteCaliber  = self:GetFlechetteCaliber(Data.Caliber, Flechettes)
		Data.FlechetteArea	   = math.pi * (Data.FlechetteCaliber * 0.5) ^ 2 -- area of a single flechette
		Data.FlechetteMass	   = Data.FlechetteArea * Data.ProjLength * ACF.SteelDensity -- volume of single flechette * density of steel
		Data.FlechetteDragCoef = Data.FlechetteArea * 0.0001 / Data.FlechetteMass
		Data.ProjMass		   = Flechettes * Data.FlechetteMass -- total mass of all flechettes
		Data.DragCoef		   = Data.ProjArea * 0.0001 / Data.ProjMass
		Data.MuzzleVel		   = ACF.MuzzleVelocity(Data.PropMass, Data.ProjMass, Data.Efficiency)
		Data.CartMass		   = Data.PropMass + Data.ProjMass

		hook.Run("ACF_OnUpdateRound", self, ToolData, Data, GUIData)

		for K, V in pairs(self:GetDisplayData(Data)) do
			GUIData[K] = V
		end
	end

	function CLASS:BaseConvert(ToolData)
		local Data, GUIData = ACF.RoundBaseGunpowder(ToolData, { LengthAdj = 0.5 })

		Data.MaxFlechettes = math.Clamp(math.floor(Data.Caliber * 4), 12, 64)
		Data.MinFlechettes = math.min(12, Data.MaxFlechettes) --force bigger guns to have higher min count
		Data.MinSpread	   = 0.2
		Data.MaxSpread	   = 10
		Data.ShovePower	   = 0.2
		Data.LimitVel	   = 500 --Most efficient penetration speed in m/s
		Data.Ricochet	   = 75 --Base ricochet angle

		self:UpdateRoundData(ToolData, Data, GUIData)

		return Data, GUIData
	end

	function CLASS:VerifyData(ToolData)
		BASE.VerifyData(self, ToolData)

		if not isnumber(ToolData.Flechettes) then
			ToolData.Flechettes = ACF.CheckNumber(ToolData.RoundData5, 0)
		end

		if not isnumber(ToolData.Spread) then
			ToolData.Spread = ACF.CheckNumber(ToolData.RoundData6, 0)
		end
	end

	if SERVER then
		local Ballistics = ACF.Ballistics
		local Conversion	= ACF.PointConversion

		function CLASS:GetCost(BulletData)
			return (BulletData.ProjMass * Conversion.Steel) + (BulletData.PropMass * Conversion.Propellant)
		end

		function CLASS:OnLast(Entity)
			BASE.OnLast(self, Entity)

			Entity.Flechettes = nil
			Entity.Spread = nil

			-- Cleanup the leftovers aswell
			Entity.RoundData5 = nil
			Entity.RoundData6 = nil
		end

		function CLASS:Create(Gun, BulletData)
			local Caliber = math.Round(BulletData.FlechetteCaliber, 2)

			local FlechetteData = {
				Caliber    = Caliber,
				Diameter   = Caliber,
				WeaponType = BulletData.WeaponType,
				AmmoType   = "ACF.Ammunition.AP",
				Owner      = BulletData.Owner,
				Entity     = BulletData.Entity,
				Crate      = BulletData.Crate,
				Gun        = BulletData.Gun,
				Pos        = BulletData.Pos,
				ProjArea   = BulletData.FlechetteArea,
				ProjMass   = BulletData.FlechetteMass,
				DragCoef   = BulletData.FlechetteDragCoef,
				Tracer     = BulletData.Tracer,
				LimitVel   = BulletData.LimitVel,
				Ricochet   = BulletData.Ricochet,
				ShovePower = BulletData.ShovePower,
			}

			--if ammo is cooking off, shoot in random direction
			if Gun:GetClass() == "acf_ammo" then
				local MuzzleVec = VectorRand()

				for _ = 1, BulletData.Flechettes do
					local Inaccuracy = VectorRand() / 360 * ((Gun.Spread or 0) + BulletData.FlechetteSpread)

					FlechetteData.Flight = (MuzzleVec + Inaccuracy):GetNormalized() * BulletData.MuzzleVel * ACF.MeterToInch + Gun:GetVelocity()

					Ballistics.CreateBullet(FlechetteData)
				end
			else
				local BaseInaccuracy = math.tan(math.rad(Gun:GetSpread()))
				local AddInaccuracy	 = math.tan(math.rad(BulletData.FlechetteSpread))
				local MuzzleVec		 = Gun:GetForward()

				for _ = 1, BulletData.Flechettes do
					local GunUp, GunRight	 = Gun:GetUp(), Gun:GetRight()
					local BaseInaccuracyMult = math.random() ^ (1 / math.Clamp(ACF.GunInaccuracyBias, 0.5, 4)) * (GunUp * (2 * math.random() - 1) + GunRight * (2 * math.random() - 1)):GetNormalized()
					local AddSpreadMult		 = math.random() ^ (1 / math.Clamp(ACF.GunInaccuracyBias, 0.5, 4)) * (GunUp * (2 * math.random() - 1) + GunRight * (2 * math.random() - 1)):GetNormalized()

					local BaseSpread = BaseInaccuracy * BaseInaccuracyMult
					local AddSpread  = AddInaccuracy * AddSpreadMult

					FlechetteData.Flight = (MuzzleVec + BaseSpread + AddSpread):GetNormalized() * BulletData.MuzzleVel * ACF.MeterToInch + Gun:GetVelocity()

					Ballistics.CreateBullet(FlechetteData)
				end
			end
		end

		function CLASS:Network(Entity, BulletData)
			BASE.Network(self, Entity, BulletData)

			local FlechetteCaliber = math.Round(BulletData.FlechetteCaliber, 2)

			Entity:SetNW2String("AmmoType", "ACF.Ammunition.FL")
			Entity:SetNW2Float("Caliber", FlechetteCaliber)
			Entity:SetNW2Float("ProjMass", BulletData.FlechetteMass)
			Entity:SetNW2Float("DragCoef", BulletData.FlechetteDragCoef)
		end

		function CLASS:UpdateCrateOverlay(BulletData, State)
			local Data	  = self:GetDisplayData(BulletData)
			local Class   = Classes.GetSubtypeByName("ACF.Weapons.BaseWeapon", BulletData.WeaponType)
			local Spread  = Class and Class.Spread * ACF.GunInaccuracyScale or 0

			State:AddNumber("Muzzle Velocity", BulletData.MuzzleVel, " m/s")
			State:AddNumber("Flechette Count", BulletData.Flechettes)
			State:AddNumber("Flechette Mass", math.Round(BulletData.FlechetteMass * 1000, 2), " g")
			State:AddNumber("Flechette Caliber", math.Round(BulletData.FlechetteCaliber, 2), " mm")
			State:AddNumber("Max Penetration", Data.MaxPen, " mm")
			State:AddNumber("Max Spread", BulletData.FlechetteSpread + Spread, " degrees")
		end
	else
		ACF.RegisterAmmoDecal("ACF.Ammunition.FL", "damage/ap_pen", "damage/ap_rico")

		function CLASS:GetRangedPenetration(Bullet, Range)
			local Speed = ACF.GetRangedSpeed(Bullet.MuzzleVel, Bullet.FlechetteDragCoef, Range) * ACF.InchToMeter

			return math.Round(self:GetPenetration(Bullet, Speed), 2), math.Round(Speed, 2)
		end

		function CLASS:OnCreateAmmoControls(Base, ToolData, BulletData)
			local Flechettes = Base:AddSlider("#acf.menu.ammo.flechette_amount", BulletData.MinFlechettes, BulletData.MaxFlechettes)
			Flechettes:SetClientData("Flechettes", "OnValueChanged")
			Flechettes:DefineSetter(function(Panel, _, _, Value)
				ToolData.Flechettes = math.floor(Value)

				Ammo:UpdateRoundData(ToolData, BulletData)

				Panel:SetValue(BulletData.Flechettes)

				return BulletData.Flechettes
			end)

			local Spread = Base:AddSlider("#acf.menu.ammo.flechette_spread", BulletData.MinSpread, BulletData.MaxSpread, 2)
			Spread:SetClientData("Spread", "OnValueChanged")
			Spread:DefineSetter(function(Panel, _, _, Value)
				ToolData.Spread = Value

				Ammo:UpdateRoundData(ToolData, BulletData)

				Panel:SetValue(BulletData.FlechetteSpread)

				return BulletData.FlechetteSpread
			end)
		end

		function CLASS:OnCreateCrateInformation(Base, Label, ...)
			BASE.OnCreateCrateInformation(self, Base, Label, ...)

			Label:TrackClientData("Flechettes")
		end

		function CLASS:OnCreateAmmoInformation(Menu, ToolData, BulletData)
			local RoundStats = Menu:AddLabel()
			RoundStats:TrackClientData("Projectile", "SetText")
			RoundStats:TrackClientData("Propellant")
			RoundStats:TrackClientData("Flechettes")
			RoundStats:DefineSetter(function()
				self:UpdateRoundData(ToolData, BulletData)

				local Text		= language.GetPhrase("acf.menu.ammo.round_stats_fl")
				local MuzzleVel	= math.Round(BulletData.MuzzleVel * ACF.Scale, 2)
				local ProjMass	= ACF.GetProperMass(BulletData.ProjMass)
				local PropMass	= ACF.GetProperMass(BulletData.PropMass)
				local FLMass	= ACF.GetProperMass(BulletData.FlechetteMass)

				return Text:format(MuzzleVel, ProjMass, PropMass, FLMass)
			end)

			local PenStats = Menu:AddLabel()
			PenStats:TrackClientData("Projectile", "SetText")
			PenStats:TrackClientData("Propellant")
			PenStats:TrackClientData("Flechettes")
			PenStats:DefineSetter(function()
				self:UpdateRoundData(ToolData, BulletData)

				local Text	   = language.GetPhrase("acf.menu.ammo.pen_stats_ap")
				local MaxPen   = math.Round(BulletData.MaxPen, 2)
				local R1P, R1V = self:GetRangedPenetration(BulletData, 300)
				local R2V, R2P = self:GetRangedPenetration(BulletData, 800)

				return Text:format(MaxPen, R1P, R1V, R2P, R2V)
			end)
		end
	end
end)