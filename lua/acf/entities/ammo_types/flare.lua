local ACF   	= ACF
local Classes   = ACF.Classes

Classes.DefineClass("ACF.Ammunition.FLR", "ACF.Ammunition.AP", function()
	local BASE = BASE

	CLASS.Name		 = "Flare"
	CLASS.SpawnIcon   = "acf/icons/shell_flare.png"
	CLASS.Description = "A countermeasure for infrared guided munitions."
	CLASS.Blacklist = ACF.GetWeaponBlacklist({
		["ACF.Guns.SmokeLauncher"] = true,
		["ACF.Guns.FlareLauncher"] = true,
	})

	function CLASS:GetDisplayData(Data)
		local Display = {
			MaxPen         = 0,
			BurnRate       = Data.BurnRate,
			DistractChance = Data.DistractChance,
			BurnTime       = Data.BurnTime,
		}

		hook.Run("ACF_OnRequestDisplayData", self, Data, Display)

		return Display
	end

	function CLASS:UpdateRoundData(ToolData, Data, GUIData)
		GUIData = GUIData or Data

		ACF.UpdateRoundSpecs(ToolData, Data, GUIData)

		local FreeVol   = ACF.RoundShellCapacity(Data.PropMass, Data.ProjArea, Data.Caliber, Data.ProjLength)
		local FillerVol = FreeVol * ToolData.FillerRatio
		Data.FillerMass	= FillerVol * ACF.HEDensity
		Data.ProjMass	= math.max(GUIData.ProjVolume - FillerVol, 0) * ACF.SteelDensity + Data.FillerMass
		Data.MuzzleVel	= ACF.MuzzleVelocity(Data.PropMass, Data.ProjMass, Data.Efficiency)
		Data.DragCoef	= Data.ProjArea * 0.0027 / Data.ProjMass
		Data.BurnTime	= Data.FillerMass / Data.BurnRate
		Data.CartMass	= Data.PropMass + Data.ProjMass

		hook.Run("ACF_OnUpdateRound", self, ToolData, Data, GUIData)

		for K, V in pairs(self:GetDisplayData(Data)) do
			GUIData[K] = V
		end
	end

	function CLASS:BaseConvert(ToolData)
		local Data, GUIData = ACF.RoundBaseGunpowder(ToolData, {})

		GUIData.MinFillerVol = 0

		Data.ShovePower		= 0.1
		Data.LimitVel		= 700 -- Most efficient penetration speed in m/s
		Data.KETransfert	= 0.1 -- Kinetic energy transfert to the target for movement purposes
		Data.Ricochet		= 75 -- Base ricochet angle
		Data.BurnRate		= Data.ProjArea * ACF.FlareBurnMultiplier
		Data.DistractChance	= (2 / math.pi) * math.atan(Data.ProjArea * ACF.FlareDistractMultiplier)	* 0.5 -- Reduced effectiveness 50% -red

		self:UpdateRoundData(ToolData, Data, GUIData)

		return Data, GUIData
	end

	function CLASS:VerifyData(ToolData)
		BASE.VerifyData(self, ToolData)

		if not ToolData.FillerRatio then
			local Data5 = ToolData.RoundData5

			ToolData.FillerRatio = Data5 and tonumber(Data5) or 0
		end
	end

	if SERVER then
		local Ballistics      = ACF.Ballistics
		local Clock           = ACF.Utilities.Clock
		local Countermeasures = ACF.Classes.Countermeasures
		local Conversion	= ACF.PointConversion

		function CLASS:GetCost(BulletData)
			return ((BulletData.ProjMass - BulletData.FillerMass) * Conversion.Steel) + (BulletData.PropMass * Conversion.Propellant) + (BulletData.FillerMass * Conversion.FlareMix)
		end

		function CLASS:Create(_, BulletData)
			local Bullet = Ballistics.CreateBullet(BulletData)

			Bullet.CreateTime = Clock.CurTime

			Countermeasures.RegisterFlare(Bullet)
		end

		function CLASS:Network(Entity, BulletData)
			BASE.Network(self, Entity, BulletData)

			Entity:SetNW2String("AmmoType", "ACF.Ammunition.FLR")
			Entity:SetNW2Float("FillerMass", BulletData.FillerMass)
		end

		function CLASS:UpdateCrateOverlay(BulletData, State)
			local Data = self:GetDisplayData(BulletData)

			State:AddNumber("Muzzle Velocity", BulletData.MuzzleVel, " m/s")
			State:AddNumber("Burn Rate", Data.BurnRate, " kg/s")
			State:AddNumber("Burn Duration", Data.BurnTime, " s")
			State:AddNumber("Distract Chance", math.floor(Data.DistractChance * 100), "%")
		end

		function CLASS:PropImpact(_, Trace)
			if ACF.FlaresIgnite then
				local Target = Trace.Entity
				local Type = ACF.Check(Target)

				if Type == "Squishy" and ((Target:IsPlayer() and not Target:HasGodMode()) or Target:IsNPC()) then
					Target:Ignite(30)
				end
			end

			return false
		end

		function CLASS:WorldImpact()
			return false
		end
	else
		ACF.RegisterAmmoDecal("ACF.Ammunition.FLR", "damage/ap_pen", "damage/ap_rico")

		function CLASS:ImpactEffect()
		end

		function CLASS:PreCreateTracerControls()
			return false
		end

		function CLASS:OnCreateAmmoControls(Base, ToolData, BulletData)
			local FillerRatio = Base:AddSlider("Filler Ratio", 0, 1, 2)
			FillerRatio:SetClientData("FillerRatio", "OnValueChanged")
			FillerRatio:DefineSetter(function(_, _, Key, Value)
				if Key == "FillerRatio" then
					ToolData.FillerRatio = math.Round(Value, 2)
				end

				self:UpdateRoundData(ToolData, BulletData)

				return BulletData.FillerVol
			end)
		end

		function CLASS:OnCreateCrateInformation(Base, Label, ...)
			BASE.OnCreateCrateInformation(self, Base, Label, ...)

			Label:TrackClientData("FillerRatio")
		end

		function CLASS:OnCreateAmmoInformation(Base, ToolData, BulletData)
			local RoundStats = Base:AddLabel()
			RoundStats:TrackClientData("Projectile", "SetText")
			RoundStats:TrackClientData("Propellant")
			RoundStats:TrackClientData("FillerRatio")
			RoundStats:DefineSetter(function()
				self:UpdateRoundData(ToolData, BulletData)

				local Text		= "Muzzle Velocity : %s m/s\nProjectile Mass : %s\nPropellant Mass : %s\nFlare Filler Mass : %s"
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

				local Text		= "Burn Rate : %s/s\nBurn Duration : %s s\nDistraction Chance : %s"
				local Rate		= ACF.GetProperMass(BulletData.BurnRate)
				local Duration	= math.Round(BulletData.BurnTime, 2)
				local Chance	= math.Round(BulletData.DistractChance * 100, 2) .. "%"

				return Text:format(Rate, Duration, Chance)
			end)
		end
	end
end)