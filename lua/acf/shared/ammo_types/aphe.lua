local Ammo = ACF.RegisterAmmoType("APHE", "AP")

function Ammo:OnLoaded()
	Ammo.BaseClass.OnLoaded(self)

	self.Name		 = "Armor Piercing High Explosive"
	self.Description = "Less capable armor piercing round with an explosive charge inside."
	self.Blacklist = {
		MG = true,
		MO = true,
		SL = true,
		RAC = true,
	}
end

function Ammo:UpdateRoundData(ToolData, Data, GUIData)
	GUIData = GUIData or Data

	ACF.UpdateRoundSpecs(ToolData, Data, GUIData)

	local HEDensity	= ACF.HEDensity * 0.001
	--Volume of the projectile as a cylinder - Volume of the filler * density of steel + Volume of the filler * density of TNT
	local ProjMass	= math.max(GUIData.ProjVolume - ToolData.FillerMass, 0) * 0.0079 + math.min(ToolData.FillerMass, GUIData.ProjVolume) * HEDensity
	local MuzzleVel	= ACF_MuzzleVelocity(Data.PropMass, ProjMass)
	local Energy	= ACF_Kinetic(MuzzleVel * 39.37, ProjMass, Data.LimitVel)
	local MaxVol	= ACF.RoundShellCapacity(Energy.Momentum, Data.FrArea, Data.Caliber, Data.ProjLength)

	GUIData.MaxFillerVol = math.Round(math.min(GUIData.ProjVolume, MaxVol * 0.9), 2)
	GUIData.FillerVol	 = math.min(ToolData.FillerMass, GUIData.MaxFillerVol)

	Data.FillerMass	= GUIData.FillerVol * HEDensity
	Data.ProjMass	= math.max(GUIData.ProjVolume - GUIData.FillerVol, 0) * 0.0079 + Data.FillerMass
	Data.MuzzleVel	= ACF_MuzzleVelocity(Data.PropMass, Data.ProjMass)
	Data.DragCoef	= Data.FrArea * 0.0001 / Data.ProjMass

	for K, V in pairs(self:GetDisplayData(Data)) do
		GUIData[K] = V
	end
end

function Ammo:BaseConvert(_, ToolData)
	if not ToolData.Projectile then ToolData.Projectile = 0 end
	if not ToolData.Propellant then ToolData.Propellant = 0 end
	if not ToolData.FillerMass then ToolData.FillerMass = 0 end

	local Data, GUIData = ACF.RoundBaseGunpowder(ToolData, {})

	GUIData.MinFillerVol = 0
	Data.ShovePower		 = 0.1
	Data.PenArea		 = Data.FrArea ^ ACF.PenAreaMod
	Data.LimitVel		 = 700 --Most efficient penetration speed in m/s
	Data.KETransfert	 = 0.1 --Kinetic energy transfert to the target for movement purposes
	Data.Ricochet		 = 65 --Base ricochet angle

	self:UpdateRoundData(ToolData, Data, GUIData)

	return Data, GUIData
end

function Ammo:Network(Crate, BulletData)
	Crate:SetNW2String("AmmoType", "APHE")
	Crate:SetNW2String("AmmoID", BulletData.Id)
	Crate:SetNW2Float("Caliber", BulletData.Caliber)
	Crate:SetNW2Float("ProjMass", BulletData.ProjMass)
	Crate:SetNW2Float("FillerMass", BulletData.FillerMass)
	Crate:SetNW2Float("PropMass", BulletData.PropMass)
	Crate:SetNW2Float("DragCoef", BulletData.DragCoef)
	Crate:SetNW2Float("MuzzleVel", BulletData.MuzzleVel)
	Crate:SetNW2Float("Tracer", BulletData.Tracer)
end

function Ammo:GetDisplayData(BulletData)
	local Data	   = Ammo.BaseClass.GetDisplayData(self, BulletData)
	local FragMass = BulletData.ProjMass - BulletData.FillerMass

	Data.BlastRadius = BulletData.FillerMass ^ 0.33 * 8
	Data.Fragments	 = math.max(math.floor((BulletData.FillerMass / FragMass) * ACF.HEFrag), 2)
	Data.FragMass	 = FragMass / Data.Fragments
	Data.FragVel	 = (BulletData.FillerMass * ACF.HEPower * 1000 / Data.FragMass / Data.Fragments) ^ 0.5

	return Data
end

function Ammo:GetCrateText(BulletData)
	local BaseText = Ammo.BaseClass.GetCrateText(self, BulletData)
	local Text	   = BaseText .. "\nBlast Radius: %s m\nBlast Energy: %s KJ"
	local Data	   = self:GetDisplayData(BulletData)

	return Text:format(math.Round(Data.BlastRadius, 2), math.Round(BulletData.FillerMass * ACF.HEPower, 2))
end

function Ammo:GetToolData()
	local Data		= Ammo.BaseClass.GetToolData(self)
	Data.FillerMass	= ACF.ReadNumber("FillerMass")

	return Data
end

function Ammo:OnFlightEnd(Index, Bullet, HitPos)
	ACF_HE(HitPos - Bullet.Flight:GetNormalized() * 3, Bullet.FillerMass, Bullet.ProjMass - Bullet.FillerMass, Bullet.Owner, nil, Bullet.Gun)

	Ammo.BaseClass.OnFlightEnd(self, Index, Bullet, Hitpos)
end

function Ammo:ImpactEffect(_, Bullet)
	local Effect = EffectData()
	Effect:SetOrigin(Bullet.SimPos)
	Effect:SetNormal(Bullet.SimFlight:GetNormalized())
	Effect:SetScale(math.max(Bullet.FillerMass ^ 0.33 * 8 * 39.37, 1))
	Effect:SetRadius(Bullet.Caliber)

	util.Effect("ACF_Explosion", Effect)
end

function Ammo:MenuAction(Menu, ToolData, Data)
	local FillerMass = Menu:AddSlider("Filler Volume", 0, Data.MaxFillerVol, 2)
	FillerMass:SetDataVar("FillerMass", "OnValueChanged")
	FillerMass:TrackDataVar("Projectile")
	FillerMass:SetValueFunction(function(Panel)
		ToolData.FillerMass = math.Round(ACF.ReadNumber("FillerMass"), 2)

		self:UpdateRoundData(ToolData, Data)

		Panel:SetMax(Data.MaxFillerVol)
		Panel:SetValue(Data.FillerVol)

		return Data.FillerVol
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
	RoundStats:TrackDataVar("FillerMass")
	RoundStats:SetValueFunction(function()
		self:UpdateRoundData(ToolData, Data)

		local Text		= "Muzzle Velocity : %s m/s\nProjectile Mass : %s\nPropellant Mass : %s\nExplosive Mass : %s"
		local MuzzleVel	= math.Round(Data.MuzzleVel * ACF.Scale, 2)
		local ProjMass	= ACF.GetProperMass(Data.ProjMass)
		local PropMass	= ACF.GetProperMass(Data.PropMass)
		local Filler	= ACF.GetProperMass(Data.FillerMass)

		return Text:format(MuzzleVel, ProjMass, PropMass, Filler)
	end)

	local FillerStats = Menu:AddLabel()
	FillerStats:TrackDataVar("FillerMass", "SetText")
	FillerStats:SetValueFunction(function()
		self:UpdateRoundData(ToolData, Data)

		local Text	   = "Blast Radius : %s m\nFragments : %s\nFragment Mass : %s\nFragment Velocity : %s m/s"
		local Blast	   = math.Round(Data.BlastRadius, 2)
		local FragMass = ACF.GetProperMass(Data.FragMass)
		local FragVel  = math.Round(Data.FragVel, 2)

		return Text:format(Blast, Data.Fragments, FragMass, FragVel)
	end)

	local PenStats = Menu:AddLabel()
	PenStats:TrackDataVar("Projectile", "SetText")
	PenStats:TrackDataVar("Propellant")
	PenStats:TrackDataVar("FillerMass")
	PenStats:SetValueFunction(function()
		self:UpdateRoundData(ToolData, Data)

		local Text	   = "Penetration : %s mm RHA\nAt 300m : %s mm RHA @ %s m/s\nAt 800m : %s mm RHA @ %s m/s"
		local MaxPen   = math.Round(Data.MaxPen, 2)
		local R1V, R1P = ACF.PenRanging(Data.MuzzleVel, Data.DragCoef, Data.ProjMass, Data.PenArea, Data.LimitVel, 300)
		local R2V, R2P = ACF.PenRanging(Data.MuzzleVel, Data.DragCoef, Data.ProjMass, Data.PenArea, Data.LimitVel, 800)

		return Text:format(MaxPen, R1P, R1V, R2P, R2V)
	end)

	Menu:AddLabel("Note: The penetration range data is an approximation and may not be entirely accurate.")
end

ACF.RegisterAmmoDecal("APHE", "damage/ap_pen", "damage/ap_rico")
