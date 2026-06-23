local ACF   	= ACF
local Classes   = ACF.Classes
Classes.DefineClass("ACF.Ammunition.HE", "ACF.Ammunition.APHE", function()
	local BASE = BASE

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

	function CLASS:UpdateRoundData(ToolData, Data, GUIData)
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

	function CLASS:BaseConvert(ToolData)
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

		function CLASS:GetCost(BulletData)
			return ((BulletData.ProjMass - BulletData.FillerMass) * Conversion.Steel) + (BulletData.PropMass * Conversion.Propellant) + (BulletData.FillerMass * Conversion.CompB)
		end

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

		function CLASS:OnCreateAmmoInformation(Base, ToolData, BulletData)
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
end)