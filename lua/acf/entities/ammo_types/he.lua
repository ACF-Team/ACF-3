local ACF   	= ACF
local Classes   = ACF.Classes
Classes.DefineClass("ACF.Ammunition.HE", "ACF.Ammunition.APHE", function(CLASS, BASE)
	CLASS.Name		 = "High Explosive"
	CLASS.SpawnIcon   = "acf/icons/shell_he.png"
	CLASS.Bodygroup   = 5 -- HE bodygroup index
	CLASS.MortarBodygroup = 0 -- HE mortar submodel
	CLASS.Description = "#acf.descs.ammo.he"
	CLASS.Blacklist = {
		["ACF.Guns.Machinegun"] = true,
		["ACF.Guns.RotaryAutocannon"] = true,
	}

	function CLASS:GetPenetration()
		return 0
	end

	function CLASS:GetDisplayData(Data)
		local FragMass	= Data.ProjMass - Data.FillerMass
		local Fragments	= math.max(math.floor((Data.FillerMass / FragMass) * ACF.HEFrag), 2)
		local Display   = {
			BlastRadius = Data.FillerMass ^ 0.33 * 8,
			Fragments   = Fragments,
			FragMass    = FragMass / Fragments,
			FragVel     = (Data.FillerMass * ACF.HEPower * 1000 / (FragMass / Fragments) / Fragments) ^ 0.5,
		}

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

	-- Shared with the client so the spawn menu can price a crate without spawning it.
	local Conversion = ACF.PointConversion

	function CLASS:GetCost(BulletData)
		return ((BulletData.ProjMass - BulletData.FillerMass) * Conversion.Steel) + (BulletData.PropMass * Conversion.Propellant) + (BulletData.FillerMass * Conversion.CompB)
	end

	if SERVER then
		local Ballistics = ACF.Ballistics



		function CLASS:Network(Entity, BulletData)
			BASE.Network(self, Entity, BulletData)

			Entity:SetNW2String("AmmoType", "ACF.Ammunition.HE")
		end

		function CLASS:UpdateCrateOverlay(BulletData, State)
			local Data = self:GetDisplayData(BulletData)
			State:AddNumber("Muzzle Velocity", BulletData.MuzzleVel, " m/s")
			State:AddNumber("Blast Radius", Data.BlastRadius, " m")
			State:AddNumber("Blast Energy", BulletData.FillerMass * ACF.HEPower, " kJ")
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
		ACF.RegisterAmmoDecal("ACF.Ammunition.HE", "damage/he_pen", "damage/he_rico")

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
		end

		-- Ammo menu graph: fragment penetration over distance from the detonation.
		function CLASS:PlotAmmoGraph(Panel, _, BulletData)
			local Damage     = ACF.Damage
			local PenText    = language.GetPhrase("acf.menu.ammo.penetration")
			-- Blast radius is display data, so it lives on GUIData rather than the bullet
			local BlastRadius = self.GUIData.BlastRadius -- Fragments reach zero velocity here; distance shares the same units
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
	end
end)