local ACF       = ACF
local Classes   = ACF.Classes

Classes.DefineClass("ACF.Ammunition.SM", "ACF.Ammunition.AP", function(CLASS, BASE)
	CLASS.Name		 = "Smoke"
	CLASS.SpawnIcon   = "acf/icons/shell_smoke.png"
	CLASS.Bodygroup   = 6 -- WP bodygroup index
	CLASS.MortarBodygroup = 1 -- Smoke mortar submodel
	CLASS.Description = "#acf.descs.ammo.sm"
	CLASS.Blacklist = {
		["ACF.Guns.Autocannon"] = true,
		["ACF.Guns.GrenadeLauncher"] = true,
		["ACF.Guns.Machinegun"] = true,
		["ACF.Guns.SemiautomaticCannon"] = true,
		["ACF.Guns.LightAutocannon"] = true,
		["ACF.Guns.RotaryAutocannon"] = true,
	}

	MENU_FIELD("Number", "FillerRatio", {Default = 0})
	MENU_FIELD("Number", "SmokeWPRatio", {Default = 0})

	function CLASS:GetPenetration()
		return 0
	end

	function CLASS:GetDisplayData(Data)
		local SMFiller = math.min(math.log(1 + Data.FillerMass * 8 * ACF.MeterToInch) * 43.4216, 350)
		local WPFiller = math.min(math.log(1 + Data.WPMass * 8 * ACF.MeterToInch) * 43.4216, 350)
		local Display  = {
			SMFiller    = SMFiller,
			SMLife      = math.Round(10 + SMFiller * 0.25, 2),
			SMRadiusMin = math.Round(SMFiller * 1.25 * 0.15 * ACF.InchToMeter, 2),
			SMRadiusMax = math.Round(SMFiller * 1.25 * 2 * ACF.InchToMeter, 2),
			WPFiller    = WPFiller,
			WPLife      = math.Round(5 + WPFiller * 0.1, 2),
			WPRadiusMin = math.Round(WPFiller * 1.25 * ACF.InchToMeter, 2),
			WPRadiusMax = math.Round(WPFiller * 1.25 * 2 * ACF.InchToMeter, 2),
		}

		hook.Run("ACF_OnRequestDisplayData", self, Data, Display)

		return Display
	end

	function CLASS:UpdateRoundData()
		local Data    = self.BulletData
		local GUIData = self.GUIData

		ACF.UpdateRoundSpecs(self)

		Data.FillerPriority = Data.FillerPriority or "Smoke"

		-- Volume of the projectile as a cylinder - Volume of the filler * density of steel + Volume of the filler * density of TNT
		local FreeVol     = ACF.RoundShellCapacity(Data.PropMass, Data.ProjArea, Data.Caliber, Data.ProjLength)
		local FillerVol   = FreeVol * math.Clamp(self.FillerRatio, 0, 1)
		local SmokeRatio  = math.Clamp(self.SmokeWPRatio, 0, 1)
		local SmokeFiller = FillerVol * SmokeRatio
		local WPFiller    = FillerVol * (1 - SmokeRatio)

		Data.FillerMass = SmokeFiller * ACF.HEDensity
		Data.WPMass     = WPFiller * ACF.HEDensity
		Data.ProjMass   = math.max(GUIData.ProjVolume - FillerVol, 0) * ACF.SteelDensity + Data.FillerMass + Data.WPMass
		Data.MuzzleVel  = ACF.MuzzleVelocity(Data.PropMass, Data.ProjMass, Data.Efficiency)
		Data.DragCoef   = Data.ProjArea * 0.0001 / Data.ProjMass
		Data.CartMass   = Data.PropMass + Data.ProjMass

		hook.Run("ACF_OnUpdateRound", self, self, Data, GUIData)

		for K, V in pairs(self:GetDisplayData(Data)) do
			GUIData[K] = V
		end
	end

	function CLASS:BaseConvert()
		self.BulletData = {}

		local Data = ACF.RoundBaseGunpowder(self)

		self.GUIData.MinFillerVol = 0

		Data.ShovePower		= 0.1
		Data.LimitVel		= 100 --Most efficient penetration speed in m/s
		Data.Ricochet		= 60 --Base ricochet angle
		Data.DetonatorAngle	= 80
		Data.CanFuze		= Data.Caliber * 10 >= ACF.MinFuzeCaliber -- Can fuze on calibers >= 25mm

		self:UpdateRoundData()

		return self.BulletData, self.GUIData
	end

	function CLASS:VerifyData()
		BASE.VerifyData(self)

		if not isnumber(self.FillerRatio) then self.FillerRatio = 1 end
		if not isnumber(self.SmokeWPRatio) then self.SmokeWPRatio = 0.5 end
	end

	-- Shared with the client so the spawn menu can price a crate without spawning it.
	local Conversion = ACF.PointConversion

	function CLASS:GetCost(BulletData)
		return ((BulletData.ProjMass - BulletData.FillerMass - BulletData.WPMass) * Conversion.Steel * 0.75) + (BulletData.PropMass * Conversion.Propellant) + (BulletData.FillerMass * Conversion.SF) + (BulletData.WPMass * Conversion.WP)
	end

	if SERVER then
		local Ballistics = ACF.Ballistics



		function CLASS:OnLast(Entity)
			BASE.OnLast(self, Entity)

			Entity.FillerRatio  = nil
			Entity.SmokeWPRatio = nil

			-- Cleanup the leftovers aswell
			Entity.SmokeFiller = nil
			Entity.WPFiller    = nil
			Entity.RoundData5  = nil
			Entity.RoundData6  = nil

			Entity:SetNW2Float("FillerMass", 0)
			Entity:SetNW2Float("WPMass", 0)
		end

		function CLASS:Network(Entity, BulletData)
			BASE.Network(self, Entity, BulletData)

			Entity:SetNW2String("AmmoType", "ACF.Ammunition.SM")
			Entity:SetNW2Float("FillerMass", BulletData.FillerMass)
			Entity:SetNW2Float("WPMass", BulletData.WPMass)
		end

		function CLASS:UpdateCrateOverlay(BulletData, State)
			local Data = self:GetDisplayData(BulletData)

			State:AddNumber("Muzzle Velocity", BulletData.MuzzleVel, " m/s")
			if Data.WPFiller > 0 then
				State:AddKeyValue("WP Radius", ("%s m to %s m"):format(Data.WPRadiusMin, Data.WPRadiusMax))
				State:AddKeyValue("WP Lifetime", ("%s s"):format(Data.WPLife))
			end
			if Data.SMFiller > 0 then
				State:AddKeyValue("SM Radius", ("%s m to %s m"):format(Data.SMRadiusMin, Data.SMRadiusMax))
				State:AddKeyValue("SM Lifetime", ("%s s"):format(Data.SMLife))
			end
		end

		function CLASS:PropImpact(Bullet, Trace)
			if ACF.Check(Trace.Entity) then
				local Speed  = Bullet.Flight:Length() / ACF.Scale
				local Energy = ACF.Kinetic(Speed, Bullet.ProjMass)

				Bullet.Speed  = Speed
				Bullet.Energy = Energy

				local HitRes = Ballistics.DoRoundImpact(Bullet, Trace)

				if HitRes.Ricochet then return "Ricochet" end
			end

			return false
		end

		function CLASS:WorldImpact()
			return false
		end
	else
		local Effects = ACF.Utilities.Effects

		ACF.RegisterAmmoDecal("ACF.Ammunition.SM", "damage/he_pen", "damage/he_rico")

		function CLASS:ImpactEffect(_, Bullet)
			local Crate = Bullet.Crate
			local Color = IsValid(Crate) and Crate:GetColor() or Color(255, 255, 255)

			local EffectTable = {
				Origin = Bullet.SimPos,
				Normal = Bullet.SimFlight:GetNormalized(),
				Scale = math.max(Bullet.FillerMass * 8 * ACF.MeterToInch, 0),
				Magnitude = math.max(Bullet.WPMass * 8 * ACF.MeterToInch, 0),
				Start = Vector(Color.r, Color.g, Color.b),
				Radius = Bullet.Caliber,
			}

			Effects.CreateEffect("ACF_Smoke", EffectTable)
		end

		function CLASS:OnCreateAmmoControls(Base)
			ACF.AmmoMenu.Slider(Base, "#acf.menu.ammo.filler_ratio", 0, 1, 2, "FillerRatio", function(Value)
				self.FillerRatio = math.Round(Value, 2)
				self:UpdateRoundData()
			end)

			ACF.AmmoMenu.Slider(Base, "#acf.menu.ammo.wp_ratio", 0, 1, 2, "SmokeWPRatio", function(Value)
				self.SmokeWPRatio = math.Round(Value, 2)
				self:UpdateRoundData()
			end)
		end

		function CLASS:OnCreateAmmoInformation(Menu, _, Data)
			local RoundStats = Menu:AddLabel()
			ACF.AmmoMenu.Reactive(RoundStats, function()
				self:UpdateRoundData()

				local Text		= language.GetPhrase("acf.menu.ammo.round_stats_ap")
				local MuzzleVel	= math.Round(Data.MuzzleVel * ACF.Scale, 2)
				local ProjMass	= ACF.FormatMass(Data.ProjMass)
				local PropMass	= ACF.FormatMass(Data.PropMass)

				RoundStats:SetText(Text:format(MuzzleVel, ProjMass, PropMass))
			end)

			local SmokeStats = Menu:AddLabel()
			ACF.AmmoMenu.Reactive(SmokeStats, function()
				self:UpdateRoundData()

				local SMText, WPText = "", ""

				-- The smoke/WP radius + life live on GUIData (see the ballistics graph), not BulletData.
				local GUIData = self.GUIData

				if Data.FillerMass > 0 then
					local Text		  = language.GetPhrase("acf.menu.ammo.smoke_stats")
					local SmokeMass	  = ACF.FormatMass(Data.FillerMass)
					local SmokeRadius = ((GUIData.SMRadiusMin or 0) + (GUIData.SMRadiusMax or 0)) * 0.5

					SMText = Text:format(SmokeMass, SmokeRadius, GUIData.SMLife or 0)
				end

				if Data.WPMass > 0 then
					local Text	   = language.GetPhrase("acf.menu.ammo.wp_stats")
					local WPMass   = ACF.FormatMass(Data.WPMass)
					local WPRadius = ((GUIData.WPRadiusMin or 0) + (GUIData.WPRadiusMax or 0)) * 0.5

					WPText = Text:format(WPMass, WPRadius, GUIData.WPLife or 0)
				end

				SmokeStats:SetText(SMText .. WPText)
			end)
		end

		-- Ammo menu visual: casing plus a body split between the smoke/WP chemical filler and the steel
		-- shell wall around it, matching the mass split in UpdateRoundData (ProjVolume - FillerVol is
		-- steel, the rest filler, further divided between smoke and WP by SmokeWPRatio).
		function CLASS:DrawAmmoVisual(Panel, w, h, ToolData, BulletData)
			local GeoPrim  = ACF.GeoPrim
			local Margin   = 10
			local DrawW    = w - Margin * 2
			local Diameter = BulletData.Diameter or BulletData.Caliber
			local Radius   = Diameter * 0.5

			local Length = BulletData.ProjLength + BulletData.PropLength

			if Length <= 0 then return end

			-- Cap Scale by the case, the widest part, so the case/bore step survives the height budget
			local CaseDia = BulletData.CaseDiameter

			if CaseDia <= 0 then return end

			local Scale      = math.min(DrawW / Length, ((h - Margin * 2) * 0.6) / CaseDia)
			local DiameterPx = CaseDia * Scale
			local CenterY    = h * 0.5

			local FillerRatio = math.Clamp(ToolData.FillerRatio or 0, 0, 1)
			local SmokeRatio  = math.Clamp(ToolData.SmokeWPRatio or 0.5, 0, 1)
			local FillerLenCm = BulletData.ProjLength * FillerRatio
			local SmokeLenCm  = FillerLenCm * SmokeRatio
			local WPLenCm     = FillerLenCm - SmokeLenCm
			local SteelLenCm  = BulletData.ProjLength - FillerLenCm

			local Propellant = GeoPrim.New("Cylinder", { Radius = CaseDia * 0.5, Height = BulletData.PropLength })
			Propellant:SetMaterial("Propellant")

			local Smoke = GeoPrim.New("Cylinder", { Radius = Radius, Height = SmokeLenCm })
			Smoke:SetMaterial("Smoke Filler (HC)")

			local WP = GeoPrim.New("Cylinder", { Radius = Radius, Height = WPLenCm })
			WP:SetMaterial("White Phosphorus Filler")

			local ShellCasing = GeoPrim.New("Cylinder", { Radius = Radius, Height = SteelLenCm })
			ShellCasing:SetMaterial("Steel Shell Casing")

			local X = Margin
			X = Propellant:Draw(Panel, X, CenterY, Scale, DiameterPx, Color(180, 150, 60), Color(30, 30, 30))
			local BodyStartX = X

			if SmokeLenCm > 0 then
				X = Smoke:Draw(Panel, X, CenterY, Scale, DiameterPx, Color(190, 190, 195), Color(30, 30, 30))
			end
			if WPLenCm > 0 then
				X = WP:Draw(Panel, X, CenterY, Scale, DiameterPx, Color(235, 220, 120), Color(30, 30, 30))
			end
			ShellCasing:Draw(Panel, X, CenterY, Scale, DiameterPx, Color(120, 120, 130), Color(30, 30, 30))

			-- Tracer, a colored segment at the very base of the body (against the casing), drawn last
			-- so it takes hover priority over whatever filler/steel material happens to sit underneath it
			if BulletData.Tracer and BulletData.Tracer > 0 then
				local Tracer = GeoPrim.New("Cylinder", { Radius = Radius, Height = math.max(BulletData.Tracer, 2 / Scale) })
				Tracer:SetMaterial("Tracer")
				Tracer:Draw(Panel, BodyStartX, CenterY, Scale, DiameterPx, Color(220, 40, 30), Color(30, 30, 30))
			end
		end

		-- Ammo menu graph: smoke and WP cloud radius over time.
		function CLASS:PlotAmmoGraph(Panel)
			local Colors = ACF.GraphColors

			Panel:SetYLabel("#acf.menu.ammo.smoke_radius")
			Panel:SetXLabel("#acf.menu.ammo.time")

			Panel:SetYSpacing(10)
			Panel:SetXSpacing(5)

			-- Smoke timings and radii are display data, so they live on GUIData rather than the bullet
			local GUIData = self.GUIData

			local WPTime = GUIData.WPLife or 0
			local SFTime = GUIData.SMLife or 0

			local MinWP = GUIData.WPRadiusMin or 0
			local MaxWP = GUIData.WPRadiusMax or 0

			local MinSF = GUIData.SMRadiusMin or 0
			local MaxSF = GUIData.SMRadiusMax or 0

			Panel:SetXRange(0, math.max(WPTime, SFTime) * 1.1)
			Panel:SetYRange(0, math.max(MaxWP, MaxSF) * 1.1)

			if WPTime > 0 then
				Panel:PlotLimitFunction(language.GetPhrase("acf.menu.ammo.wp_filler"), 0, WPTime, Colors.Blue, function(X)
					return Lerp(X / WPTime, MinWP, MaxWP)
				end)

				Panel:PlotPoint(language.GetPhrase("acf.menu.ammo.wp_max_radius"), WPTime, MaxWP, Colors.Blue)
			end

			if SFTime > 0 then
				Panel:PlotLimitFunction(language.GetPhrase("acf.menu.ammo.smoke_filler"), 0, SFTime, Colors.Red, function(X)
					return Lerp(X / SFTime, MinSF, MaxSF)
				end)

				Panel:PlotPoint(language.GetPhrase("acf.menu.ammo.smoke_max_radius"), SFTime, MaxSF, Colors.Red)
			end
		end
	end
end)