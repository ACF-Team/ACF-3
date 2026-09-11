local ACF   	= ACF
local Classes   = ACF.Classes

Classes.DefineClass("ACF.Ammunition.APFSDS", "ACF.Ammunition.AP", function(CLASS, BASE)
	CLASS.Name		 = "Armor Piercing Fin Stabilized"
	CLASS.SpawnIcon   = "acf/icons/shell_apfsds.png"
	CLASS.Bodygroup   = 4 -- APFSDS bodygroup index
	CLASS.Description = "#acf.descs.ammo.apfsds"
	-- Only this type lets the rod bore back into the propellant, gating TelescopeRatio in UpdateRoundSpecs
	CLASS.CanTelescope = true

	MENU_FIELD("Number", "TelescopeRatio", {Default = 0})

	CLASS.Blacklist = ACF.GetWeaponBlacklist({
		["ACF.Guns.Cannon"] = true,
		["ACF.Guns.Autocannon"] = true,
		["ACF.Guns.SemiautomaticCannon"] = true,
		["ACF.Guns.ShortBarrelledCannon"] = true,
	})

	-- Long rod penetrators are different, so we'll use Lanz Odermatt Penetration Equation with them
	-- See: http://www.longrods.ch/perfeq.php
	-- Speed is on m/s
	-- Returns penetration in mm
	-- NOTE: This assume we're hitting a RHA plate at 0°
	function CLASS:GetPenetration(Bullet, Speed)
		if not isnumber(Speed) then
			Speed = Bullet.Flight and Bullet.Flight:Length() / ACF.Scale * ACF.InchToMeter or Bullet.MuzzleVel
		end

		Speed = Speed * 0.001 -- From m/s to km/s

		local RoundLength   = Bullet.ProjLength * 10 -- From cm to mm
		local RoundCaliber  = Bullet.Diameter * 10 -- From cm to mm
		local RoundBrinell  = 294
		local RoundDensity  = 19250 -- in kg/m3
		local TargetBrinell = 237 -- Assuming we're hitting RHA
		local TargetDensity = 7840 -- Assuming we're hitting RHA
		local Constant      = 1.104 -- Steel specific constant
		local S2            = 9874 * TargetBrinell ^ 0.3598 * RoundBrinell ^ -0.2342 / RoundDensity

		local FirstChunk    = 1 / math.tanh(0.283 + 0.0656 * RoundLength / RoundCaliber)
		local SecondChunk   = (RoundDensity / TargetDensity) ^ 0.5
		local ThirdChunk    = math.exp(-S2 / (Speed * Speed))

		return Constant * FirstChunk * SecondChunk * ThirdChunk * RoundLength
	end

	-- Inverse of the Lanz-Odermatt equation above, solved for Speed (Penetration in mm, returns speed in m/s)
	function CLASS:CalcSpeed(Bullet, Penetration)
		local RoundLength   = Bullet.ProjLength * 10 -- From cm to mm
		local RoundCaliber  = Bullet.Diameter * 10 -- From cm to mm
		local RoundBrinell  = 294
		local RoundDensity  = 19250 -- in kg/m3
		local TargetBrinell = 237 -- Assuming we're hitting RHA
		local TargetDensity = 7840 -- Assuming we're hitting RHA
		local Constant      = 1.104 -- Steel specific constant
		local S2            = 9874 * TargetBrinell ^ 0.3598 * RoundBrinell ^ -0.2342 / RoundDensity

		local FirstChunk  = 1 / math.tanh(0.283 + 0.0656 * RoundLength / RoundCaliber)
		local SecondChunk = (RoundDensity / TargetDensity) ^ 0.5
		local MaxPen      = Constant * FirstChunk * SecondChunk * RoundLength -- Asymptotic penetration as Speed -> infinity

		if Penetration <= 0 then return 0 end

		local Speed = (S2 / math.log(MaxPen / math.min(Penetration, MaxPen * 0.999999))) ^ 0.5 -- In km/s

		return Speed * 1000 -- From km/s to m/s
	end

	function CLASS:UpdateRoundData()
		local Data    = self.BulletData
		local GUIData = self.GUIData

		ACF.UpdateRoundSpecs(self)

		local Cylinder  = (math.pi * (Data.Caliber * 0.5) ^ 2) * Data.ProjLength * 0.25 -- A cylinder 1/4 the length of the projectile
		local Hole		= Data.ProjArea * Data.ProjLength * 0.25 -- Volume removed by the hole the dart passes through
		local SabotMass = (Cylinder - Hole) * ACF.AluminumDensity -- A cylinder with a hole the size of the dart in it and im no math wizard so we're just going to take off 3/4 of the mass for the cutout since sabots are shaped like this: ][

		Data.ProjMass  = Data.ProjArea * Data.ProjLength * ACF.TungstenDensity -- Volume of the projectile as a cylinder * density of steel
		Data.MuzzleVel = ACF.MuzzleVelocity(Data.PropMass, Data.ProjMass + SabotMass, Data.Efficiency)
		Data.DragCoef  = Data.ProjArea * 0.0001 / Data.ProjMass
		Data.CartMass  = Data.PropMass + Data.ProjMass + SabotMass

		hook.Run("ACF_OnUpdateRound", self, self, Data, GUIData)

		for K, V in pairs(self:GetDisplayData(Data)) do
			GUIData[K] = V
		end
	end

	function CLASS:VerifyData()
		BASE.VerifyData(self)

		if not isnumber(self.TelescopeRatio) then
			self.TelescopeRatio = 0
		end
	end

	function CLASS:BaseConvert()
		self.BulletData = { ProjScale = 0.35 }

		local Data = ACF.RoundBaseGunpowder(self)

		Data.ShovePower = 0.2
		Data.LimitVel   = 1000 --Most efficient penetration speed in m/s
		Data.Ricochet   = 80 --Base ricochet angle

		self:UpdateRoundData()

		return self.BulletData, self.GUIData
	end

	-- Shared with the client so the spawn menu can price a crate without spawning it.
	local Conversion = ACF.PointConversion

	function CLASS:GetCost(BulletData)
		local SabotMass	= BulletData.CartMass - BulletData.PropMass - BulletData.ProjMass

		return (BulletData.ProjMass * Conversion.Tungsten) + (BulletData.PropMass * Conversion.Propellant) + (SabotMass * Conversion.Aluminum)
	end

	if SERVER then
		function CLASS:OnLast(Entity)
			BASE.OnLast(self, Entity)

			Entity.TelescopeRatio = nil
		end

		function CLASS:Network(Entity, BulletData)
			BASE.Network(self, Entity, BulletData)

			Entity:SetNW2String("AmmoType", "ACF.Ammunition.APFSDS")
		end
	else
		ACF.RegisterAmmoDecal("ACF.Ammunition.APFSDS", "damage/apcr_pen", "damage/apcr_rico")

		function CLASS:OnCreateAmmoControls(Base)
			ACF.AmmoMenu.Slider(Base, "#acf.menu.ammo.telescope_ratio", 0, 1, 3, "TelescopeRatio", function(Value)
				self.TelescopeRatio = Value
				self:UpdateRoundData()
			end)
		end

		-- Ammo menu visual: a long-rod penetrator (BulletData.Diameter, already scaled down to 35% of bore)
		-- riding inside a full-bore sabot (BulletData.Caliber) that only covers part of the dart's length.
		function CLASS:DrawAmmoVisual(Panel, w, h, _, BulletData)
			local GeoPrim = ACF.GeoPrim
			local Margin  = 10
			local DrawW   = w - Margin * 2

			local TelescopeLengthCm = BulletData.TelescopeLength or 0
			local ExposedProjLength = BulletData.ProjLength - TelescopeLengthCm

			-- Sabot mass/volume in UpdateRoundData is sized off the full rod (BulletData.ProjLength), not
			-- just its exposed portion -- but the sabot can only be drawn over the exposed rod (the part
			-- not buried back in the propellant), so the drawn length is still capped to what's visible.
			local SabotLenCm = math.min(BulletData.ProjLength * 0.25, ExposedProjLength)

			-- ProjLength already includes the telescoped overlap into the propellant, so laying it out
			-- back-to-back with PropLength would double-count that overlap -- use RoundLength (the real
			-- physical span) instead, and pull the rod's start back into the propellant separately below.
			local Length = BulletData.RoundLength

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

			-- Discarding sabot, full bore diameter, only wraps the rear portion of the rod
			local Sabot = GeoPrim.New("Cylinder", { Radius = BulletData.Caliber * 0.5, Height = SabotLenCm })
			Sabot:SetMaterial("Aluminum Sabot (Discarding)")

			-- Long-rod penetrator, running the full length of the projectile. Drawn after the sabot,
			-- starting at RodX (behind SabotX when telescoped) so it's the on-top, narrower shape
			-- within the overlap.
			local Penetrator = GeoPrim.New("Cylinder", { Radius = BulletData.Diameter * 0.5, Height = BulletData.ProjLength })
			Penetrator:SetMaterial("Tungsten Penetrator")

			local X = Margin
			X = Propellant:Draw(Panel, X, CenterY, Scale, MaxDia, Color(180, 150, 60), Color(30, 30, 30))
			local SabotX = X
			-- Telescoped rounds have the rod reaching back into the propellant/case by TelescopeLength,
			-- so the rod is drawn starting that far behind the sabot instead of flush with it.
			local RodX = X - TelescopeLengthCm * Scale
			Sabot:Draw(Panel, SabotX, CenterY, Scale, MaxDia, Color(150, 150, 155), Color(30, 30, 30))
			Penetrator:Draw(Panel, RodX, CenterY, Scale, MaxDia, Color(90, 95, 100), Color(30, 30, 30))

			-- Tracer, a colored segment at the very base of the rod -- behind the telescoped tail buried
			-- in the case, not just behind the sabot -- drawn last (and not as a Rod child -- Draw() paints
			-- an entire subtree in one Color, so a child never gets a color of its own) so it takes hover
			-- priority and actually renders red instead of inheriting the penetrator's gray.
			if BulletData.Tracer and BulletData.Tracer > 0 then
				local Tracer = GeoPrim.New("Cylinder", { Radius = BulletData.Diameter * 0.5, Height = BulletData.Tracer })
				Tracer:SetMaterial("Tracer")
				Tracer:Draw(Panel, RodX, CenterY, Scale, MaxDia, Color(220, 40, 30), Color(30, 30, 30))
			end
		end
	end
end)