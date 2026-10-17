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

	function CLASS:UpdateRoundData()
		local Data    = self.BulletData
		local GUIData = self.GUIData

		ACF.UpdateRoundSpecs(self)

		Data.ProjMass  = Data.ProjArea * Data.ProjLength * ACF.SteelDensity --Volume of the projectile as a cylinder * density of steel (kg/in3)
		Data.MuzzleVel = ACF.MuzzleVelocity(Data.PropMass, Data.ProjMass, Data.Efficiency)
		Data.DragCoef  = Data.ProjArea * 0.0001 / Data.ProjMass
		Data.CartMass  = Data.PropMass + Data.ProjMass

		hook.Run("ACF_OnUpdateRound", self, self, Data, GUIData)

		for K, V in pairs(self:GetDisplayData(Data)) do
			GUIData[K] = V
		end
	end

	function CLASS:BaseConvert()
		self.BulletData = { ProjScale = 0.75 }

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



		function CLASS:Network(Entity, BulletData)
			BASE.Network(self, Entity, BulletData)

			Entity:SetNW2String("AmmoType", "ACF.Ammunition.APCR")
		end
	else
		ACF.RegisterAmmoDecal("ACF.Ammunition.APCR", "damage/apcr_pen", "damage/apcr_rico")

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

			-- Steel core, drawn after the body at the same starting X so it's the on-top shape.
			local Core = GeoPrim.New("Cylinder", { Radius = BulletData.Diameter * 0.5, Height = BulletData.ProjLength })
			Core:SetMaterial("Steel Core")

			local X = Margin
			X = Propellant:Draw(Panel, X, CenterY, Scale, MaxDia, Color(180, 150, 60), Color(30, 30, 30))
			local CoreX = X
			Body:Draw(Panel, X, CenterY, Scale, MaxDia, Color(150, 150, 155), Color(30, 30, 30))
			Core:Draw(Panel, CoreX, CenterY, Scale, MaxDia, Color(120, 120, 130), Color(30, 30, 30))

			-- Tracer drawn last (not as a Core child) so it takes hover priority and renders red, not gray.
			if BulletData.Tracer and BulletData.Tracer > 0 then
				local Tracer = GeoPrim.New("Cylinder", { Radius = BulletData.Diameter * 0.5, Height = BulletData.Tracer })
				Tracer:SetMaterial("Tracer")
				Tracer:Draw(Panel, CoreX, CenterY, Scale, MaxDia, Color(220, 40, 30), Color(30, 30, 30))
			end
		end
	end
end)