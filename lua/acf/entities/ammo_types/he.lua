local ACF   = ACF
local Types = ACF.Classes.AmmoTypes
local Ammo  = Types.Register("HE", "APHE")


function Ammo:OnLoaded()
	Ammo.BaseClass.OnLoaded(self)

	self.Name		 = "High Explosive"
	self.SpawnIcon   = "acf/icons/shell_he.png"
	self.Bodygroup   = 5 -- HE bodygroup index
	self.MortarBodygroup = 0 -- HE mortar submodel
	self.Description = "#acf.descs.ammo.he"
	self.Blacklist = {
		MG = true,
		RAC = true,
	}
end

function Ammo:GetPenetration()
	return 0
end

function Ammo:GetDisplayData(Data)
	local FragMass	= Data.ProjMass - Data.FillerMass
	local FragInfo	= ACF.Damage.getFragmentInfo(Data.FillerMass, FragMass) -- Single source of truth shared with the damage code
	local Display   = {
		BlastRadius = Data.FillerMass ^ 0.33 * 8,
		Fragments   = FragInfo.Count,
		FragMass    = FragInfo.Mass,
		FragVel     = FragInfo.Velocity * ACF.InchToMeter, -- in/s (sim units) to m/s for display
	}

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

	hook.Run("ACF_OnUpdateRound", self, ToolData, Data, GUIData)

	for K, V in pairs(self:GetDisplayData(Data)) do
		GUIData[K] = V
	end
end

function Ammo:BaseConvert(ToolData)
	local Data, GUIData = ACF.RoundBaseGunpowder(ToolData, {})

	GUIData.MinFillerVol = 0

	Data.ShovePower		= 0.1
	Data.LimitVel		= 100 --Most efficient penetration speed in m/s
	Data.Ricochet		= 60 --Base ricochet angle
	Data.DetonatorAngle	= 80
	Data.CanFuze		= Data.Caliber * 10 >= ACF.MinFuzeCaliber -- Can fuze on calibers >= 25mm

	self:UpdateRoundData(ToolData, Data, GUIData)

	return Data, GUIData
end

if SERVER then
	local Ballistics = ACF.Ballistics
	local Conversion	= ACF.PointConversion

	function Ammo:GetCost(BulletData)
		return ((BulletData.ProjMass - BulletData.FillerMass) * Conversion.Steel) + (BulletData.PropMass * Conversion.Propellant) + (BulletData.FillerMass * Conversion.CompB)
	end

	function Ammo:Network(Entity, BulletData)
		Ammo.BaseClass.Network(self, Entity, BulletData)

		Entity:SetNW2String("AmmoType", "HE")
	end

	function Ammo:UpdateCrateOverlay(BulletData, State)
		local Data = self:GetDisplayData(BulletData)
		State:AddNumber("Muzzle Velocity", BulletData.MuzzleVel, " m/s")
		State:AddNumber("Blast Radius", Data.BlastRadius, " m")
		State:AddNumber("Blast Energy", BulletData.FillerMass * ACF.HEPower, " kJ")
	end

	function Ammo:PropImpact(Bullet, Trace)
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

	function Ammo:WorldImpact()
		return false
	end
else
	ACF.RegisterAmmoDecal("HE", "damage/he_pen", "damage/he_rico")

	-- Ammo menu graph: fragment penetration over distance from the detonation.
	function Ammo:PlotAmmoGraph(Panel, _, BulletData)
		local Damage     = ACF.Damage
		local PenText    = language.GetPhrase("acf.menu.ammo.penetration")
		local BlastRadius = BulletData.BlastRadius -- Fragments reach zero velocity here; distance shares the same units
		local FillerMass  = BulletData.FillerMass
		local FragMass    = BulletData.ProjMass - FillerMass

		local Radius = math.max(BlastRadius, 1)
		local MaxPen = math.max(Damage.getFragmentPenetration(FillerMass, FragMass, BlastRadius, 0), 1)

		Panel:SetYLabel(PenText)
		Panel:SetXLabel("#acf.menu.ammo.distance")

		Panel:SetXRange(0, Radius)
		Panel:SetYRange(0, MaxPen * 1.1)

		Panel:SetXSpacing(Radius / 10)
		Panel:SetYSpacing(MaxPen * 1.1 / 10)

		Panel:PlotFunction(PenText, ACF.GraphColors.RedAlt, function(X)
			return Damage.getFragmentPenetration(FillerMass, FragMass, BlastRadius, X)
		end)
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
	end
end