local Ammo = ACF.RegisterAmmoType("HE", "APHE")

function Ammo:OnLoaded()
	Ammo.BaseClass.OnLoaded(self)

	self.Name		 = "High Explosive"
	self.Description = "A shell filled with explosives, detonates on impact."
	self.Blacklist = {
		MG = true,
		RAC = true,
	}
end

function Ammo:UpdateRoundData(ToolData, Data, GUIData)
	GUIData = GUIData or Data

	ACF.UpdateRoundSpecs(ToolData, Data, GUIData)

	local HEDensity	= ACF.HEDensity * 0.001
	-- Volume of the projectile as a cylinder - Volume of the filler * density of steel + Volume of the filler * density of TNT
	local ProjMass	= math.max(GUIData.ProjVolume - ToolData.FillerMass, 0) * 0.0079 + math.min(ToolData.FillerMass, GUIData.ProjVolume) * HEDensity
	local MuzzleVel	= ACF_MuzzleVelocity(Data.PropMass, ProjMass)
	local Energy	= ACF_Kinetic(MuzzleVel * 39.37, ProjMass, Data.LimitVel)
	local MaxVol	= ACF.RoundShellCapacity(Energy.Momentum, Data.FrArea, Data.Caliber, Data.ProjLength)

	GUIData.MaxFillerVol = math.min(GUIData.ProjVolume, MaxVol)
	GUIData.FillerVol	 = math.min(ToolData.FillerMass, GUIData.MaxFillerVol)

	Data.FillerMass	= GUIData.FillerVol * HEDensity
	Data.ProjMass	= math.max(GUIData.ProjVolume - GUIData.FillerVol, 0) * 0.0079 + Data.FillerMass
	Data.MuzzleVel	= ACF_MuzzleVelocity(Data.PropMass, Data.ProjMass)
	Data.DragCoef	= Data.FrArea * 0.0001 / Data.ProjMass
	Data.CartMass	= Data.PropMass + Data.ProjMass

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
	Crate:SetNW2String("AmmoType", "HE")
	Crate:SetNW2String("AmmoID", BulletData.Id)
	Crate:SetNW2Float("Caliber", BulletData.Caliber)
	Crate:SetNW2Float("ProjMass", BulletData.ProjMass)
	Crate:SetNW2Float("FillerMass", BulletData.FillerMass)
	Crate:SetNW2Float("PropMass", BulletData.PropMass)
	Crate:SetNW2Float("DragCoef", BulletData.DragCoef)
	Crate:SetNW2Float("MuzzleVel", BulletData.MuzzleVel)
	Crate:SetNW2Float("Tracer", BulletData.Tracer)
end

function Ammo:GetDisplayData(Data)
	local FragMass	= Data.ProjMass - Data.FillerMass
	local Fragments	= math.max(math.floor((Data.FillerMass / FragMass) * ACF.HEFrag), 2)

	return {
		BlastRadius	= Data.FillerMass ^ 0.33 * 8,
		Fragments	= Fragments,
		FragMass	= FragMass / Fragments,
		FragVel		= (Data.FillerMass * ACF.HEPower * 1000 / FragMass / Fragments / Fragments) ^ 0.5,
	}
end

function Ammo:GetCrateText(BulletData)
	local Text = "Muzzle Velocity: %s m/s\nBlast Radius: %s m\nBlast Energy: %s KJ"
	local Data = self:GetDisplayData(BulletData)

	return Text:format(math.Round(BulletData.MuzzleVel, 2), math.Round(Data.BlastRadius, 2), math.Round(BulletData.FillerMass * ACF.HEPower, 2))
end

function Ammo:PropImpact(_, Bullet, Target, HitNormal, HitPos, Bone)
	if ACF_Check(Target) then
		local Speed	 = Bullet.Flight:Length() / ACF.Scale
		local Energy = ACF_Kinetic(Speed, Bullet.ProjMass - Bullet.FillerMass, Bullet.LimitVel)
		local HitRes = ACF_RoundImpact(Bullet, Speed, Energy, Target, HitPos, HitNormal, Bone)

		if HitRes.Ricochet then return "Ricochet" end
	end

	return false
end

function Ammo:WorldImpact()
	return false
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
end

ACF.RegisterAmmoDecal("HE", "damage/he_pen", "damage/he_rico")
