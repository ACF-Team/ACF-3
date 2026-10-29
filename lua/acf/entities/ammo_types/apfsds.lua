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
	-- TelescopeRatio bores the rod back into the propellant to shorten the overall round; real telescoped
	-- designs do this a lot. A real M829A1 cross-section shows the rod running nearly the entire case,
	-- propellant packed in the annular space around it, not a rod mostly exposed ahead of a separate
	-- propellant-only zone. Matching the real geometry (120x570mm NATO: 984mm overall round length, 570mm
	-- case, against the 684mm rod) needs TelescopeRatio = 0.474 to reproduce the real 684mm rod length
	-- exactly when RoundLength/PropRatio are also dialed to the real round's own 984mm/57.9% instead of
	-- this class's max slider settings; at M829A1's own real diameter ratio (0.202-0.225, see RodScale
	-- below) that predicts 728-763mm penetration, inside M829A1's own (uncertain) 670-820mm range. Capped
	-- there, not padded past it. (984mm OAL and 570mm case are
	-- moderate confidence, the case figure is the generic 120x570mm NATO family designation, not confirmed
	-- M829A1-specific.) A thin rod barely displaces propellant volume while boring in, so this model's
	-- velocity cost for telescoping is small relative to the length gained; the worst case across the
	-- class's full slider range, now that RodScale/MaxLengthToDiameter are both Cold War-bounded too, is
	-- ~809mm, down from 923mm when those two bounds mixed modern-era figures, and well under the 1126mm
	-- an unbounded 0-1 range let through.
	local MaxTelescopeRatio = 0.474

	-- Real long-rod penetrators are monobloc, one dense material (tungsten alloy or DU) end to end, not a
	-- dense core embedded in a separate lighter shaft; an earlier version of this file modeled the latter
	-- with a CoreLength field, removed, it didn't match how these rounds are actually built, and on top of
	-- TelescopeRatio and RodScale it made for too many sliders. The full rod (ProjLength) is dense material.

	-- Rod diameter from 0 (thinnest real rod for this caliber and length) to 1 (thickest), defaulting to the thickest
	MENU_FIELD("Number", "RodScale", {Default = 1})

	-- Rod over bore diameter, Cold War rounds only (to ~1991): 3BM9 0.352, DM23 0.267, 3BM42 0.248, DM33 0.233.
	-- Modern 3BM42M (0.176) is left out, pairing it with a modern L/D gave rods slimmer than any real round.
	local RealMinDiameterRatio, RealMaxDiameterRatio = 0.233, 0.352

	-- Small bores carry relatively thicker rods (30mm Mk258 9mm, 3UBR11 10mm), so the thin end rises below 105mm (M833 0.234)
	local SmallMinDiameterRatio = 0.30

	local function GetMinDiameterRatio(Caliber)
		return math.Remap(math.Clamp(Caliber * 10, 30, 105), 30, 105, SmallMinDiameterRatio, RealMinDiameterRatio)
	end

	-- Real Cold War-era APFSDS L/D: German DM13 (1979) ~8:1, DM23 ~12-15:1, DM33 ~18-26:1 (two sources
	-- disagree, 26 is the upper figure, used here). DM43's ~32:1 estimate and DM53's directly-published
	-- 38:1 are post-Cold War and excluded, same reasoning as the diameter bound above. A rod can't be
	-- arbitrarily thin for its length and still survive sabot-discard and launch loads; that structural
	-- limit, not a pressure model, is what bounds this. Capped at DM33's upper estimate, the highest
	-- Cold War figure found.
	local MaxLengthToDiameter = 26

	local RodDensity      = 17.5e-3 -- kg/cm^3, tungsten heavy alloy (DM33 17.2, DM53 17.6, M829A1 about 18 from real rod mass)
	local SabotCalibers   = 0.65 -- Sabot mass as a full-bore aluminium slug this many calibers long,
	local SabotRodShare   = 0.048 -- plus this share of the rod length (120mm sabots 2.8 to 3.6kg for 360 to 685mm rods, M735 2.1kg)

	CLASS.Blacklist = ACF.GetWeaponBlacklist({
		["ACF.Guns.Cannon"] = true,
		["ACF.Guns.Autocannon"] = true,
		["ACF.Guns.LightAutocannon"] = true,
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
		local RoundDensity  = RodDensity * 1e6 -- From kg/cm3 to kg/m3
		local TargetBrinell = 237 -- Assuming we're hitting RHA
		local TargetDensity = 7840 -- Assuming we're hitting RHA
		local Constant      = 0.994 -- Tungsten rod perforation coefficients, from longrods.ch's calculator
		local S2            = (134.5 - 0.148 * TargetBrinell) * TargetBrinell / RoundDensity

		local FirstChunk    = 1 / math.tanh(0.283 + 0.0656 * RoundLength / RoundCaliber)
		local SecondChunk   = (RoundDensity / TargetDensity) ^ 0.5
		local ThirdChunk    = math.exp(-S2 / (Speed * Speed))

		return Constant * FirstChunk * SecondChunk * ThirdChunk * RoundLength
	end

	-- Inverse of the Lanz-Odermatt equation above, solved for Speed (Penetration in mm, returns speed in m/s)
	function CLASS:CalcSpeed(Bullet, Penetration)
		local RoundLength   = Bullet.ProjLength * 10 -- From cm to mm
		local RoundCaliber  = Bullet.Diameter * 10 -- From cm to mm
		local RoundDensity  = RodDensity * 1e6 -- From kg/cm3 to kg/m3
		local TargetBrinell = 237 -- Assuming we're hitting RHA
		local TargetDensity = 7840 -- Assuming we're hitting RHA
		local Constant      = 0.994 -- Tungsten rod perforation coefficients, from longrods.ch's calculator
		local S2            = (134.5 - 0.148 * TargetBrinell) * TargetBrinell / RoundDensity

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

		-- ProjLength is final here, so the thin end can also rise with it to keep the rod under MaxLengthToDiameter
		local LengthFloor      = Data.ProjLength / (MaxLengthToDiameter * Data.Caliber)
		local MinDiameterRatio = math.Clamp(math.max(LengthFloor, GetMinDiameterRatio(Data.Caliber)), RealMinDiameterRatio, RealMaxDiameterRatio)

		Data.Diameter = Data.Caliber * Lerp(math.Clamp(self.RodScale or 1, 0, 1), MinDiameterRatio, RealMaxDiameterRatio)
		Data.ProjArea = math.pi * (Data.Diameter * 0.5) ^ 2

		-- Real sabots barely grow with rod length or thinness, so the sabot is sized off the bore
		local SabotLength = SabotCalibers * Data.Caliber + SabotRodShare * Data.ProjLength
		local SabotMass   = math.pi * (Data.Caliber * 0.5) ^ 2 * SabotLength * ACF.AluminumDensity

		Data.ProjMass  = Data.ProjArea * Data.ProjLength * RodDensity
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

		self.TelescopeRatio = math.Clamp(self.TelescopeRatio, 0, MaxTelescopeRatio)

		if not isnumber(self.RodScale) then
			self.RodScale = 1
		end

		self.RodScale = math.Clamp(self.RodScale, 0, 1)
	end

	function CLASS:BaseConvert()
		-- Mutated in place, not replaced: the ammo menu's preview captures this table once and redraws
		-- from that same reference on every slider change (see apcr.lua's CoreScale for the full story).
		self.BulletData = self.BulletData or {}
		-- Provisional diameter for UpdateRoundSpecs's telescope hole, UpdateRoundData corrects it once ProjLength is known
		self.BulletData.ProjScale = Lerp(math.Clamp(self.RodScale or 1, 0, 1), RealMinDiameterRatio, RealMaxDiameterRatio)

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
			Entity.RodScale = nil
		end

		function CLASS:Network(Entity, BulletData)
			BASE.Network(self, Entity, BulletData)

			Entity:SetNW2String("AmmoType", "ACF.Ammunition.APFSDS")
		end
	else
		ACF.RegisterAmmoDecal("ACF.Ammunition.APFSDS", "damage/apcr_pen", "damage/apcr_rico")

		function CLASS:OnCreateAmmoControls(Base)
			ACF.AmmoMenu.Slider(Base, "#acf.menu.ammo.telescope_ratio", 0, MaxTelescopeRatio, 3, "TelescopeRatio", function(Value)
				self.TelescopeRatio = Value
				self:UpdateRoundData()
			end, function(Panel)
				Panel:SetValue(math.Clamp(self.TelescopeRatio or 0, 0, MaxTelescopeRatio))
			end)

			ACF.AmmoMenu.Slider(Base, "#acf.menu.ammo.rod_scale", 0, 1, 2, "RodScale", function(Value)
				self.RodScale = Value
				self:UpdateRoundData()
			end)
		end

		-- Ammo menu visual: a long-rod penetrator (BulletData.Diameter, already scaled down by RodScale)
		-- riding inside a full-bore sabot (BulletData.Caliber) that only covers part of the dart's length.
		function CLASS:DrawAmmoVisual(Panel, w, h, _, BulletData)
			local GeoPrim = ACF.GeoPrim
			local Margin  = 10
			local DrawW   = w - Margin * 2

			local TelescopeLengthCm = BulletData.TelescopeLength or 0
			local ExposedProjLength = BulletData.ProjLength - TelescopeLengthCm

			-- Illustrative only, UpdateRoundData sizes the sabot by mass. Capped to the rod left exposed past the propellant.
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

			-- Long-rod penetrator, monobloc tungsten, running the full length of the projectile. Drawn
			-- after the sabot, starting at RodX (behind SabotX when telescoped) so it's the on-top,
			-- narrower shape within the overlap.
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