local Ammo = ACF.RegisterAmmoType("HP", "AP")

function Ammo:OnLoaded()
	Ammo.BaseClass.OnLoaded(self)

	self.Name		 = "Hollow Point"
	self.Description = "A round with a hollow cavity, meant to flatten against surfaces on impact."
end

function Ammo:UpdateRoundData(ToolData, Data, GUIData)
	GUIData = GUIData or Data

	ACF.UpdateRoundSpecs(ToolData, Data, GUIData)

	local ProjMass	   = math.max(GUIData.ProjVolume * 0.5, 0) * 0.0079 --(Volume of the projectile as a cylinder - Volume of the cavity) * density of steel 
	local MuzzleVel	   = ACF_MuzzleVelocity(Data.PropMass, ProjMass)
	local Energy	   = ACF_Kinetic(MuzzleVel * 39.37, ProjMass, Data.LimitVel)
	local MaxVol	   = ACF.RoundShellCapacity(Energy.Momentum, Data.FrArea, Data.Caliber, Data.ProjLength)
	local MaxCavity	   = math.min(GUIData.ProjVolume, MaxVol)
	local HollowCavity = math.Clamp(ToolData.HollowCavity, GUIData.MinCavVol, MaxCavity)
	local ExpRatio	   = HollowCavity / GUIData.ProjVolume

	GUIData.MaxCavVol = MaxCavity

	Data.CavVol		= HollowCavity
	Data.ProjMass	= (Data.FrArea * Data.ProjLength - HollowCavity) * 0.0079 --Volume of the projectile as a cylinder * fraction missing due to hollow point (Data5) * density of steel
	Data.MuzzleVel	= ACF_MuzzleVelocity(Data.PropMass, Data.ProjMass)
	Data.ShovePower	= 0.2 + ExpRatio * 0.5
	Data.ExpCaliber	= Data.Caliber * 0.1 + ExpRatio * Data.ProjLength
	Data.PenArea	= (3.1416 * Data.ExpCaliber * 0.5) ^ 2 ^ ACF.PenAreaMod
	Data.DragCoef	= Data.FrArea * 0.0001 / Data.ProjMass
	Data.CartMass	= Data.PropMass + Data.ProjMass

	for K, V in pairs(self:GetDisplayData(Data)) do
		GUIData[K] = V
	end
end

function Ammo:BaseConvert(_, ToolData)
	if not ToolData.Projectile then ToolData.Projectile = 0 end
	if not ToolData.Propellant then ToolData.Propellant = 0 end
	if not ToolData.HollowCavity then ToolData.HollowCavity = 0 end

	local Data, GUIData = ACF.RoundBaseGunpowder(ToolData, {})

	GUIData.MinCavVol = 0

	Data.LimitVel	 = 400 --Most efficient penetration speed in m/s
	Data.KETransfert = 0.1 --Kinetic energy transfert to the target for movement purposes
	Data.Ricochet	 = 90 --Base ricochet angle

	self:UpdateRoundData(ToolData, Data, GUIData)

	return Data, GUIData
end

function Ammo:Network(Crate, BulletData)
	Crate:SetNW2String("AmmoType", "HP")
	Crate:SetNW2String("AmmoID", BulletData.Id)
	Crate:SetNW2Float("Caliber", BulletData.Caliber)
	Crate:SetNW2Float("ProjMass", BulletData.ProjMass)
	Crate:SetNW2Float("PropMass", BulletData.PropMass)
	Crate:SetNW2Float("ExpCaliber", BulletData.ExpCaliber)
	Crate:SetNW2Float("DragCoef", BulletData.DragCoef)
	Crate:SetNW2Float("MuzzleVel", BulletData.MuzzleVel)
	Crate:SetNW2Float("Tracer", BulletData.Tracer)
end

function Ammo:GetDisplayData(BulletData)
	local Data	 = Ammo.BaseClass.GetDisplayData(self, BulletData)
	local Energy = ACF_Kinetic(BulletData.MuzzleVel * 39.37, BulletData.ProjMass, BulletData.LimitVel)

	Data.MaxKETransfert = Energy.Kinetic * BulletData.ShovePower

	return Data
end

function Ammo:GetCrateText(BulletData)
	local BaseText = Ammo.BaseClass.GetCrateText(self, BulletData)
	local Data	   = self:GetDisplayData(BulletData)
	local Text	   = BaseText .. "\nExpanded Caliber: %s mm\nImparted Energy: %s KJ"

	return Text:format(math.Round(BulletData.ExpCaliber * 10, 2), math.Round(Data.MaxKETransfert, 2))
end

function Ammo:MenuAction(Menu, ToolData, Data)
	local HollowCavity = Menu:AddSlider("Cavity Volume", Data.MinCavVol, Data.MaxCavVol, 2)
	HollowCavity:SetDataVar("HollowCavity", "OnValueChanged")
	HollowCavity:TrackDataVar("Projectile")
	HollowCavity:SetValueFunction(function(Panel)
		ToolData.HollowCavity = math.Round(ACF.ReadNumber("HollowCavity"), 2)

		self:UpdateRoundData(ToolData, Data)

		Panel:SetMax(Data.MaxCavVol)
		Panel:SetValue(Data.CavVol)

		return Data.CavVol
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
	RoundStats:TrackDataVar("HollowCavity")
	RoundStats:SetValueFunction(function()
		self:UpdateRoundData(ToolData, Data)

		local Text		= "Muzzle Velocity : %s m/s\nProjectile Mass : %s\nPropellant Mass : %s"
		local MuzzleVel	= math.Round(Data.MuzzleVel * ACF.Scale, 2)
		local ProjMass	= ACF.GetProperMass(Data.ProjMass)
		local PropMass	= ACF.GetProperMass(Data.PropMass)

		return Text:format(MuzzleVel, ProjMass, PropMass)
	end)

	local HollowStats = Menu:AddLabel()
	HollowStats:TrackDataVar("Projectile", "SetText")
	HollowStats:TrackDataVar("Propellant")
	HollowStats:TrackDataVar("HollowCavity")
	HollowStats:SetValueFunction(function()
		self:UpdateRoundData(ToolData, Data)

		local Text	  = "Expanded Caliber : %s mm\nTransfered Energy : %s KJ"
		local Caliber = math.Round(Data.ExpCaliber * 10, 2)
		local Energy  = math.Round(Data.MaxKETransfert, 2)

		return Text:format(Caliber, Energy)
	end)

	local PenStats = Menu:AddLabel()
	PenStats:TrackDataVar("Projectile", "SetText")
	PenStats:TrackDataVar("Propellant")
	PenStats:TrackDataVar("HollowCavity")
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

ACF.RegisterAmmoDecal("HP", "damage/ap_pen", "damage/ap_rico")
