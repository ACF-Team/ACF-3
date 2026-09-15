local ACF   	= ACF
local Classes   = ACF.Classes

Classes.DefineClass("ACF.Ammunition.FLR", "ACF.Ammunition.AP", function(CLASS, BASE)
	CLASS.Name		 = "Flare"
	CLASS.SpawnIcon   = "acf/icons/shell_flare.png"
	CLASS.Description = "A countermeasure for infrared guided munitions."
	CLASS.Blacklist = ACF.GetWeaponBlacklist({
		["ACF.Guns.SmokeLauncher"] = true,
		["ACF.Guns.FlareLauncher"] = true,
	})

	MENU_FIELD("Number", "FillerRatio", {Default = 0})

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

	function CLASS:UpdateRoundData()
		local Data    = self.BulletData
		local GUIData = self.GUIData

		ACF.UpdateRoundSpecs(self)

		local FreeVol   = ACF.RoundShellCapacity(Data.PropMass, Data.ProjArea, Data.Caliber, Data.ProjLength)
		local FillerVol = FreeVol * self.FillerRatio
		Data.FillerMass	= FillerVol * ACF.HEDensity
		Data.ProjMass	= math.max(GUIData.ProjVolume - FillerVol, 0) * ACF.SteelDensity + Data.FillerMass
		Data.MuzzleVel	= ACF.MuzzleVelocity(Data.PropMass, Data.ProjMass, Data.Efficiency)
		Data.DragCoef	= Data.ProjArea * 0.0027 / Data.ProjMass
		Data.BurnTime	= Data.FillerMass / Data.BurnRate
		Data.CartMass	= Data.PropMass + Data.ProjMass

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
		Data.LimitVel		= 700 -- Most efficient penetration speed in m/s
		Data.KETransfert	= 0.1 -- Kinetic energy transfert to the target for movement purposes
		Data.Ricochet		= 75 -- Base ricochet angle
		Data.BurnRate		= Data.ProjArea * ACF.FlareBurnMultiplier
		Data.DistractChance	= (2 / math.pi) * math.atan(Data.ProjArea * ACF.FlareDistractMultiplier)	* 0.5 -- Reduced effectiveness 50% -red

		self:UpdateRoundData()

		return self.BulletData, self.GUIData
	end

	function CLASS:VerifyData()
		BASE.VerifyData(self)

		if not isnumber(self.FillerRatio) then self.FillerRatio = 0 end
	end

	-- Shared with the client so the spawn menu can price a crate without spawning it.
	local Conversion = ACF.PointConversion

	function CLASS:GetCost(BulletData)
		return ((BulletData.ProjMass - BulletData.FillerMass) * Conversion.Steel) + (BulletData.PropMass * Conversion.Propellant) + (BulletData.FillerMass * Conversion.FlareMix)
	end

	if SERVER then
		local Ballistics      = ACF.Ballistics
		local Clock           = ACF.Utilities.Clock
		local Countermeasures = ACF.Countermeasures



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

		function CLASS:OnCreateAmmoControls(Base)
			ACF.AmmoMenu.Slider(Base, "Filler Ratio", 0, 1, 2, "FillerRatio", function(Value)
				self.FillerRatio = math.Round(Value, 2)
				self:UpdateRoundData()
			end)
		end

		function CLASS:OnCreateAmmoInformation(Base, _, BulletData)
			local RoundStats = Base:AddLabel()
			ACF.AmmoMenu.Reactive(RoundStats, function()
				self:UpdateRoundData()

				local Text		= "Muzzle Velocity : %s m/s\nProjectile Mass : %s\nPropellant Mass : %s\nFlare Filler Mass : %s"
				local MuzzleVel	= math.Round(BulletData.MuzzleVel * ACF.Scale, 2)
				local ProjMass	= ACF.FormatMass(BulletData.ProjMass)
				local PropMass	= ACF.FormatMass(BulletData.PropMass)
				local Filler	= ACF.FormatMass(BulletData.FillerMass)

				RoundStats:SetText(Text:format(MuzzleVel, ProjMass, PropMass, Filler))
			end)

			local FillerStats = Base:AddLabel()
			ACF.AmmoMenu.Reactive(FillerStats, function()
				self:UpdateRoundData()

				local Text		= "Burn Rate : %s/s\nBurn Duration : %s s\nDistraction Chance : %s"
				local Rate		= ACF.FormatMass(BulletData.BurnRate)
				local Duration	= math.Round(BulletData.BurnTime, 2)
				local Chance	= math.Round(BulletData.DistractChance * 100, 2) .. "%"

				FillerStats:SetText(Text:format(Rate, Duration, Chance))
			end)
		end

		-- Ammo menu visual: casing plus a body split between the pyrotechnic filler and the steel shell
		-- wall/nose around it, matching the mass split in UpdateRoundData (ProjVolume - FillerVol is
		-- steel, the rest filler). No tracer segment, since flares don't have a tracer control.
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

			local FillerRatio = math.Clamp(ToolData.FillerRatio or 0, 0, 1)
			local FillerLenCm = BulletData.ProjLength * FillerRatio
			local SteelLenCm  = BulletData.ProjLength - FillerLenCm

			local Propellant = GeoPrim.New("Cylinder", { Radius = CaseDia * 0.5, Height = BulletData.PropLength })
			Propellant:SetMaterial("Propellant")

			local Filler = GeoPrim.New("Cylinder", { Radius = Radius, Height = FillerLenCm })
			Filler:SetMaterial("Pyrotechnic Filler (Flare Composition)")

			local ShellCasing = GeoPrim.New("Cylinder", { Radius = Radius, Height = SteelLenCm })
			ShellCasing:SetMaterial("Steel Shell Casing")

			local X = Margin
			X = Propellant:Draw(Panel, X, CenterY, Scale, DiameterPx, Color(180, 150, 60), Color(30, 30, 30))

			if FillerLenCm > 0 then
				X = Filler:Draw(Panel, X, CenterY, Scale, DiameterPx, Color(210, 80, 30), Color(30, 30, 30))
			end
			ShellCasing:Draw(Panel, X, CenterY, Scale, DiameterPx, Color(120, 120, 130), Color(30, 30, 30))
		end
	end
end)