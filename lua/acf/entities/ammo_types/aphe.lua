local ACF       = ACF
local Classes   = ACF.Classes
local Damage    = ACF.Damage
local AmmoTypes = Classes.AmmoTypes
local Ammo      = AmmoTypes.Register("APHE", "AP")


function Ammo:OnLoaded()
	Ammo.BaseClass.OnLoaded(self)

	self.Name		 = "Armor Piercing High Explosive"
	self.SpawnIcon   = "acf/icons/shell_aphe.png"
	self.Model		 = "models/munitions/round_100mm_ap_shot.mdl"
	self.Description = "#acf.descs.ammo.aphe"
	self.Blacklist = {
		GL = true,
		MG = true,
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

function Ammo:GetDisplayData(Data)
	local Display  = Ammo.BaseClass.GetDisplayData(self, Data)
	local FragMass = Data.ProjMass - Data.FillerMass

	Display.BlastRadius = Data.FillerMass ^ 0.33 * 8
	Display.Fragments   = math.max(math.floor((Data.FillerMass / FragMass) * ACF.HEFrag), 2)
	Display.FragMass    = FragMass / Display.Fragments
	Display.FragVel     = (Data.FillerMass * ACF.HEPower * 1000 / Display.FragMass / Display.Fragments) ^ 0.5

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
	Data.CanFuze    = Data.Caliber * 10 > ACF.MinFuzeCaliber -- Can fuze on calibers > 20mm

	GUIData.MinFillerVol = 0

	self:UpdateRoundData(ToolData, Data, GUIData)

	return Data, GUIData
end

function Ammo:VerifyData(ToolData)
	Ammo.BaseClass.VerifyData(self, ToolData)

	if not isnumber(ToolData.FillerRatio) then
		ToolData.FillerRatio = 1
	end
end

if SERVER then
	local Entities = Classes.Entities
	local Objects  = Damage.Objects
	local Conversion	= ACF.PointConversion

	Entities.AddArguments("acf_ammo", "FillerRatio") -- Adding extra info to ammo crates

	function Ammo:GetCost(BulletData)
		return ((BulletData.ProjMass - BulletData.FillerMass) * Conversion.Steel) + (BulletData.PropMass * Conversion.Propellant) + (BulletData.FillerMass * Conversion.CompB)
	end

	function Ammo:OnLast(Entity)
		Ammo.BaseClass.OnLast(self, Entity)

		Entity.FillerRatio = nil

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

		Damage.createExplosion(Position, Filler, Fragment, nil, DmgInfo)

		Ammo.BaseClass.OnFlightEnd(self, Bullet, Trace)
	end
else
	ACF.RegisterAmmoDecal("APHE", "damage/ap_pen", "damage/ap_rico")

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
	end

	function Ammo:OnCreateCrateInformation(Base, Label, ...)
		Ammo.BaseClass.OnCreateCrateInformation(self, Base, Label, ...)

		Label:TrackClientData("FillerRatio")
	end

	function Ammo:OnCreateAmmoInformation(Base, ToolData, BulletData)
		local RoundStats = Base:AddLabel()
		RoundStats:TrackClientData("Projectile", "SetText")
		RoundStats:TrackClientData("Propellant")
		RoundStats:TrackClientData("FillerRatio")
		RoundStats:DefineSetter(function()
			self:UpdateRoundData(ToolData, BulletData)

			local Text		= language.GetPhrase("acf.menu.ammo.round_stats_he")
			local MuzzleVel	= math.Round(BulletData.MuzzleVel * ACF.Scale, 2)
			local ProjMass	= ACF.GetProperMass(BulletData.ProjMass)
			local PropMass	= ACF.GetProperMass(BulletData.PropMass)
			local Filler	= ACF.GetProperMass(BulletData.FillerMass)

			return Text:format(MuzzleVel, ProjMass, PropMass, Filler)
		end)

		local FillerStats = Base:AddLabel()
		FillerStats:TrackClientData("FillerRatio", "SetText")
		FillerStats:DefineSetter(function()
			self:UpdateRoundData(ToolData, BulletData)

			local Text	   = language.GetPhrase("acf.menu.ammo.filler_stats_he")
			local Blast	   = math.Round(BulletData.BlastRadius, 2)
			local FragMass = ACF.GetProperMass(BulletData.FragMass)
			local FragVel  = math.Round(BulletData.FragVel, 2)

			return Text:format(Blast, BulletData.Fragments, FragMass, FragVel)
		end)

		local MaxPen = Base:AddLabel()
		MaxPen:TrackClientData("Projectile", "SetText")
		MaxPen:TrackClientData("Propellant")
		MaxPen:TrackClientData("FillerRatio")
		MaxPen:DefineSetter(function()
			local Text		= language.GetPhrase("acf.menu.ammo.pen_stats_ap")
			local MaxPen	= math.Round(BulletData.MaxPen, 2)
			return Text:format(MaxPen)
		end)
	end
end