local Ammo = ACF.RegisterAmmoType("SM", "AP")

function Ammo:OnLoaded()
	self.Name		 = "Smoke"
	self.Description = "A shell filled white phosporous, detonating on impact. Smoke filler produces a long lasting cloud but takes a while to be effective, whereas WP filler quickly creates a cloud that also dissipates quickly."
	self.Blacklist = {
		C = true,
		AC = true,
		AL = true,
		GL = true,
		MG = true,
		SA = true,
		SC = true,
		HMG = true,
		RAC = true,
	}
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

	Data.FuseLength	= math.Clamp(ToolData.FuzeLength, GUIData.MinFuzeTime, GUIData.MaxFuzeTime)
	Data.FillerMass	= GUIData.FillerVol * ACF.HEDensity * 0.0005
	Data.WPMass		= GUIData.WPVol * ACF.HEDensity * 0.0005
	Data.ProjMass	= math.max(GUIData.ProjVolume - (GUIData.FillerVol + GUIData.WPVol), 0) * 0.0079 + Data.FillerMass + Data.WPMass
	Data.MuzzleVel	= ACF_MuzzleVelocity(Data.PropMass, Data.ProjMass)
	Data.DragCoef	= Data.FrArea * 0.0001 / Data.ProjMass

	for K, V in pairs(self:GetDisplayData(Data)) do
		GUIData[K] = V
	end
end

function Ammo:BaseConvert(_, ToolData)
	if not ToolData.Projectile then ToolData.Projectile = 0 end
	if not ToolData.Propellant then ToolData.Propellant = 0 end
	if not ToolData.SmokeFiller then ToolData.SmokeFiller = 0 end
	if not ToolData.WPFiller then ToolData.WPFiller = 0 end
	if not ToolData.FuzeLength then ToolData.FuzeLength = 0 end

	local Data, GUIData = ACF.RoundBaseGunpowder(ToolData, {})

	GUIData.MinFuzeTime	 = 0
	GUIData.MaxFuzeTime	 = 1
	GUIData.MinFillerVol = 0

	Data.ShovePower		= 0.1
	Data.PenArea		= Data.FrArea ^ ACF.PenAreaMod
	Data.LimitVel		= 100 --Most efficient penetration speed in m/s
	Data.KETransfert	= 0.1 --Kinetic energy transfert to the target for movement purposes
	Data.Ricochet		= 60 --Base ricochet angle
	Data.DetonatorAngle	= 80
	Data.CanFuze		= Data.Caliber > 20 -- Can fuze on calibers > 20mm

	self:UpdateRoundData(ToolData, Data, GUIData)

	return Data, GUIData
end

function Ammo:Network(Crate, BulletData)
	Crate:SetNW2String("AmmoType", "SM")
	Crate:SetNW2String("AmmoID", BulletData.Id)
	Crate:SetNW2Float("Caliber", BulletData.Caliber)
	Crate:SetNW2Float("ProjMass", BulletData.ProjMass)
	Crate:SetNW2Float("FillerMass", BulletData.FillerMass)
	Crate:SetNW2Float("WPMass", BulletData.WPMass)
	Crate:SetNW2Float("PropMass", BulletData.PropMass)
	Crate:SetNW2Float("DragCoef", BulletData.DragCoef)
	Crate:SetNW2Float("MuzzleVel", BulletData.MuzzleVel)
	Crate:SetNW2Float("Tracer", BulletData.Tracer)
end

function Ammo:GetDisplayData(Data)
	local SMFiller = math.min(math.log(1 + Data.FillerMass * 8 * 39.37) * 43.4216, 350)
	local WPFiller = math.min(math.log(1 + Data.WPMass * 8 * 39.37) * 43.4216, 350)

	return {
		SMFiller	= SMFiller,
		SMLife		= math.Round(20 + SMFiller * 0.25, 2),
		SMRadiusMin	= math.Round(SMFiller * 1.25 * 0.15 * 0.0254, 2),
		SMRadiusMax	= math.Round(SMFiller * 1.25 * 2 * 0.0254, 2),
		WPFiller	= WPFiller,
		WPLife		= math.Round(6 + WPFiller * 0.1, 2),
		WPRadiusMin	= math.Round(WPFiller * 1.25 * 0.0254, 2),
		WPRadiusMax	= math.Round(WPFiller * 1.25 * 2 * 0.0254, 2),
	}
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

function Ammo:PropImpact(_, Bullet, Target, HitNormal, HitPos, Bone)
	if ACF_Check(Target) then
		local Speed  = Bullet.Flight:Length() / ACF.Scale
		local Energy = ACF_Kinetic(Speed, Bullet.ProjMass - (Bullet.FillerMass + Bullet.WPMass), Bullet.LimitVel)
		local HitRes = ACF_RoundImpact(Bullet, Speed, Energy, Target, HitPos, HitNormal, Bone)

		if HitRes.Ricochet then return "Ricochet" end
	end

	return false
end

function Ammo:WorldImpact()
	return false
end

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

function Ammo:MenuAction(Menu, ToolData, Data)
	local SmokeFiller = Menu:AddSlider("Smoke Filler", Data.MinFillerVol, Data.MaxFillerVol, 2)
	SmokeFiller:SetDataVar("SmokeFiller", "OnValueChanged")
	SmokeFiller:TrackDataVar("Projectile")
	SmokeFiller:TrackDataVar("WPFiller")
	SmokeFiller:SetValueFunction(function(Panel, IsTracked)
		ToolData.SmokeFiller = math.Round(ACF.ReadNumber("SmokeFiller"), 2)

		if not IsTracked then
			Data.FillerPriority = "Smoke"
		end

		self:UpdateRoundData(ToolData, Data)

		Panel:SetMax(Data.MaxFillerVol)
		Panel:SetValue(Data.FillerVol)

		return Data.FillerVol
	end)

	local WPFiller = Menu:AddSlider("WP Filler", Data.MinFillerVol, Data.MaxFillerVol, 2)
	WPFiller:SetDataVar("WPFiller", "OnValueChanged")
	WPFiller:TrackDataVar("SmokeFiller")
	WPFiller:TrackDataVar("Projectile")
	WPFiller:SetValueFunction(function(Panel, IsTracked)
		ToolData.WPFiller = math.Round(ACF.ReadNumber("WPFiller"), 2)

		if not IsTracked then
			Data.FillerPriority = "WP"
		end

		self:UpdateRoundData(ToolData, Data)

		Panel:SetMax(Data.MaxFillerVol)
		Panel:SetValue(Data.WPVol)

		return Data.WPVol
	end)

	local FuzeLength = Menu:AddSlider("Fuze Delay", Data.MinFuzeTime, Data.MaxFuzeTime, 2)
	FuzeLength:SetDataVar("FuzeLength", "OnValueChanged")
	FuzeLength:SetValueFunction(function(Panel)
		ToolData.FuzeLength = math.Round(ACF.ReadNumber("FuzeLength"), 2)

		self:UpdateRoundData(ToolData, Data)

		Panel:SetValue(Data.FuseLength)

		return Data.FuseLength
	end)

	local Tracer = Menu:AddCheckBox("Tracer")
	Tracer:SetDataVar("Tracer", "OnChange")
	Tracer:SetValueFunction(function(Panel)
		ToolData.Tracer = ACF.ReadBool("Tracer")

		self:UpdateRoundData(ToolData, Data)

		ACF.WriteValue("Projectile", Data.ProjLength)
		ACF.WriteValue("Propellant", Data.PropLength)

		Panel:SetText("Tracer : " .. Data.Tracer .. " cm")
		Panel:SetValue(ToolData.Tracer)

		return ToolData.Tracer
	end)

	local RoundStats = Menu:AddLabel()
	RoundStats:TrackDataVar("Projectile", "SetText")
	RoundStats:TrackDataVar("Propellant")
	RoundStats:TrackDataVar("SmokeFiller")
	RoundStats:TrackDataVar("WPFiller")
	RoundStats:SetValueFunction(function()
		self:UpdateRoundData(ToolData, Data)

		local Text		= "Muzzle Velocity : %s m/s\nProjectile Mass : %s\nPropellant Mass : %s"
		local MuzzleVel	= math.Round(Data.MuzzleVel * ACF.Scale, 2)
		local ProjMass	= ACF.GetProperMass(Data.ProjMass)
		local PropMass	= ACF.GetProperMass(Data.PropMass)

		return Text:format(MuzzleVel, ProjMass, PropMass)
	end)

	local SmokeStats = Menu:AddLabel()
	SmokeStats:TrackDataVar("SmokeFiller", "SetText")
	SmokeStats:TrackDataVar("WPFiller")
	SmokeStats:SetValueFunction(function()
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

ACF.RegisterAmmoDecal("SM", "damage/he_pen", "damage/he_rico")
