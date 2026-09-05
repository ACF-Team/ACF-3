local ACF       = ACF
local Classes   = ACF.Classes
local Damage    = ACF.Damage
local AmmoTypes = Classes.AmmoTypes
local Ammo      = AmmoTypes.Register("APHE", "AP")
local Clock 	= ACF.Utilities.Clock

local MAX_FUZE_DELAY = 0.1 -- Longest delay a fuze can be set to, in seconds; also the menu slider's ceiling

function Ammo:OnLoaded()
	Ammo.BaseClass.OnLoaded(self)

	self.Name		 = "Armor Piercing High Explosive"
	self.SpawnIcon   = "acf/icons/shell_aphe.png"
	self.Bodygroup   = 1 -- APHE bodygroup index
	self.Description = "#acf.descs.ammo.aphe"
	self.HasDelayFuze = true -- Can be given a penetration triggered delay fuze
	self.Blacklist = {
		GL = true,
		MG = true,
		MO = true,
		SL = true,
		RAC = true,
	}
end

function Ammo:GetPenetration(Bullet, Speed)
	if not isnumber(Speed) then
		Speed = Bullet.Flight and Bullet.Flight:Length() / ACF.Scale * ACF.InchToMeter or Bullet.MuzzleVel
	end

	return ACF.Penetration(Speed, Bullet.ProjMass, Bullet.Diameter * 10) * (1 - Bullet.FillerRatio)
end

--- Inverse of GetPenetration; undoes the filler penalty so recovered speed doesn't lose pen per layer.
function Ammo:CalcSpeed(Bullet, Penetration)
	local Solid = 1 - Bullet.FillerRatio

	if Solid <= 0 then return 0 end

	return ACF.CalcSpeed(Penetration / Solid, Bullet.ProjMass, Bullet.Diameter * 10)
end

function Ammo:GetDisplayData(Data)
	local Display  = Ammo.BaseClass.GetDisplayData(self, Data)
	local FragMass = Data.ProjMass - Data.FillerMass
	local FragInfo = ACF.Damage.getFragmentInfo(Data.FillerMass, FragMass) -- Single source of truth shared with the damage code

	Display.BlastRadius = Data.FillerMass ^ 0.33 * 8
	Display.Fragments   = FragInfo.Count
	Display.FragMass    = FragInfo.Mass
	Display.FragVel     = FragInfo.Velocity * ACF.InchToMeter -- in/s (sim units) to m/s for display

	hook.Run("ACF_OnRequestDisplayData", self, Data, Display)

	return Display
end

function Ammo:UpdateRoundData(ToolData, Data, GUIData)
	GUIData = GUIData or Data

	ACF.UpdateRoundSpecs(ToolData, Data, GUIData)

	local FreeVol   = ACF.RoundShellCapacity(Data.PropMass, Data.ProjArea, Data.Caliber, Data.ProjLength)
	local FillerVol = FreeVol * math.Clamp(ToolData.FillerRatio, 0, 1)

	Data.FillerMass = FillerVol * ACF.HEDensity
	Data.ProjMass   = math.max(GUIData.ProjVolume - FillerVol, 0) * ACF.SteelDensity + Data.FillerMass
	Data.MuzzleVel  = ACF.MuzzleVelocity(Data.PropMass, Data.ProjMass, Data.Efficiency)
	Data.DragCoef   = Data.ProjArea * 0.0001 / Data.ProjMass
	Data.CartMass   = Data.PropMass + Data.ProjMass
	Data.FillerRatio = math.Clamp(ToolData.FillerRatio, 0, 1)

	-- Depth is capped by muzzle penetration, or arming would require more than the round can ever defeat.
	local MaxPen = self:GetPenetration(Data, Data.MuzzleVel)

	Data.PenFuze   = Data.CanFuze and math.Clamp(ToolData.PenFuze or 0, 0, MaxPen) or 0
	Data.FuzeDelay = Data.PenFuze > 0 and math.Clamp(ToolData.FuzeDelay or 0, 0, MAX_FUZE_DELAY) or 0

	hook.Run("ACF_OnUpdateRound", self, ToolData, Data, GUIData)

	for K, V in pairs(self:GetDisplayData(Data)) do
		GUIData[K] = V
	end
end

function Ammo:BaseConvert(ToolData)
	local Data, GUIData = ACF.RoundBaseGunpowder(ToolData, {})

	Data.ShovePower = 0.1
	Data.LimitVel   = 700 --Most efficient penetration speed in m/s
	Data.Ricochet   = 65 --Base ricochet angle
	Data.CanFuze    = Data.Caliber * 10 >= ACF.MinFuzeCaliber -- Can fuze on calibers >= 25mm

	GUIData.MinFillerVol = 0

	self:UpdateRoundData(ToolData, Data, GUIData)

	return Data, GUIData
end

function Ammo:VerifyData(ToolData)
	Ammo.BaseClass.VerifyData(self, ToolData)

	if not isnumber(ToolData.FillerRatio) then
		ToolData.FillerRatio = 1
	end

	if not isnumber(ToolData.PenFuze) then
		ToolData.PenFuze = 0
	end

	if not isnumber(ToolData.FuzeDelay) then
		ToolData.FuzeDelay = 0
	end
end

-- Shared with the client so the spawn menu can price a crate without spawning it.
local Conversion = ACF.PointConversion

function Ammo:GetCost(BulletData)
	return ((BulletData.ProjMass - BulletData.FillerMass) * Conversion.Steel) + (BulletData.PropMass * Conversion.Propellant) + (BulletData.FillerMass * Conversion.CompB)
end

if SERVER then
	local Entities = Classes.Entities
	local Objects  = Damage.Objects

	Entities.AddArguments("acf_ammo", "FillerRatio", "PenFuze", "FuzeDelay") -- Adding extra info to ammo crates

	function Ammo:OnLast(Entity)
		Ammo.BaseClass.OnLast(self, Entity)

		Entity.FillerRatio = nil
		Entity.PenFuze     = nil
		Entity.FuzeDelay   = nil

		-- Cleanup the leftovers aswell
		Entity.FillerMass  = nil
		Entity.RoundData5  = nil

		Entity:SetNW2Float("FillerMass", 0)
	end

	function Ammo:Network(Entity, BulletData)
		Ammo.BaseClass.Network(self, Entity, BulletData)

		Entity:SetNW2String("AmmoType", "APHE")
		Entity:SetNW2Float("FillerMass", BulletData.FillerMass)
	end

	function Ammo:UpdateCrateOverlay(BulletData, State)
		Ammo.BaseClass.UpdateCrateOverlay(self, BulletData, State)
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

	function Ammo:PropImpact(Bullet, Trace)
		if (Bullet.PenFuze or 0) <= 0 or Bullet.PenFuzeArmed then
			return Ammo.BaseClass.PropImpact(self, Bullet, Trace)
		end

		local Before = Bullet:GetPenetration()
		local Result = Ammo.BaseClass.PropImpact(self, Bullet, Trace)

		return TrackPenFuze(Bullet, Result, Before, Bullet.ConvexHit and Bullet.ConvexHit.ExitPos or Trace.HitPos)
	end

	-- World penetration rescales Flight the same way, so GetPenetration() before/after still measures it; only NextPos (no ConvexHit here) differs.
	function Ammo:WorldImpact(Bullet, Trace)
		if (Bullet.PenFuze or 0) <= 0 or Bullet.PenFuzeArmed then
			return Ammo.BaseClass.WorldImpact(self, Bullet, Trace)
		end

		local Before = Bullet:GetPenetration()
		local Result = Ammo.BaseClass.WorldImpact(self, Bullet, Trace)

		return TrackPenFuze(Bullet, Result, Before, Bullet.NextPos)
	end

	function Ammo:OnFlightEnd(Bullet, Trace)
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

		Ammo.BaseClass.OnFlightEnd(self, Bullet, Trace)
	end
else
	ACF.RegisterAmmoDecal("APHE", "damage/ap_pen", "damage/ap_rico")

	-- Ammo menu visual: casing plus a body split between the explosive filler and the steel shell
	-- wall/nose around it, matching the mass split in UpdateRoundData (ProjVolume - FillerVol is
	-- steel, the rest filler). Inherited by HE, which doesn't override this.
	function Ammo:DrawAmmoVisual(Panel, w, h, ToolData, BulletData)
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

	function Ammo:ImpactEffect(_, Bullet)
		local Position  = Bullet.SimPos
		local Direction = Bullet.SimFlight
		local Filler    = Bullet.FillerMass

		Damage.explosionEffect(Position, Direction, Filler)
	end

	function Ammo:OnCreateAmmoControls(Base, ToolData, BulletData)
		local FillerRatio = Base:AddSlider("Filler Ratio", 0, 1, 2)
		FillerRatio:SetClientData("FillerRatio", "OnValueChanged")
		FillerRatio:DefineSetter(function(_, _, _, Value)
			ToolData.FillerRatio = math.Round(Value, 2)

			self:UpdateRoundData(ToolData, BulletData)

			return BulletData.FillerVol
		end)

		-- Skipped by HE (no penetration to fuze on) and below the timed fuze's caliber gate.
		if not self.HasDelayFuze or not BulletData.CanFuze then return end

		local function GetMaxDepth()
			return math.max(BulletData.MaxPen or 0, 1)
		end

		-- Tracks anything that moves the round's penetration, since that's this slider's ceiling.
		local PenFuze = Base:AddSlider("#acf.menu.ammo.pen_fuze", 0, GetMaxDepth(), 0)
		PenFuze:SetClientData("PenFuze", "OnValueChanged")
		PenFuze:TrackClientData("FillerRatio")
		PenFuze:TrackClientData("RoundLength")
		PenFuze:TrackClientData("PropRatio")
		PenFuze:TrackClientData("CaseScale")
		PenFuze:DefineSetter(function(Panel, _, Key, Value)
			if Key == "PenFuze" then
				ToolData.PenFuze = math.Round(Value)
			end

			self:UpdateRoundData(ToolData, BulletData)

			Panel:SetMinMax(0, GetMaxDepth())
			Panel:SetValue(BulletData.PenFuze)

			return BulletData.PenFuze
		end)

		local FuzeDelay = Base:AddSlider("#acf.menu.ammo.fuze_delay", 0, MAX_FUZE_DELAY, 3)
		FuzeDelay:SetClientData("FuzeDelay", "OnValueChanged")
		FuzeDelay:DefineSetter(function(Panel, _, _, Value)
			ToolData.FuzeDelay = math.Round(Value, 3)

			self:UpdateRoundData(ToolData, BulletData)

			Panel:SetValue(BulletData.FuzeDelay)

			return BulletData.FuzeDelay
		end)
	end

	function Ammo:OnCreateCrateInformation(Base, Label, ...)
		Ammo.BaseClass.OnCreateCrateInformation(self, Base, Label, ...)

		Label:TrackClientData("FillerRatio")
	end

	function Ammo:OnCreateAmmoInformation(Base, ToolData, BulletData)
		local RoundStats = Base:AddLabel()
		RoundStats:TrackClientData("RoundLength", "SetText")
		RoundStats:TrackClientData("PropRatio")
		RoundStats:TrackClientData("CaseScale")
		RoundStats:TrackClientData("FillerRatio")
		RoundStats:DefineSetter(function()
			self:UpdateRoundData(ToolData, BulletData)

			local Text		= language.GetPhrase("acf.menu.ammo.round_stats_he")
			local MuzzleVel	= math.Round(BulletData.MuzzleVel * ACF.Scale, 2)
			local ProjMass	= ACF.FormatMass(BulletData.ProjMass)
			local PropMass	= ACF.FormatMass(BulletData.PropMass)
			local Filler	= ACF.FormatMass(BulletData.FillerMass)

			return Text:format(MuzzleVel, ProjMass, PropMass, Filler)
		end)

		local FillerStats = Base:AddLabel()
		FillerStats:TrackClientData("FillerRatio", "SetText")
		FillerStats:DefineSetter(function()
			self:UpdateRoundData(ToolData, BulletData)

			local Text	   = language.GetPhrase("acf.menu.ammo.filler_stats_he")
			local Blast	   = math.Round(BulletData.BlastRadius, 2)
			local FragMass = ACF.FormatMass(BulletData.FragMass)
			local FragVel  = math.Round(BulletData.FragVel, 2)

			return Text:format(Blast, BulletData.Fragments, FragMass, FragVel)
		end)

		local MaxPen = Base:AddLabel()
		MaxPen:TrackClientData("RoundLength", "SetText")
		MaxPen:TrackClientData("PropRatio")
		MaxPen:TrackClientData("CaseScale")
		MaxPen:TrackClientData("FillerRatio")
		MaxPen:DefineSetter(function()
			local Text		= language.GetPhrase("acf.menu.ammo.pen_stats_ap")
			local MaxPen	= math.Round(BulletData.MaxPen, 2)
			return Text:format(MaxPen)
		end)

		local FuzeStats = Base:AddLabel()
		FuzeStats:TrackClientData("PenFuze", "SetText")
		FuzeStats:TrackClientData("FuzeDelay")
		FuzeStats:TrackClientData("RoundLength")
		FuzeStats:TrackClientData("PropRatio")
		FuzeStats:TrackClientData("CaseScale")
		FuzeStats:TrackClientData("FillerRatio")
		FuzeStats:DefineSetter(function()
			self:UpdateRoundData(ToolData, BulletData)

			if BulletData.PenFuze <= 0 then
				return language.GetPhrase("acf.menu.ammo.fuze_stats_none")
			end

			local Text  = language.GetPhrase("acf.menu.ammo.fuze_stats_aphe")
			local Depth = math.Round(BulletData.PenFuze, 2)
			local Delay = math.Round(BulletData.FuzeDelay, 3)

			return Text:format(Depth, Delay)
		end)
	end
end