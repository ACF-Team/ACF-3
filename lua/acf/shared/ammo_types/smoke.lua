local Ammo = ACF.RegisterAmmoType("SM", "AP")

function Ammo:OnLoaded()
	self.Name		 = "Smoke"
	self.Description = "A shell filled white phosporous, detonating on impact. Smoke filler produces a long lasting cloud but takes a while to be effective, whereas WP filler quickly creates a cloud that also dissipates quickly."
	self.Blacklist = {
		AC = true,
		AL = true,
		GL = true,
		MG = true,
		SA = true,
		HMG = true,
		RAC = true,
	}
end

function Ammo:GetDisplayData(Data)
	local SMFiller = math.min(math.log(1 + Data.FillerMass * 8 * 39.37) * 43.4216, 350)
	local WPFiller = math.min(math.log(1 + Data.WPMass * 8 * 39.37) * 43.4216, 350)
	local Display  = {
		SMFiller    = SMFiller,
		SMLife      = math.Round(20 + SMFiller * 0.25, 2),
		SMRadiusMin = math.Round(SMFiller * 1.25 * 0.15 * 0.0254, 2),
		SMRadiusMax = math.Round(SMFiller * 1.25 * 2 * 0.0254, 2),
		WPFiller    = WPFiller,
		WPLife      = math.Round(6 + WPFiller * 0.1, 2),
		WPRadiusMin = math.Round(WPFiller * 1.25 * 0.0254, 2),
		WPRadiusMax = math.Round(WPFiller * 1.25 * 2 * 0.0254, 2),
	}

	hook.Run("ACF_GetDisplayData", self, Data, Display)

	return Display
end

function Ammo:UpdateRoundData(ToolData, Data, GUIData)
	GUIData = GUIData or Data

	ACF.UpdateRoundSpecs(ToolData, Data, GUIData)

	Data.FillerPriority = Data.FillerPriority or "Smoke"

	-- Volume of the projectile as a cylinder - Volume of the filler * density of steel + Volume of the filler * density of TNT
	local ProjMass	  = math.max(GUIData.ProjVolume - ToolData.SmokeFiller, 0) * 0.0079 + math.min(ToolData.SmokeFiller, GUIData.ProjVolume) * ACF.HEDensity * 0.0005
	local MuzzleVel	  = ACF_MuzzleVelocity(Data.PropMass, ProjMass)
	local Energy	  = ACF_Kinetic(MuzzleVel * 39.37, ProjMass, Data.LimitVel)
	local MaxCapacity = ACF.RoundShellCapacity(Energy.Momentum, Data.FrArea, Data.Caliber, Data.ProjLength)
	local MaxVolume	  = math.Round(math.min(GUIData.ProjVolume, MaxCapacity), 2)
	local SmokeFiller = math.Clamp(ToolData.SmokeFiller, GUIData.MinFillerVol, MaxVolume)
	local WPFiller	  = math.Clamp(ToolData.WPFiller, GUIData.MinFillerVol, MaxVolume)

	if Data.FillerPriority == "Smoke" then
		WPFiller = math.Clamp(WPFiller, 0, MaxVolume - SmokeFiller)
	elseif Data.FillerPriority == "WP" then
		SmokeFiller = math.Clamp(SmokeFiller, 0, MaxVolume - WPFiller)
	end

	GUIData.MaxFillerVol = MaxVolume
	GUIData.FillerVol	 = math.Round(SmokeFiller, 2)
	GUIData.WPVol		 = math.Round(WPFiller, 2)

	Data.FillerMass	= GUIData.FillerVol * ACF.HEDensity * 0.0005
	Data.WPMass		= GUIData.WPVol * ACF.HEDensity * 0.0005
	Data.ProjMass	= math.max(GUIData.ProjVolume - (GUIData.FillerVol + GUIData.WPVol), 0) * 0.0079 + Data.FillerMass + Data.WPMass
	Data.MuzzleVel	= ACF_MuzzleVelocity(Data.PropMass, Data.ProjMass)
	Data.DragCoef	= Data.FrArea * 0.0001 / Data.ProjMass
	Data.CartMass	= Data.PropMass + Data.ProjMass

	hook.Run("ACF_UpdateRoundData", self, ToolData, Data, GUIData)

	for K, V in pairs(self:GetDisplayData(Data)) do
		GUIData[K] = V
	end
end

function Ammo:BaseConvert(ToolData)
	local Data, GUIData = ACF.RoundBaseGunpowder(ToolData, {})

	GUIData.MinFillerVol = 0

	Data.ShovePower		= 0.1
	Data.PenArea		= Data.FrArea ^ ACF.PenAreaMod
	Data.LimitVel		= 100 --Most efficient penetration speed in m/s
	Data.KETransfert	= 0.1 --Kinetic energy transfert to the target for movement purposes
	Data.Ricochet		= 60 --Base ricochet angle
	Data.DetonatorAngle	= 80
	Data.CanFuze		= Data.Caliber * 10 > ACF.MinFuzeCaliber -- Can fuze on calibers > 20mm

	self:UpdateRoundData(ToolData, Data, GUIData)

	return Data, GUIData
end

function Ammo:VerifyData(ToolData)
	Ammo.BaseClass.VerifyData(self, ToolData)

	if not ToolData.SmokeFiller then
		local Data5 = ToolData.RoundData5

		ToolData.SmokeFiller = Data5 and tonumber(Data5) or 0
	end

	if not ToolData.WPFiller then
		local Data6 = ToolData.RoundData6

		ToolData.WPFiller = Data6 and tonumber(Data6) or 0
	end
end

if SERVER then
	ACF.AddEntityArguments("acf_ammo", "SmokeFiller", "WPFiller") -- Adding extra info to ammo crates

	function Ammo:OnLast(Entity)
		Ammo.BaseClass.OnLast(self, Entity)

		Entity.SmokeFiller = nil
		Entity.WPFiller = nil

		-- Cleanup the leftovers aswell
		Entity.RoundData5 = nil
		Entity.RoundData6 = nil

		Entity:SetNW2Float("FillerMass", 0)
		Entity:SetNW2Float("WPMass", 0)
	end

	function Ammo:Network(Entity, BulletData)
		Ammo.BaseClass.Network(self, Entity, BulletData)

		Entity:SetNW2String("AmmoType", "SM")
		Entity:SetNW2Float("FillerMass", BulletData.FillerMass)
		Entity:SetNW2Float("WPMass", BulletData.WPMass)
	end

	function Ammo:GetCrateText(BulletData)
		local Text = "Muzzle Velocity: %s m/s%s%s"
		local Data = self:GetDisplayData(BulletData)
		local WPText, SMText = "", ""


		if Data.WPFiller > 0 then
			local Template = "\nWP Radius: %s m to %s m\nWP Lifetime: %s s"

			WPText = Template:format(Data.WPRadiusMin, Data.WPRadiusMax, Data.WPLife)
		end

		if Data.SMFiller > 0 then
			local Template = "\nSM Radius: %s m to %s m\nSM Lifetime: %s s"

			SMText = Template:format(Data.SMRadiusMin, Data.SMRadiusMax, Data.SMLife)
		end

		return Text:format(math.Round(BulletData.MuzzleVel, 2), WPText, SMText)
	end

	function Ammo:PropImpact(Bullet, Trace)
		local Target = Trace.Entity

		if ACF.Check(Target) then
			local Speed  = Bullet.Flight:Length() / ACF.Scale
			local Energy = ACF_Kinetic(Speed, Bullet.ProjMass - (Bullet.FillerMass + Bullet.WPMass), Bullet.LimitVel)
			local HitRes = ACF_RoundImpact(Bullet, Speed, Energy, Target, Trace.HitPos, Trace.HitNormal, Trace.HitGroup)

			if HitRes.Ricochet then return "Ricochet" end
		end

		return false
	end

	function Ammo:WorldImpact()
		return false
	end
else
	ACF.RegisterAmmoDecal("SM", "damage/he_pen", "damage/he_rico")

	function Ammo:ImpactEffect(_, Bullet)
		local Crate = Bullet.Crate
		local Color = IsValid(Crate) and Crate:GetColor() or Color(255, 255, 255)

		local Effect = EffectData()
		Effect:SetOrigin(Bullet.SimPos)
		Effect:SetNormal(Bullet.SimFlight:GetNormalized())
		Effect:SetScale(math.max(Bullet.FillerMass * 8 * 39.37, 0))
		Effect:SetMagnitude(math.max(Bullet.WPMass * 8 * 39.37, 0))
		Effect:SetStart(Vector(Color.r, Color.g, Color.b))
		Effect:SetRadius(Bullet.Caliber)

		util.Effect("ACF_Smoke", Effect)
	end

	function Ammo:AddAmmoControls(Base, ToolData, BulletData)
		local SmokeFiller = Base:AddSlider("Smoke Filler", BulletData.MinFillerVol, BulletData.MaxFillerVol, 2)
		SmokeFiller:SetClientData("SmokeFiller", "OnValueChanged")
		SmokeFiller:TrackClientData("Projectile")
		SmokeFiller:TrackClientData("WPFiller")
		SmokeFiller:DefineSetter(function(Panel, _, Key, Value, IsTracked)
			if Key == "SmokeFiller" then
				ToolData.SmokeFiller = math.Round(Value, 2)

				if not IsTracked then
					BulletData.FillerPriority = "Smoke"
				end
			end

			self:UpdateRoundData(ToolData, BulletData)

			Panel:SetMax(BulletData.MaxFillerVol)
			Panel:SetValue(BulletData.FillerVol)

			return BulletData.FillerVol
		end)

		local WPFiller = Base:AddSlider("WP Filler", BulletData.MinFillerVol, BulletData.MaxFillerVol, 2)
		WPFiller:SetClientData("WPFiller", "OnValueChanged")
		WPFiller:TrackClientData("SmokeFiller")
		WPFiller:TrackClientData("Projectile")
		WPFiller:DefineSetter(function(Panel, _, Key, Value, IsTracked)
			if Key == "WPFiller" then
				ToolData.WPFiller = math.Round(Value, 2)

				if not IsTracked then
					BulletData.FillerPriority = "WP"
				end
			end

			self:UpdateRoundData(ToolData, BulletData)

			Panel:SetMax(BulletData.MaxFillerVol)
			Panel:SetValue(BulletData.WPVol)

			return BulletData.WPVol
		end)
	end

	function Ammo:AddCrateDataTrackers(Trackers, ...)
		Ammo.BaseClass.AddCrateDataTrackers(self, Trackers, ...)

		Trackers.SmokeFiller = true
		Trackers.WPFiller = true
	end

	function Ammo:AddAmmoInformation(Menu, ToolData, Data)
		local RoundStats = Menu:AddLabel()
		RoundStats:TrackClientData("Projectile", "SetText")
		RoundStats:TrackClientData("Propellant")
		RoundStats:TrackClientData("SmokeFiller")
		RoundStats:TrackClientData("WPFiller")
		RoundStats:DefineSetter(function()
			self:UpdateRoundData(ToolData, Data)

			local Text		= "Muzzle Velocity : %s m/s\nProjectile Mass : %s\nPropellant Mass : %s"
			local MuzzleVel	= math.Round(Data.MuzzleVel * ACF.Scale, 2)
			local ProjMass	= ACF.GetProperMass(Data.ProjMass)
			local PropMass	= ACF.GetProperMass(Data.PropMass)

			return Text:format(MuzzleVel, ProjMass, PropMass)
		end)

		local SmokeStats = Menu:AddLabel()
		SmokeStats:TrackClientData("SmokeFiller", "SetText")
		SmokeStats:TrackClientData("WPFiller")
		SmokeStats:DefineSetter(function()
			self:UpdateRoundData(ToolData, Data)

			local SMText, WPText = "", ""

			if Data.FillerMass > 0 then
				local Text		  = "Smoke Filler Mass : %s\nSmoke Filler Radius : %s m\nSmoke Filler Life : %s s\n"
				local SmokeMass	  = ACF.GetProperMass(Data.FillerMass)
				local SmokeRadius = (Data.SMRadiusMin + Data.SMRadiusMax) * 0.5

				SMText = Text:format(SmokeMass, SmokeRadius, Data.SMLife)
			end

			if Data.WPMass > 0 then
				local Text	   = "WP Filler Mass : %s\nWP Filler Radius : %s m\nWP Filler Life : %s s"
				local WPMass   = ACF.GetProperMass(Data.WPMass)
				local WPRadius = (Data.WPRadiusMin + Data.WPRadiusMax) * 0.5

				WPText = Text:format(WPMass, WPRadius, Data.WPLife)
			end

			return SMText .. WPText
		end)
	end
end
