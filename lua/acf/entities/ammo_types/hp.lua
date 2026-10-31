local ACF       = ACF
local Classes   = ACF.Classes

Classes.DefineClass("ACF.Ammunition.HP", "ACF.Ammunition.AP", function(CLASS, BASE)
	CLASS.Name		 = "Hollow Point"
	CLASS.SpawnIcon   = "acf/icons/shell_hp.png"
	CLASS.Bodygroup   = 0 -- Use AP bodygroup (no specific HP variant)
	CLASS.Description = "#acf.descs.ammo.hp"
	CLASS.Blacklist = ACF.GetWeaponBlacklist({
		["ACF.Guns.Machinegun"] = true,
	})

	MENU_FIELD("Number", "HollowRatio", {Default = 0})

	function CLASS:GetDisplayData(Data)
		local Display = BASE.GetDisplayData(self, Data)
		local Energy  = ACF.Kinetic(Data.MuzzleVel * ACF.MeterToInch, Data.ProjMass)

		Display.MaxKETransfert = Energy.Kinetic * Data.ShovePower

		hook.Run("ACF_OnRequestDisplayData", self, Data, Display)

		return Display
	end

	function CLASS:UpdateRoundData()
		local Data    = self.BulletData
		local GUIData = self.GUIData

		ACF.UpdateRoundSpecs(self)

		local FreeVol      = ACF.RoundShellCapacity(Data.PropMass, Data.ProjArea, Data.Caliber, Data.ProjLength)
		local HollowCavity = FreeVol * math.Clamp(self.HollowRatio, 0, 1)
		local ExpRatio     = HollowCavity / GUIData.ProjVolume

		Data.CavVol     = HollowCavity
		Data.ProjMass   = (Data.ProjArea * Data.ProjLength - HollowCavity) * ACF.SteelDensity --Volume of the projectile as a cylinder * fraction missing due to hollow point (Data5) * density of steel
		Data.MuzzleVel  = ACF.MuzzleVelocity(Data.PropMass, Data.ProjMass, Data.Efficiency)
		Data.ShovePower = 0.2 + ExpRatio * 0.5
		Data.Diameter   = Data.Caliber + ExpRatio * Data.ProjLength
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

		Data.LimitVel = 400 --Most efficient penetration speed in m/s
		Data.Ricochet = 90 --Base ricochet angle

		self:UpdateRoundData()

		return self.BulletData, self.GUIData
	end

	function CLASS:VerifyData()
		BASE.VerifyData(self)

		if not isnumber(self.HollowRatio) then
			self.HollowRatio = 0.5
		end
	end

	-- Shared with the client so the spawn menu can price a crate without spawning it.
	local Conversion = ACF.PointConversion

	function CLASS:GetCost(BulletData)
		local RemovedMass	= BulletData.CavVol * ACF.SteelDensity

		return (BulletData.ProjMass * Conversion.Steel) + (BulletData.PropMass * Conversion.Propellant) + (RemovedMass * Conversion.Steel * 0.25)
	end

	if SERVER then



		function CLASS:OnLast(Entity)
			BASE.OnLast(self, Entity)

			Entity.HollowRatio = nil

			-- Cleanup the leftovers aswell
			Entity.HollowCavity = nil
			Entity.RoundData5   = nil
		end

		function CLASS:Network(Entity, BulletData)
			BASE.Network(self, Entity, BulletData)

			Entity:SetNW2String("AmmoType", "ACF.Ammunition.HP")
		end

		function CLASS:UpdateCrateOverlay(BulletData, State)
			BASE.UpdateCrateOverlay(self, BulletData, State)
			local Data = self:GetDisplayData(BulletData)
			State:AddNumber("Expanded Caliber", BulletData.Diameter * 10, " mm")
			State:AddNumber("Imparted Energy", Data.MaxKETransfert, " kJ")
		end
	else
		ACF.RegisterAmmoDecal("ACF.Ammunition.HP", "damage/ap_pen", "damage/ap_rico")

		function CLASS:OnCreateAmmoControls(Base)
			ACF.AmmoMenu.Slider(Base, "#acf.menu.ammo.hollow_ratio", 0, 1, 2, "HollowRatio", function(Value)
				self.HollowRatio = math.Round(Value, 2)
				self:UpdateRoundData()
			end)
		end

		function CLASS:OnCreateAmmoInformation(Base, _, BulletData)
			local RoundStats = Base:AddLabel()
			ACF.AmmoMenu.Reactive(RoundStats, function()
				self:UpdateRoundData()

				local Text		= language.GetPhrase("acf.menu.ammo.round_stats_ap")
				local MuzzleVel	= math.Round(BulletData.MuzzleVel * ACF.Scale, 2)
				local ProjMass	= ACF.FormatMass(BulletData.ProjMass)
				local PropMass	= ACF.FormatMass(BulletData.PropMass)

				RoundStats:SetText(Text:format(MuzzleVel, ProjMass, PropMass))
			end)

			local HollowStats = Base:AddLabel()
			ACF.AmmoMenu.Reactive(HollowStats, function()
				self:UpdateRoundData()

				local Text	  = language.GetPhrase("acf.menu.ammo.hollow_stats_hp")
				local Caliber = math.Round(BulletData.Diameter * 10, 2)
				local Energy  = math.Round(self.GUIData.MaxKETransfert, 2)

				HollowStats:SetText(Text:format(Caliber, Energy))
			end)

			local PenStats = Base:AddLabel()
			ACF.AmmoMenu.Reactive(PenStats, function()
				self:UpdateRoundData()

				local Text     = language.GetPhrase("acf.menu.ammo.pen_stats_ap")
				local MaxPen   = math.Round(self.GUIData.MaxPen, 2)
				local R1P, R1V = self:GetRangedPenetration(BulletData, 300)
				local R2V, R2P = self:GetRangedPenetration(BulletData, 800)

				PenStats:SetText(Text:format(MaxPen, R1P, R1V, R2P, R2V))
			end)

			Base:AddLabel("#acf.menu.ammo.approx_pen_warning")
		end

		-- Ammo menu visual: a steel penetrator with a hollow cavity drilled into the nose, sized from
		-- ToolData.HollowRatio. Uses BulletData.Caliber for the body width rather than BulletData.Diameter --
		-- that field is overloaded by UpdateRoundData to mean the round's *expanded* post-impact diameter
		-- for the penetration formula, not the physical width of the unfired round.
		function CLASS:DrawAmmoVisual(Panel, w, h, ToolData, BulletData)
			local GeoPrim  = ACF.GeoPrim
			local Margin   = 10
			local DrawW    = w - Margin * 2
			local Diameter = BulletData.Caliber
			local Radius   = Diameter * 0.5

			local Length = BulletData.ProjLength + BulletData.PropLength

			if Length <= 0 then return end

			-- Cap Scale by the case, the widest part, so the case/bore step survives the height budget
			local CaseDia = BulletData.CaseDiameter

			if CaseDia <= 0 then return end

			local Scale      = math.min(DrawW / Length, ((h - Margin * 2) * 0.6) / CaseDia)
			local DiameterPx = CaseDia * Scale
			local CenterY    = h * 0.5

			local Propellant = GeoPrim.New("Cylinder", { Radius = CaseDia * 0.5, Height = BulletData.PropLength })
			Propellant:SetMaterial("Propellant")

			local Penetrator = GeoPrim.New("Cylinder", { Radius = Radius, Height = BulletData.ProjLength })
			Penetrator:SetMaterial("Steel Penetrator")

			-- Hollow point cavity: a notch drilled into the tip, sized off ToolData.HollowRatio. Apex
			-- (Radius 0) buried CavityDepth behind the tip, mouth opening flush with the body's flat face.
			local HollowRatio = math.Clamp(ToolData.HollowRatio or 0, 0, 1)

			if HollowRatio > 0 then
				local CavityDepthCm = Diameter * 0.8 * HollowRatio * 0.8
				local Cavity = GeoPrim.New("Cone", { Radius = 0, TipRadius = Diameter * 0.3, Height = CavityDepthCm })
				Cavity:SetVoid(true):SetMaterial("Hollow Cavity (Air)")
				Penetrator:AddChild(Cavity, BulletData.ProjLength - CavityDepthCm)
			end

			local X = Margin
			X = Propellant:Draw(Panel, X, CenterY, Scale, DiameterPx, Color(180, 150, 60), Color(30, 30, 30))
			local BodyStartX = X
			Penetrator:Draw(Panel, X, CenterY, Scale, DiameterPx, Color(120, 120, 130), Color(30, 30, 30))

			-- Tracer, a colored segment at the base of the projectile, drawn last (and not as a Body child --
			-- Draw() paints an entire subtree in one Color, so a child never gets a color of its own) so it
			-- takes hover priority and actually renders red instead of inheriting the penetrator's gray.
			if BulletData.Tracer and BulletData.Tracer > 0 then
				local Tracer = GeoPrim.New("Cylinder", { Radius = Radius, Height = BulletData.Tracer })
				Tracer:SetMaterial("Tracer")
				Tracer:Draw(Panel, BodyStartX, CenterY, Scale, DiameterPx, Color(220, 40, 30), Color(30, 30, 30))
			end
		end
	end
end)