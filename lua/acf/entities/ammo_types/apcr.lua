local ACF   	= ACF
local Classes   = ACF.Classes

Classes.DefineClass("ACF.Ammunition.APCR", "ACF.Ammunition.AP", function(CLASS, BASE)
	CLASS.Name		 = "Armor Piercing Composite Rigid"
	CLASS.SpawnIcon   = "acf/icons/shell_apcr.png"
	CLASS.Bodygroup   = 2 -- APCR bodygroup index
	CLASS.Description = "#acf.descs.ammo.apcr"
	CLASS.Blacklist = ACF.GetWeaponBlacklist({
		["ACF.Guns.Cannon"] = true,
		["ACF.Guns.Autocannon"] = true,
		["ACF.Guns.SemiautomaticCannon"] = true,
		["ACF.Guns.ShortBarrelledCannon"] = true,
		["ACF.Guns.LightAutocannon"] = true,
		["ACF.Guns.RotaryAutocannon"] = true,
	})

	-- Core diameter from 0 (thinnest real core) to 1 (thickest); negative keeps the old full-length steel core for existing rounds
	MENU_FIELD("Number", "CoreScale", {Default = -1})

	local MinCoreRatio, MaxCoreRatio = 0.32, 0.531 -- Core over bore diameter, Soviet 85mm BR-365P to 90mm M304
	local CoreLengthRatio = 3.3 -- M93 and M304 cores, same as APDS (German Pzgr.40 ran longer, about 4)
	local CarrierFill     = 0.275 -- Carrier body mass relative to solid steel, fitted to M93 and M304

	function CLASS:VerifyData()
		BASE.VerifyData(self)

		if not isnumber(self.CoreScale) then self.CoreScale = -1 end
	end

	function CLASS:UpdateRoundData()
		local Data    = self.BulletData
		local GUIData = self.GUIData

		ACF.UpdateRoundSpecs(self)

		local DragArea = Data.ProjArea

		if (self.CoreScale or -1) >= 0 then
			-- Carbide core at the tip, launched together with the full-bore carrier around it
			local FullBoreArea = math.pi * (Data.Caliber * 0.5) ^ 2
			local CarrierMass

			Data.CoreLength     = math.min(CoreLengthRatio * Data.Diameter, Data.ProjLength)
			Data.CoreMass       = Data.ProjArea * Data.CoreLength * ACF.TungstenCarbideDensity
			CarrierMass         = (FullBoreArea * Data.ProjLength - Data.ProjArea * Data.CoreLength) * ACF.SteelDensity * CarrierFill
			Data.ProjMass       = Data.CoreMass + CarrierMass
			Data.CoreIsTungsten = true
			DragArea            = FullBoreArea -- The carrier stays on in flight, unlike a sabot
		else
			Data.CoreLength = Data.ProjLength
			Data.CoreMass   = nil
			Data.ProjMass   = Data.ProjArea * Data.ProjLength * ACF.SteelDensity --Volume of the projectile as a cylinder * density of steel (kg/in3)
			Data.CoreIsTungsten = false
		end

		Data.MuzzleVel = ACF.MuzzleVelocity(Data.PropMass, Data.ProjMass, Data.Efficiency)
		Data.DragCoef  = DragArea * 0.0001 / Data.ProjMass
		Data.CartMass  = Data.PropMass + Data.ProjMass

		hook.Run("ACF_OnUpdateRound", self, self, Data, GUIData)

		for K, V in pairs(self:GetDisplayData(Data)) do
			GUIData[K] = V
		end
	end

	function CLASS:BaseConvert()
		-- Mutated in place, not replaced: the ammo menu's preview captures this table once and redraws
		-- from that same reference on every slider change, so swapping in a new table here would leave
		-- the preview watching a stale, orphaned copy while self.BulletData moves on without it.
		local CoreScale = self.CoreScale or -1

		self.BulletData = self.BulletData or {}
		self.BulletData.ProjScale = CoreScale >= 0 and Lerp(math.min(CoreScale, 1), MinCoreRatio, MaxCoreRatio) or 0.75

		local Data = ACF.RoundBaseGunpowder(self) -- APCR has a smaller penetrator

		Data.ShovePower = 0.2
		Data.LimitVel   = 900 --Most efficient penetration speed in m/s
		Data.Ricochet   = 55 --Base ricochet angle

		self:UpdateRoundData()

		return self.BulletData, self.GUIData
	end

	-- Shared with the client so the spawn menu can price a crate without spawning it.
	local Conversion = ACF.PointConversion

	-- Since APCR
	function CLASS:GetCost(BulletData)
		return (BulletData.ProjMass * Conversion.Steel * 2.5) + (BulletData.PropMass * Conversion.Propellant)
	end

	if SERVER then
		function CLASS:OnLast(Entity)
			BASE.OnLast(self, Entity)

			Entity.CoreScale = nil
		end

		function CLASS:Network(Entity, BulletData)
			BASE.Network(self, Entity, BulletData)

			Entity:SetNW2String("AmmoType", "ACF.Ammunition.APCR")
		end
	else
		ACF.RegisterAmmoDecal("ACF.Ammunition.APCR", "damage/apcr_pen", "damage/apcr_rico")

		function CLASS:OnCreateAmmoControls(Base)
			-- The legacy steel core (negative) isn't reachable from the slider, only from old saved data
			ACF.AmmoMenu.Slider(Base, "#acf.menu.ammo.core_scale", 0, 1, 2, "CoreScale", function(Value)
				self.CoreScale = Value
				-- ProjScale (and the ProjArea/Diameter it drives) is only set up in BaseConvert, not
				-- recomputed by UpdateRoundData, so changing it needs the fuller rebuild, not just a refresh.
				self:BaseConvert()
			end)
		end

		-- Ammo menu visual: a subcaliber steel core fused inside a full-bore body for the round's entire length (never discarded, unlike APDS's sabot).
		function CLASS:DrawAmmoVisual(Panel, w, h, _, BulletData)
			local GeoPrim = ACF.GeoPrim
			local Margin  = 10
			local DrawW   = w - Margin * 2

			local Length = BulletData.ProjLength + BulletData.PropLength

			if Length <= 0 then return end

			-- Cap Scale itself by the height budget so every shape shrinks uniformly, not just the radius.
			-- The case, not the bore, is the widest part of a necked round, so it sets the budget.
			local CaseDia = BulletData.CaseDiameter

			if CaseDia <= 0 then return end

			local Scale   = math.min(DrawW / Length, ((h - Margin * 2) * 0.6) / CaseDia)
			local MaxDia  = CaseDia * Scale
			local CenterY = h * 0.5

			local Propellant = GeoPrim.New("Cylinder", { Radius = CaseDia * 0.5, Height = BulletData.PropLength })
			Propellant:SetMaterial("Propellant")

			-- Fused body, full bore diameter, wraps the core's entire length
			local Body = GeoPrim.New("Cylinder", { Radius = BulletData.Caliber * 0.5, Height = BulletData.ProjLength })
			Body:SetMaterial("Steel Body (Fused)")

			-- Core; shorter than the fused body and tungsten when CoreScale is set, flush with the
			-- tip (the end furthest from the propellant, since a real HVAP core sits at the nose). Unset,
			-- it's the old full-length steel-core behavior (UpdateRoundData's ProjMass matches:
			-- SteelDensity over the whole ProjLength), so the label tracks that via CoreIsTungsten rather
			-- than comparing lengths, since a too-thin CoreScale can cap CoreLength back up to ProjLength.
			local CoreLength = BulletData.CoreLength or BulletData.ProjLength
			local Core = GeoPrim.New("Cylinder", { Radius = BulletData.Diameter * 0.5, Height = CoreLength })
			Core:SetMaterial(BulletData.CoreIsTungsten and "Tungsten Core" or "Steel Core")

			local X = Margin
			X = Propellant:Draw(Panel, X, CenterY, Scale, MaxDia, Color(180, 150, 60), Color(30, 30, 30))
			local BodyX = X
			local CoreX = X + (BulletData.ProjLength - CoreLength) * Scale
			Body:Draw(Panel, BodyX, CenterY, Scale, MaxDia, Color(150, 150, 155), Color(30, 30, 30))
			Core:Draw(Panel, CoreX, CenterY, Scale, MaxDia, Color(60, 65, 75), Color(30, 30, 30))

			-- Tracer drawn last (not as a Core child) so it takes hover priority and renders red, not gray.
			if BulletData.Tracer and BulletData.Tracer > 0 then
				local Tracer = GeoPrim.New("Cylinder", { Radius = BulletData.Diameter * 0.5, Height = BulletData.Tracer })
				Tracer:SetMaterial("Tracer")
				Tracer:Draw(Panel, BodyX, CenterY, Scale, MaxDia, Color(220, 40, 30), Color(30, 30, 30))
			end
		end
	end
end)