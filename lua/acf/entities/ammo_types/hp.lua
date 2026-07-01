local ACF       = ACF
local Classes   = ACF.Classes

Classes.DefineClass("ACF.Ammunition.HP", "ACF.Ammunition.AP", function()
	local BASE = BASE

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

	if SERVER then
		local Conversion	= ACF.PointConversion

		function CLASS:GetCost(BulletData)
			local RemovedMass	= BulletData.CavVol * ACF.SteelDensity

			return (BulletData.ProjMass * Conversion.Steel) + (BulletData.PropMass * Conversion.Propellant) + (RemovedMass * Conversion.Steel * 0.25)
		end

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

		function CLASS:OnCreateAmmoControls(Base, _, BulletData)
			local HollowRatio = Base:AddSlider("#acf.menu.ammo.hollow_ratio", 0, 1, 2)
			HollowRatio:SetClientData("HollowRatio", "OnValueChanged")
			HollowRatio:DefineSetter(function(_, _, _, Value)
				self.HollowRatio = math.Round(Value, 2)

				self:UpdateRoundData()

				return BulletData.CavVol
			end)
		end

		function CLASS:OnCreateCrateInformation(Base, Label, ...)
			BASE.OnCreateCrateInformation(self, Base, Label, ...)

			Label:TrackClientData("HollowRatio")
		end

		function CLASS:OnCreateAmmoInformation(Base, _, BulletData)
			local RoundStats = Base:AddLabel()
			RoundStats:TrackClientData("Projectile", "SetText")
			RoundStats:TrackClientData("Propellant")
			RoundStats:TrackClientData("HollowRatio")
			RoundStats:DefineSetter(function()
				self:UpdateRoundData()

				local Text		= language.GetPhrase("acf.menu.ammo.round_stats_ap")
				local MuzzleVel	= math.Round(BulletData.MuzzleVel * ACF.Scale, 2)
				local ProjMass	= ACF.GetProperMass(BulletData.ProjMass)
				local PropMass	= ACF.GetProperMass(BulletData.PropMass)

				return Text:format(MuzzleVel, ProjMass, PropMass)
			end)

			local HollowStats = Base:AddLabel()
			HollowStats:TrackClientData("Projectile", "SetText")
			HollowStats:TrackClientData("Propellant")
			HollowStats:TrackClientData("HollowRatio")
			HollowStats:DefineSetter(function()
				self:UpdateRoundData()

				local Text	  = language.GetPhrase("acf.menu.ammo.hollow_stats_hp")
				local Caliber = math.Round(BulletData.Diameter * 10, 2)
				local Energy  = math.Round(self.GUIData.MaxKETransfert, 2)

				return Text:format(Caliber, Energy)
			end)

			local PenStats = Base:AddLabel()
			PenStats:TrackClientData("Projectile", "SetText")
			PenStats:TrackClientData("Propellant")
			PenStats:TrackClientData("HollowRatio")
			PenStats:DefineSetter(function()
				self:UpdateRoundData()

				local Text     = language.GetPhrase("acf.menu.ammo.pen_stats_ap")
				local MaxPen   = math.Round(self.GUIData.MaxPen, 2)
				local R1P, R1V = self:GetRangedPenetration(BulletData, 300)
				local R2V, R2P = self:GetRangedPenetration(BulletData, 800)

				return Text:format(MaxPen, R1P, R1V, R2P, R2V)
			end)

			Base:AddLabel("#acf.menu.ammo.approx_pen_warning")
		end
	end
end)