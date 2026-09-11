local ACF       = ACF
local Classes   = ACF.Classes

local MAX_FUZE_DELAY = 0.1 -- Longest delay a fuze can be set to, in seconds; also the menu slider's ceiling
local Damage    = ACF.Damage
local Clock 	= ACF.Utilities.Clock

Classes.DefineClass("ACF.Ammunition.APHE", "ACF.Ammunition.AP", function(CLASS, BASE)
	CLASS.Name		 = "Armor Piercing High Explosive"
	CLASS.SpawnIcon   = "acf/icons/shell_aphe.png"
	CLASS.Bodygroup   = 1 -- APHE bodygroup index
	CLASS.Description = "#acf.descs.ammo.aphe"
	CLASS.HasDelayFuze = true -- Can be given a penetration triggered delay fuze
	CLASS.Blacklist = {
		["ACF.Guns.GrenadeLauncher"] = true,
		["ACF.Guns.Machinegun"] = true,
		["ACF.Guns.Mortar"] = true,
		["ACF.Guns.SmokeLauncher"] = true,
		["ACF.Guns.RotaryAutocannon"] = true,
	}

	MENU_FIELD("Number", "FillerRatio", {Default = 0})
	MENU_FIELD("Number", "PenFuze",     {Default = 0})
	MENU_FIELD("Number", "FuzeDelay",   {Default = 0})

	function CLASS:GetPenetration(Bullet, Speed)
		if not isnumber(Speed) then
			Speed = Bullet.Flight and Bullet.Flight:Length() / ACF.Scale * ACF.InchToMeter or Bullet.MuzzleVel
		end

		return ACF.Penetration(Speed, Bullet.ProjMass, Bullet.Diameter * 10) * (1 - Bullet.FillerRatio)
	end

	--- Inverse of GetPenetration; undoes the filler penalty so recovered speed doesn't lose pen per layer.
	function CLASS:CalcSpeed(Bullet, Penetration)
		local Solid = 1 - Bullet.FillerRatio

		if Solid <= 0 then return 0 end

		return ACF.CalcSpeed(Penetration / Solid, Bullet.ProjMass, Bullet.Diameter * 10)
	end

	function CLASS:GetDisplayData(Data)
		local Display  = BASE.GetDisplayData(self, Data)
		local FragMass = Data.ProjMass - Data.FillerMass
		local FragInfo = ACF.Damage.getFragmentInfo(Data.FillerMass, FragMass) -- Single source of truth shared with the damage code

		Display.BlastRadius = Data.FillerMass ^ 0.33 * 8
		Display.Fragments   = FragInfo.Count
		Display.FragMass    = FragInfo.Mass
		Display.FragVel     = FragInfo.Velocity * ACF.InchToMeter -- in/s (sim units) to m/s for display

		hook.Run("ACF_OnRequestDisplayData", self, Data, Display)

		return Display
	end

	function CLASS:UpdateRoundData()
		local Data    = self.BulletData
		local GUIData = self.GUIData

		ACF.UpdateRoundSpecs(self)

		local FreeVol   = ACF.RoundShellCapacity(Data.PropMass, Data.ProjArea, Data.Caliber, Data.ProjLength)
		local FillerVol = FreeVol * math.Clamp(self.FillerRatio, 0, 1)

		Data.FillerMass = FillerVol * ACF.HEDensity
		Data.ProjMass   = math.max(GUIData.ProjVolume - FillerVol, 0) * ACF.SteelDensity + Data.FillerMass
		Data.MuzzleVel  = ACF.MuzzleVelocity(Data.PropMass, Data.ProjMass, Data.Efficiency)
		Data.DragCoef   = Data.ProjArea * 0.0001 / Data.ProjMass
		Data.CartMass   = Data.PropMass + Data.ProjMass
		Data.FillerRatio = math.Clamp(self.FillerRatio, 0, 1)

		-- Depth is capped by muzzle penetration, or arming would require more than the round can ever defeat.
		local MaxPen = self:GetPenetration(Data, Data.MuzzleVel)

		Data.PenFuze   = Data.CanFuze and math.Clamp(self.PenFuze or 0, 0, MaxPen) or 0
		Data.FuzeDelay = Data.PenFuze > 0 and math.Clamp(self.FuzeDelay or 0, 0, MAX_FUZE_DELAY) or 0

		hook.Run("ACF_OnUpdateRound", self, self, Data, GUIData)

		for K, V in pairs(self:GetDisplayData(Data)) do
			GUIData[K] = V
		end
	end

	function CLASS:BaseConvert()
		self.BulletData = {}

		local Data = ACF.RoundBaseGunpowder(self)

		Data.ShovePower = 0.1
		Data.LimitVel   = 700 --Most efficient penetration speed in m/s
		Data.Ricochet   = 65 --Base ricochet angle
		Data.CanFuze    = Data.Caliber * 10 >= ACF.MinFuzeCaliber -- Can fuze on calibers >= 25mm

		self.GUIData.MinFillerVol = 0

		self:UpdateRoundData()

		return self.BulletData, self.GUIData
	end

	function CLASS:VerifyData()
		BASE.VerifyData(self)

		if not isnumber(self.FillerRatio) then
			self.FillerRatio = 1
		end

		if not isnumber(self.PenFuze) then
			self.PenFuze = 0
		end

		if not isnumber(self.FuzeDelay) then
			self.FuzeDelay = 0
		end
	end

	-- Shared with the client so the spawn menu can price a crate without spawning it.
	local Conversion = ACF.PointConversion

	function CLASS:GetCost(BulletData)
		return ((BulletData.ProjMass - BulletData.FillerMass) * Conversion.Steel) + (BulletData.PropMass * Conversion.Propellant) + (BulletData.FillerMass * Conversion.CompB)
	end

	if SERVER then
		local Objects  = Damage.Objects

		function CLASS:OnLast(Entity)
			BASE.OnLast(self, Entity)

			Entity.FillerRatio = nil
			Entity.PenFuze     = nil
			Entity.FuzeDelay   = nil

			-- Cleanup the leftovers aswell
			Entity.FillerMass  = nil
			Entity.RoundData5  = nil

			Entity:SetNW2Float("FillerMass", 0)
		end

		function CLASS:Network(Entity, BulletData)
			BASE.Network(self, Entity, BulletData)

			Entity:SetNW2String("AmmoType", "ACF.Ammunition.APHE")
			Entity:SetNW2Float("FillerMass", BulletData.FillerMass)
		end

		function CLASS:UpdateCrateOverlay(BulletData, State)
			BASE.UpdateCrateOverlay(self, BulletData, State)
			local Data = self:GetDisplayData(BulletData)
			State:AddNumber("Blast Radius", Data.BlastRadius, " m", 2)
			State:AddNumber("Blast Energy", BulletData.FillerMass * ACF.HEPower, " kJ", 2)

			if (BulletData.PenFuze or 0) > 0 then
				State:AddNumber("Fuze Depth", BulletData.PenFuze, " mm RHA", 2)
				State:AddNumber("Fuze Delay", BulletData.FuzeDelay, " s", 3)
			end
		end

		--- Delay fuze: tracks armor defeated, then hands detonation to the flight loop's fuze timer once armed.
		local function TrackPenFuze(Bullet, Result, Before, ExitPos)
			-- Only a real penetration spends capacity; ACF-ignored targets also return "Penetrated" but change nothing.
			if Result ~= "Penetrated" then return Result end

			local Defeated = (Bullet.PenDefeated or 0) + (Before - Bullet:GetPenetration())

			Bullet.PenDefeated = Defeated

			if Defeated < Bullet.PenFuze then return Result end

			Bullet.PenFuzeArmed = true

			local Delay = Bullet.FuzeDelay or 0

			-- No delay: detonate at the exit point now rather than waiting for the next tick boundary.
			if Delay <= 0 then
				Bullet.DetByFuze = true
				Bullet.Pos       = ExitPos

				return false
			end

			local Time = Clock.CurTime + Delay

			-- Whichever fuze, the weapon's or this one, runs out first wins.
			Bullet.Fuze = Bullet.Fuze and math.min(Bullet.Fuze, Time) or Time

			return Result
		end

		function CLASS:PropImpact(Bullet, Trace)
			if (Bullet.PenFuze or 0) <= 0 or Bullet.PenFuzeArmed then
				return BASE.PropImpact(self, Bullet, Trace)
			end

			local Before = Bullet:GetPenetration()
			local Result = BASE.PropImpact(self, Bullet, Trace)

			return TrackPenFuze(Bullet, Result, Before, Bullet.ConvexHit and Bullet.ConvexHit.ExitPos or Trace.HitPos)
		end
		-- World penetration rescales Flight the same way, so GetPenetration() before/after still measures it; only NextPos (no ConvexHit here) differs.
		function CLASS:WorldImpact(Bullet, Trace)
			if (Bullet.PenFuze or 0) <= 0 or Bullet.PenFuzeArmed then
				return BASE.WorldImpact(self, Bullet, Trace)
			end

			local Before = Bullet:GetPenetration()
			local Result = BASE.WorldImpact(self, Bullet, Trace)

			return TrackPenFuze(Bullet, Result, Before, Bullet.NextPos)
		end

		function CLASS:OnFlightEnd(Bullet, Trace)
			if not Bullet.DetByFuze then
				local Offset = Bullet.ProjLength * 0.39 * 0.5 -- Pulling the explosion back by half of the projectiles length

				Bullet.Pos = Trace.HitPos - Bullet.Flight:GetNormalized() * Offset
			end

			local Position = Bullet.Pos
			local Filler   = Bullet.FillerMass
			local Fragment = Bullet.ProjMass - Filler
			local DmgInfo  = Objects.DamageInfo(Bullet.Owner, Bullet.Gun)

			Bullet.KillTime = Clock.CurTime
			Damage.createExplosion(Position, Filler, Fragment, nil, DmgInfo)

			BASE.OnFlightEnd(self, Bullet, Trace)
		end
	else
		ACF.RegisterAmmoDecal("ACF.Ammunition.APHE", "damage/ap_pen", "damage/ap_rico")

		function CLASS:ImpactEffect(_, Bullet)
			local Position  = Bullet.SimPos
			local Direction = Bullet.SimFlight
			local Filler    = Bullet.FillerMass

			Damage.explosionEffect(Position, Direction, Filler)
		end

		function CLASS:OnCreateAmmoControls(Base)
			ACF.AmmoMenu.Slider(Base, "Filler Ratio", 0, 1, 2, "FillerRatio", function(Value)
				self.FillerRatio = math.Round(Value, 2)
				self:UpdateRoundData()
			end)

			-- Skipped by HE (no penetration to fuze on) and below the timed fuze's caliber gate.
			if not self.HasDelayFuze or not self.BulletData.CanFuze then return end

			local function GetMaxDepth()
				return math.max(self.GUIData.MaxPen or 0, 1)
			end

			ACF.AmmoMenu.Slider(Base, "#acf.menu.ammo.pen_fuze", 0, GetMaxDepth(), 0, "PenFuze", function(Value)
				self.PenFuze = math.Round(Value)
				self:UpdateRoundData()
			end, function(Panel)
				-- The ceiling is the round's own muzzle penetration, which moves with filler and length.
				Panel:SetMinMax(0, GetMaxDepth())
				Panel:SetValue(self.BulletData.PenFuze)
			end)

			ACF.AmmoMenu.Slider(Base, "#acf.menu.ammo.fuze_delay", 0, MAX_FUZE_DELAY, 3, "FuzeDelay", function(Value)
				self.FuzeDelay = math.Round(Value, 3)
				self:UpdateRoundData()
			end)
		end

		function CLASS:OnCreateAmmoInformation(Base, _, BulletData)
			local RoundStats = Base:AddLabel()
			ACF.AmmoMenu.Reactive(RoundStats, function()
				self:UpdateRoundData()

				local Text		= language.GetPhrase("acf.menu.ammo.round_stats_he")
				local MuzzleVel	= math.Round(BulletData.MuzzleVel * ACF.Scale, 2)
				local ProjMass	= ACF.FormatMass(BulletData.ProjMass)
				local PropMass	= ACF.FormatMass(BulletData.PropMass)
				local Filler	= ACF.FormatMass(BulletData.FillerMass)

				RoundStats:SetText(Text:format(MuzzleVel, ProjMass, PropMass, Filler))
			end)

			local FillerStats = Base:AddLabel()
			ACF.AmmoMenu.Reactive(FillerStats, function()
				self:UpdateRoundData()

				local Text	   = language.GetPhrase("acf.menu.ammo.filler_stats_he")
				local Blast	   = math.Round(self.GUIData.BlastRadius, 2)
				local FragMass = ACF.FormatMass(self.GUIData.FragMass)
				local FragVel  = math.Round(self.GUIData.FragVel, 2)

				FillerStats:SetText(Text:format(Blast, self.GUIData.Fragments, FragMass, FragVel))
			end)

			local FuzeStats = Base:AddLabel()
			ACF.AmmoMenu.Reactive(FuzeStats, function()
				self:UpdateRoundData()

				if BulletData.PenFuze <= 0 then
					FuzeStats:SetText(language.GetPhrase("acf.menu.ammo.fuze_stats_none"))
					return
				end

				local Text  = language.GetPhrase("acf.menu.ammo.fuze_stats_aphe")
				local Depth = math.Round(BulletData.PenFuze, 2)
				local Delay = math.Round(BulletData.FuzeDelay, 3)

				FuzeStats:SetText(Text:format(Depth, Delay))
			end)

			local MaxPenLabel = Base:AddLabel()
			ACF.AmmoMenu.Reactive(MaxPenLabel, function()
				local Text		= language.GetPhrase("acf.menu.ammo.pen_stats_ap")
				local MaxPen	= math.Round(self.GUIData.MaxPen, 2)
				MaxPenLabel:SetText(Text:format(MaxPen))
			end)
		end

		-- Ammo menu visual: casing plus a body split between the explosive filler and the steel shell
		-- wall/nose around it, matching the mass split in UpdateRoundData (ProjVolume - FillerVol is
		-- steel, the rest filler). Inherited by HE, which doesn't override this.
		function CLASS:DrawAmmoVisual(Panel, w, h, ToolData, BulletData)
			local GeoPrim  = ACF.GeoPrim
			local Margin   = 10
			local DrawW    = w - Margin * 2
			local Diameter = BulletData.Diameter or BulletData.Caliber

			local Length = BulletData.ProjLength + BulletData.PropLength

			if Length <= 0 then return end

			-- Cap Scale by the case, the widest part, so the case/bore step survives the height budget
			local CaseDia = BulletData.CaseDiameter

			if CaseDia <= 0 then return end

			local Scale      = math.min(DrawW / Length, ((h - Margin * 2) * 0.6) / CaseDia)
			local DiameterPx = CaseDia * Scale
			local CenterY    = h * 0.5
			local Radius     = Diameter * 0.5

			-- Use ToolData directly rather than BulletData.FillerRatio: HE overrides UpdateRoundData
			-- without inheriting APHE's, and only ToolData.FillerRatio is guaranteed to be set for both.
			local FillerRatio = math.Clamp(ToolData.FillerRatio or 0, 0, 1)

			-- Matches UpdateRoundData's own math (ACF.RoundShellCapacity): the filler cavity is inset
			-- from the casing's outer radius/length by MinWall (the shell wall thickness needed to
			-- survive firing), and FillerRatio scales that already-shrunk cavity, not the raw ProjLength.
			local _, CavityLenCm, CavityRadius = ACF.RoundShellCapacity(BulletData.PropMass, BulletData.ProjArea, BulletData.Caliber, BulletData.ProjLength)
			local FillerLenCm = CavityLenCm * FillerRatio

			local Propellant = GeoPrim.New("Cylinder", { Radius = CaseDia * 0.5, Height = BulletData.PropLength })
			Propellant:SetMaterial("Propellant")

			-- Steel casing spans the whole body at the full outer radius, drawn first as the "hull" so
			-- the wall around the inset filler cavity shows as a visible steel ring once Filler is
			-- painted on top of it (a child GeoPrim can't have its own color -- see the Tracer comment
			-- below -- so these have to be two independent top-level primitives, not parent/child).
			local ShellCasing = GeoPrim.New("Cylinder", { Radius = Radius, Height = BulletData.ProjLength })
			ShellCasing:SetMaterial("Steel Shell Casing")

			local Filler = GeoPrim.New("Cylinder", { Radius = CavityRadius, Height = FillerLenCm })
			Filler:SetMaterial("Explosive Filler")

			local X = Margin
			X = Propellant:Draw(Panel, X, CenterY, Scale, DiameterPx, Color(180, 150, 60), Color(30, 30, 30))

			local BodyStartX = X
			ShellCasing:Draw(Panel, X, CenterY, Scale, DiameterPx, Color(120, 120, 130), Color(30, 30, 30))

			if FillerLenCm > 0 then
				Filler:Draw(Panel, BodyStartX, CenterY, Scale, DiameterPx, Color(190, 140, 40), Color(30, 30, 30))
			end

			-- Tracer, a colored segment at the very base of the body (against the casing), drawn last
			-- so it takes hover priority over whatever filler/steel material happens to sit underneath it
			if BulletData.Tracer and BulletData.Tracer > 0 then
				local Tracer = GeoPrim.New("Cylinder", { Radius = Radius, Height = math.max(BulletData.Tracer, 2 / Scale) })
				Tracer:SetMaterial("Tracer")
				Tracer:Draw(Panel, BodyStartX, CenterY, Scale, DiameterPx, Color(220, 40, 30), Color(30, 30, 30))
			end
		end
	end
end)