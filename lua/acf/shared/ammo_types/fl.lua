local Ammo = ACF.RegisterAmmoType("FL", "AP")

function Ammo:OnLoaded()
	Ammo.BaseClass.OnLoaded(self)

	self.Name		 = "Flechette"
	self.Model		 = "models/munitions/dart_100mm.mdl"
	self.Description = "Flechette shells contain several steel darts inside, functioning as a large shotgun round."
	self.Blacklist = {
		AC = true,
		GL = true,
		MG = true,
		SL = true,
		HMG = true,
		RAC = true,
	}
end

function Ammo:Create(Gun, BulletData)
	local FlechetteData = {
		Caliber		= math.Round(BulletData.FlechetteRadius * 0.2, 2),
		Id			= BulletData.Id,
		Type		= "AP",
		Owner		= BulletData.Owner,
		Crate		= BulletData.Crate,
		Gun			= BulletData.Gun,
		Pos			= BulletData.Pos,
		FrArea		= BulletData.FlechetteArea,
		ProjMass	= BulletData.FlechetteMass,
		DragCoef	= BulletData.FlechetteDragCoef,
		Tracer		= BulletData.Tracer,
		LimitVel	= BulletData.LimitVel,
		Ricochet	= BulletData.Ricochet,
		PenArea		= BulletData.FlechettePenArea,
		ShovePower	= BulletData.ShovePower,
		KETransfert	= BulletData.KETransfert,
	}

	--if ammo is cooking off, shoot in random direction
	if Gun:GetClass() == "acf_ammo" then
		local MuzzleVec = VectorRand()

		for _ = 1, BulletData.Flechettes do
			local Inaccuracy = VectorRand() / 360 * ((Gun.Spread or 0) + BulletData.FlechetteSpread)

			FlechetteData.Flight = (MuzzleVec + Inaccuracy):GetNormalized() * BulletData.MuzzleVel * 39.37 + Gun:GetVelocity()

			ACF_CreateBullet(FlechetteData)
		end
	else
		local BaseInaccuracy = math.tan(math.rad(Gun:GetSpread()))
		local AddInaccuracy	 = math.tan(math.rad(BulletData.FlechetteSpread))
		local MuzzleVec		 = Gun:GetForward()

		for _ = 1, BulletData.Flechettes do
			local GunUp, GunRight	 = Gun:GetUp(), Gun:GetRight()
			local BaseInaccuracyMult = math.random() ^ (1 / math.Clamp(ACF.GunInaccuracyBias, 0.5, 4)) * (GunUp * (2 * math.random() - 1) + GunRight * (2 * math.random() - 1)):GetNormalized()
			local AddSpreadMult		 = math.random() ^ (1 / math.Clamp(ACF.GunInaccuracyBias, 0.5, 4)) * (GunUp * (2 * math.random() - 1) + GunRight * (2 * math.random() - 1)):GetNormalized()

			BaseSpread = BaseInaccuracy * BaseInaccuracyMult
			AddSpread  = AddInaccuracy * AddSpreadMult

			FlechetteData.Flight = (MuzzleVec + BaseSpread + AddSpread):GetNormalized() * BulletData.MuzzleVel * 39.37 + Gun:GetVelocity()

			ACF_CreateBullet(FlechetteData)
		end
	end
end

function Ammo:UpdateRoundData(ToolData, Data, GUIData)
	GUIData = GUIData or Data

	ACF.UpdateRoundSpecs(ToolData, Data, GUIData)

	local PenAdj	 = 0.8 --higher means lower pen, but more structure (hp) damage (old: 2.35, 2.85)
	local RadiusAdj	 = 1.0 -- lower means less structure (hp) damage, but higher pen (old: 1.0, 0.8)
	local Flechettes = math.Clamp(ToolData.Flechettes, Data.MinFlechettes, Data.MaxFlechettes)
	local PackRatio	 = 0.0025 * Flechettes + 0.69 --how efficiently flechettes are packed into shell

	Data.Flechettes		   = Flechettes
	Data.FlechetteSpread   = math.Clamp(ToolData.Spread, Data.MinSpread, Data.MaxSpread)
	Data.FlechetteRadius   = (((PackRatio * RadiusAdj * Data.Caliber * 0.05) ^ 2) / Data.Flechettes) ^ 0.5
	Data.FlechetteArea	   = 3.1416 * Data.FlechetteRadius ^ 2 -- area of a single flechette
	Data.FlechetteMass	   = Data.FlechetteArea * (Data.ProjLength * 7.9 / 1000) -- volume of single flechette * density of steel
	Data.FlechettePenArea  = (PenAdj * Data.FlechetteArea) ^ ACF.PenAreaMod
	Data.FlechetteDragCoef = Data.FlechetteArea * 0.0001 / Data.FlechetteMass
	Data.ProjMass		   = Data.Flechettes * Data.FlechetteMass -- total mass of all flechettes
	Data.DragCoef		   = Data.FrArea * 0.0001 / Data.ProjMass
	Data.MuzzleVel		   = ACF_MuzzleVelocity(Data.PropMass, Data.ProjMass)
	Data.CartMass		   = Data.PropMass + Data.ProjMass

	for K, V in pairs(self:GetDisplayData(Data)) do
		GUIData[K] = V
	end
end

function Ammo:BaseConvert(_, ToolData)
	if not ToolData.Projectile then ToolData.Projectile = 0 end
	if not ToolData.Propellant then ToolData.Propellant = 0 end
	if not ToolData.Flechettes then ToolData.Flechettes = 3 end
	if not ToolData.Spread then ToolData.Spread = 5 end

	local Data, GUIData = ACF.RoundBaseGunpowder(ToolData, { LengthAdj = 0.5 })
	local GunClass = ToolData.WeaponClass

	if GunClass == "SA" then
		Data.MaxFlechettes = math.Clamp(math.floor(Data.Caliber * 0.3 - 4.5), 1, 32)
	elseif GunClass == "MO" then
		Data.MaxFlechettes = math.Clamp(math.floor(Data.Caliber * 0.4) - 12, 1, 32)
	elseif GunClass == "HW" then
		Data.MaxFlechettes = math.Clamp(math.floor(Data.Caliber * 0.4) - 10, 1, 32)
	else
		Data.MaxFlechettes = math.Clamp(math.floor(Data.Caliber * 0.4) - 8, 1, 32)
	end

	Data.MinFlechettes = math.min(6, Data.MaxFlechettes) --force bigger guns to have higher min count
	Data.MinSpread	   = 0.25
	Data.MaxSpread	   = 30
	Data.ShovePower	   = 0.2
	Data.PenArea	   = Data.FrArea ^ ACF.PenAreaMod
	Data.LimitVel	   = 500 --Most efficient penetration speed in m/s
	Data.KETransfert   = 0.1 --Kinetic energy transfert to the target for movement purposes
	Data.Ricochet	   = 75 --Base ricochet angle

	self:UpdateRoundData(ToolData, Data, GUIData)

	return Data, GUIData
end

function Ammo:Network(Crate, BulletData)
	Crate:SetNW2String("AmmoType", "FL")
	Crate:SetNW2String("AmmoID", BulletData.Id)
	Crate:SetNW2Float("PropMass", BulletData.PropMass)
	Crate:SetNW2Float("MuzzleVel", BulletData.MuzzleVel)
	Crate:SetNW2Float("Tracer", BulletData.Tracer)
	Crate:SetNW2Float("Caliber", math.Round(BulletData.FlechetteRadius * 0.2, 2))
	Crate:SetNW2Float("ProjMass", BulletData.FlechetteMass)
	Crate:SetNW2Float("DragCoef", BulletData.FlechetteDragCoef)
	Crate:SetNW2Float("FillerMass", 0)
end

function Ammo:GetDisplayData(BulletData)
	local Energy = ACF_Kinetic(BulletData.MuzzleVel * 39.37, BulletData.FlechetteMass, BulletData.LimitVel)

	return {
		MaxPen = (Energy.Penetration / BulletData.FlechettePenArea) * ACF.KEtoRHA
	}
end

function Ammo:GetCrateText(BulletData)
	local Text	 = "Muzzle Velocity: %s m/s\nMax Penetration: %s mm\nMax Spread: %s degrees"
	local Data	 = self:GetDisplayData(BulletData)
	local Gun	 = ACF.Weapons.Guns[BulletData.Id]
	local Spread = 0

	if Gun then
		local GunClass = ACF.Classes.GunClass[Gun.gunclass]

		Spread = GunClass and (GunClass.spread * ACF.GunInaccuracyScale) or 0
	end

	return Text:format(math.Round(BulletData.MuzzleVel, 2), math.Round(Data.MaxPen, 2), math.Round(BulletData.FlechetteSpread + Spread, 2))
end

function Ammo:MenuAction(Menu, ToolData, Data)
	local Flechettes = Menu:AddSlider("Flechette Amount", Data.MinFlechettes, Data.MaxFlechettes)
	Flechettes:SetDataVar("Flechettes", "OnValueChanged")
	Flechettes:SetValueFunction(function(Panel)
		ToolData.Flechettes = math.floor(ACF.ReadNumber("Flechettes"))

		Ammo:UpdateRoundData(ToolData, Data)

		Panel:SetValue(Data.Flechettes)

		return Data.Flechettes
	end)

	local Spread = Menu:AddSlider("Flechette Spread", Data.MinSpread, Data.MaxSpread, 2)
	Spread:SetDataVar("Spread", "OnValueChanged")
	Spread:SetValueFunction(function(Panel)
		ToolData.Spread = ACF.ReadNumber("Spread")

		Ammo:UpdateRoundData(ToolData, Data)

		Panel:SetValue(Data.FlechetteSpread)

		return Data.FlechetteSpread
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
	RoundStats:TrackDataVar("Flechettes")
	RoundStats:SetValueFunction(function()
		self:UpdateRoundData(ToolData, Data)

		local Text		= "Muzzle Velocity : %s m/s\nProjectile Mass : %s\nPropellant Mass : %s\nFlechette Mass : %s"
		local MuzzleVel	= math.Round(Data.MuzzleVel * ACF.Scale, 2)
		local ProjMass	= ACF.GetProperMass(Data.ProjMass)
		local PropMass	= ACF.GetProperMass(Data.PropMass)
		local FLMass	= ACF.GetProperMass(Data.FlechetteMass)

		return Text:format(MuzzleVel, ProjMass, PropMass, FLMass)
	end)

	local PenStats = Menu:AddLabel()
	PenStats:TrackDataVar("Projectile", "SetText")
	PenStats:TrackDataVar("Propellant")
	PenStats:TrackDataVar("Flechettes")
	PenStats:SetValueFunction(function()
		self:UpdateRoundData(ToolData, Data)

		local Text	   = "Penetration : %s mm RHA\nAt 300m : %s mm RHA @ %s m/s\nAt 800m : %s mm RHA @ %s m/s"
		local MaxPen   = math.Round(Data.MaxPen, 2)
		local R1V, R1P = ACF.PenRanging(Data.MuzzleVel, Data.FlechetteDragCoef, Data.FlechetteMass, Data.FlechettePenArea, Data.LimitVel, 300)
		local R2V, R2P = ACF.PenRanging(Data.MuzzleVel, Data.FlechetteDragCoef, Data.FlechetteMass, Data.FlechettePenArea, Data.LimitVel, 800)

		return Text:format(MaxPen, R1P, R1V, R2P, R2V)
	end)

	Menu:AddLabel("Note: The penetration range data is an approximation and may not be entirely accurate.")
end

ACF.RegisterAmmoDecal("FL", "damage/ap_pen", "damage/ap_rico")