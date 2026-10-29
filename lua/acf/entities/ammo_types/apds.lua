local ACF   	= ACF
local Classes   = ACF.Classes

Classes.DefineClass("ACF.Ammunition.APDS", "ACF.Ammunition.AP", function(CLASS, BASE)
	CLASS.Name		 = "Armor Piercing Discarding Sabot"
	CLASS.SpawnIcon   = "acf/icons/shell_apds.png"
	CLASS.Bodygroup   = 3 -- APDS bodygroup index
	CLASS.Description = "#acf.descs.ammo.apds"
	CLASS.Blacklist = ACF.GetWeaponBlacklist({
		["ACF.Guns.Cannon"] = true,
		["ACF.Guns.Autocannon"] = true,
		["ACF.Guns.SemiautomaticCannon"] = true,
		["ACF.Guns.RotaryAutocannon"] = true,
		["ACF.Guns.LightAutocannon"] = true,
	})

	-- Core diameter from 0 (thinnest) to 1 (thickest)
	MENU_FIELD("Number", "CoreScale", {Default = 0.5})

	local MinCoreRatio, MaxCoreRatio = 0.40, 0.58 -- Core over bore diameter, real 0.42 (105mm L28, 2.73kg) to 0.50 (17pdr), War Thunder's British 120mm up to 0.58
	local CoreLengthRatio = 3.3 -- 17pdr core 38 x 127mm, 20pdr 40 x 134mm
	local CoreCarrier     = 0.77 -- Sheath and sabot mass per kg of core, fitted with AnnulusFill to 17pdr (1.74kg core in 3.5kg) and L28 (2.73kg in 5.84kg)
	local AnnulusFill     = 0.12 -- Plus this share of solid steel in the ring between core and bore
	local SheathShare     = 0.43 -- Part of the carrier which flies with the core (17pdr 0.74 of 1.76kg, L28 1.37 of 3.11kg)

	function CLASS:VerifyData()
		BASE.VerifyData(self)

		if not isnumber(self.CoreScale) then self.CoreScale = 0.5 end
	end

	function CLASS:UpdateRoundData()
		local Data    = self.BulletData
		local GUIData = self.GUIData

		ACF.UpdateRoundSpecs(self)

		-- Sheath and sabot mostly scale with the core they hold, a thinner core adds only a little for the wider ring
		local FullBoreArea = math.pi * (Data.Caliber * 0.5) ^ 2

		Data.CoreLength = math.min(CoreLengthRatio * Data.Diameter, Data.ProjLength)
		Data.CoreMass   = Data.ProjArea * Data.CoreLength * ACF.TungstenCarbideDensity

		local RingMass    = (FullBoreArea - Data.ProjArea) * Data.CoreLength * ACF.SteelDensity * AnnulusFill
		local CarrierMass = Data.CoreMass * CoreCarrier + RingMass
		local SabotMass   = CarrierMass * (1 - SheathShare)

		Data.ProjMass = Data.CoreMass + CarrierMass * SheathShare

		Data.MuzzleVel = ACF.MuzzleVelocity(Data.PropMass, Data.ProjMass + SabotMass, Data.Efficiency)
		Data.DragCoef  = Data.ProjArea * 0.000125 / Data.ProjMass -- Worse drag (Manually fudged to make a meaningful difference)
		Data.CartMass  = Data.PropMass + Data.ProjMass + SabotMass

		hook.Run("ACF_OnUpdateRound", self, self, Data, GUIData)

		for K, V in pairs(self:GetDisplayData(Data)) do
			GUIData[K] = V
		end
	end

	function CLASS:BaseConvert()
		-- Mutated in place so the ammo menu preview keeps its reference (see apcr.lua)
		self.BulletData = self.BulletData or {}
		self.BulletData.ProjScale = Lerp(math.Clamp(self.CoreScale or 0.5, 0, 1), MinCoreRatio, MaxCoreRatio)

		local Data = ACF.RoundBaseGunpowder(self) -- Ratio of projectile to gun caliber

		Data.ShovePower = 0.2
		Data.LimitVel   = 950 --Most efficient penetration speed in m/s
		Data.Ricochet   = 80 --Base ricochet angle

		self:UpdateRoundData()

		return self.BulletData, self.GUIData
	end

	-- Shared with the client so the spawn menu can price a crate without spawning it.
	local Conversion = ACF.PointConversion

	function CLASS:GetCost(BulletData)
		local SabotMass	= BulletData.CartMass - BulletData.PropMass - BulletData.ProjMass

		return (BulletData.ProjMass * Conversion.Steel * 6) + (BulletData.PropMass * Conversion.Propellant) + (SabotMass * Conversion.Aluminum)
	end

	if SERVER then
		function CLASS:OnLast(Entity)
			BASE.OnLast(self, Entity)

			Entity.CoreScale = nil
		end

		function CLASS:Network(Entity, BulletData)
			BASE.Network(self, Entity, BulletData)

			Entity:SetNW2String("AmmoType", "ACF.Ammunition.APDS")
		end
	else
		ACF.RegisterAmmoDecal("ACF.Ammunition.APDS", "damage/apcr_pen", "damage/apcr_rico")

		function CLASS:OnCreateAmmoControls(Base)
			-- ProjScale is only read in BaseConvert, so the core diameter needs the full rebuild
			ACF.AmmoMenu.Slider(Base, "#acf.menu.ammo.core_scale", 0, 1, 2, "CoreScale", function(Value)
				self.CoreScale = Value
				self:BaseConvert()
			end)
		end

		-- Ammo menu visual: a carbide core (BulletData.Diameter) riding inside a full-bore sabot that wraps half its length.
		function CLASS:DrawAmmoVisual(Panel, w, h, _, BulletData)
			local GeoPrim = ACF.GeoPrim
			local Margin  = 10
			local DrawW   = w - Margin * 2

			local CoreLength = BulletData.CoreLength or BulletData.ProjLength
			local SabotLenCm = CoreLength * 0.5 -- Illustrative only, UpdateRoundData sizes the sabot by mass
			local Length = CoreLength + BulletData.PropLength -- Projectile length past the core carries nothing, so it isn't drawn

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

			-- Discarding sabot, full bore diameter, only wraps the rear portion of the dart
			local Sabot = GeoPrim.New("Cylinder", { Radius = BulletData.Caliber * 0.5, Height = SabotLenCm })
			Sabot:SetMaterial("Aluminum Sabot (Discarding)")

			-- Carbide core seated on the propellant. Drawn after the sabot at the same starting X so it's the on-top shape.
			local Penetrator = GeoPrim.New("Cylinder", { Radius = BulletData.Diameter * 0.5, Height = CoreLength })
			Penetrator:SetMaterial("Tungsten Core")

			local X = Margin
			X = Propellant:Draw(Panel, X, CenterY, Scale, MaxDia, Color(180, 150, 60), Color(30, 30, 30))
			local DartX = X
			Sabot:Draw(Panel, DartX, CenterY, Scale, MaxDia, Color(150, 150, 155), Color(30, 30, 30))
			Penetrator:Draw(Panel, DartX, CenterY, Scale, MaxDia, Color(120, 120, 130), Color(30, 30, 30))

			-- Tracer, a colored segment at the base of the dart, drawn last (and not as a Dart child --
			-- Draw() paints an entire subtree in one Color, so a child never gets a color of its own) so it
			-- takes hover priority and actually renders red instead of inheriting the penetrator's gray.
			if BulletData.Tracer and BulletData.Tracer > 0 then
				local Tracer = GeoPrim.New("Cylinder", { Radius = BulletData.Diameter * 0.5, Height = BulletData.Tracer })
				Tracer:SetMaterial("Tracer")
				Tracer:Draw(Panel, DartX, CenterY, Scale, MaxDia, Color(220, 40, 30), Color(30, 30, 30))
			end
		end
	end

end)