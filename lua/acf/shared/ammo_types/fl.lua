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
		MO = true,
		SA = true,
		SB = true,
		SL = true,
		HMG = true,
		RAC = true,
	}
end

function Ammo:GetDisplayData(Data)
	local Energy  = ACF_Kinetic(Data.MuzzleVel * 39.37, Data.FlechetteMass, Data.LimitVel)
	local Display = {
		MaxPen = (Energy.Penetration / Data.FlechettePenArea) * ACF.KEtoRHA
	}

	hook.Run("ACF_GetDisplayData", self, Data, Display)

	return Display
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
	Data.FlechetteRadius   = (((PackRatio * RadiusAdj * Data.Caliber * 0.5) ^ 2) / Data.Flechettes) ^ 0.5
	Data.FlechetteArea	   = 3.1416 * Data.FlechetteRadius ^ 2 -- area of a single flechette
	Data.FlechetteMass	   = Data.FlechetteArea * (Data.ProjLength * 7.9 / 1000) -- volume of single flechette * density of steel
	Data.FlechettePenArea  = (PenAdj * Data.FlechetteArea) ^ ACF.PenAreaMod
	Data.FlechetteDragCoef = Data.FlechetteArea * 0.0001 / Data.FlechetteMass
	Data.ProjMass		   = Data.Flechettes * Data.FlechetteMass -- total mass of all flechettes
	Data.DragCoef		   = Data.FrArea * 0.0001 / Data.ProjMass
	Data.MuzzleVel		   = ACF_MuzzleVelocity(Data.PropMass, Data.ProjMass)
	Data.CartMass		   = Data.PropMass + Data.ProjMass

	hook.Run("ACF_UpdateRoundData", self, ToolData, Data, GUIData)

	for K, V in pairs(self:GetDisplayData(Data)) do
		GUIData[K] = V
	end
end

function Ammo:BaseConvert(ToolData)
	local Data, GUIData = ACF.RoundBaseGunpowder(ToolData, { LengthAdj = 0.5 })

	Data.MaxFlechettes = math.Clamp(math.floor(Data.Caliber * 4) - 8, 1, 32)
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

function Ammo:VerifyData(ToolData)
	Ammo.BaseClass.VerifyData(self, ToolData)

	if not ToolData.Flechettes then
		local Data5 = ToolData.RoundData5

		ToolData.Flechettes = Data5 and tonumber(Data5) or 0
	end

	if not ToolData.Spread then
		local Data6 = ToolData.RoundData6

		ToolData.Spread = Data6 and tonumber(Data6) or 0
	end
end

if SERVER then
	ACF.AddEntityArguments("acf_ammo", "Flechettes", "Spread") -- Adding extra info to ammo crates

	function Ammo:OnLast(Entity)
		Ammo.BaseClass.OnLast(self, Entity)

		Entity.Flechettes = nil
		Entity.Spread = nil

		-- Cleanup the leftovers aswell
		Entity.RoundData5 = nil
		Entity.RoundData6 = nil
	end

	function Ammo:Create(Gun, BulletData)
		local FlechetteData = {
			Caliber     = math.Round(BulletData.FlechetteRadius * 0.2, 2),
			Id          = BulletData.Id,
			Type        = "AP",
			Owner       = BulletData.Owner,
			Entity      = BulletData.Entity,
			Crate       = BulletData.Crate,
			Gun         = BulletData.Gun,
			Pos         = BulletData.Pos,
			FrArea      = BulletData.FlechetteArea,
			ProjMass    = BulletData.FlechetteMass,
			DragCoef    = BulletData.FlechetteDragCoef,
			Tracer      = BulletData.Tracer,
			LimitVel    = BulletData.LimitVel,
			Ricochet    = BulletData.Ricochet,
			PenArea     = BulletData.FlechettePenArea,
			ShovePower  = BulletData.ShovePower,
			KETransfert = BulletData.KETransfert,
		}

		--if ammo is cooking off, shoot in random direction
		if Gun:GetClass() == "acf_ammo" then
			local MuzzleVec = VectorRand()

			for _ = 1, BulletData.Flechettes do
				local Inaccuracy = VectorRand() / 360 * ((Gun.Spread or 0) + BulletData.FlechetteSpread)

				FlechetteData.Flight = (MuzzleVec + Inaccuracy):GetNormalized() * BulletData.MuzzleVel * 39.37 + Gun:GetVelocity()

				ACF.CreateBullet(FlechetteData)
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

				ACF.CreateBullet(FlechetteData)
			end
		end
	end

	function Ammo:Network(Entity, BulletData)
		Ammo.BaseClass.Network(self, Entity, BulletData)

		Entity:SetNW2String("AmmoType", "FL")
		Entity:SetNW2Float("Caliber", math.Round(BulletData.FlechetteRadius * 0.2, 2))
		Entity:SetNW2Float("ProjMass", BulletData.FlechetteMass)
		Entity:SetNW2Float("DragCoef", BulletData.FlechetteDragCoef)
	end

	function Ammo:GetCrateText(BulletData)
		local Text	  = "Muzzle Velocity: %s m/s\nMax Penetration: %s mm\nMax Spread: %s degrees"
		local Data	  = self:GetDisplayData(BulletData)
		local Destiny = ACF.FindWeaponrySource(BulletData.Id)
		local Class   = ACF.GetClassGroup(Destiny, BulletData.Id)
		local Spread  = Class and Class.Spread * ACF.GunInaccuracyScale or 0

		return Text:format(math.Round(BulletData.MuzzleVel, 2), math.Round(Data.MaxPen, 2), math.Round(BulletData.FlechetteSpread + Spread, 2))
	end
else
	ACF.RegisterAmmoDecal("FL", "damage/ap_pen", "damage/ap_rico")

	function Ammo:AddAmmoControls(Base, ToolData, BulletData)
		local Flechettes = Base:AddSlider("Flechette Amount", BulletData.MinFlechettes, BulletData.MaxFlechettes)
		Flechettes:SetClientData("Flechettes", "OnValueChanged")
		Flechettes:DefineSetter(function(Panel, _, _, Value)
			ToolData.Flechettes = math.floor(Value)

			Ammo:UpdateRoundData(ToolData, BulletData)

			Panel:SetValue(BulletData.Flechettes)

			return BulletData.Flechettes
		end)

		local Spread = Base:AddSlider("Flechette Spread", BulletData.MinSpread, BulletData.MaxSpread, 2)
		Spread:SetClientData("Spread", "OnValueChanged")
		Spread:DefineSetter(function(Panel, _, _, Value)
			ToolData.Spread = Value

			Ammo:UpdateRoundData(ToolData, BulletData)

			Panel:SetValue(BulletData.FlechetteSpread)

			return BulletData.FlechetteSpread
		end)
	end

	function Ammo:AddCrateDataTrackers(Trackers, ...)
		Ammo.BaseClass.AddCrateDataTrackers(self, Trackers, ...)

		Trackers.Flechettes = true
	end

	function Ammo:AddAmmoInformation(Menu, ToolData, BulletData)
		local RoundStats = Menu:AddLabel()
		RoundStats:TrackClientData("Projectile", "SetText")
		RoundStats:TrackClientData("Propellant")
		RoundStats:TrackClientData("Flechettes")
		RoundStats:DefineSetter(function()
			self:UpdateRoundData(ToolData, BulletData)

			local Text		= "Muzzle Velocity : %s m/s\nProjectile Mass : %s\nPropellant Mass : %s\nFlechette Mass : %s"
			local MuzzleVel	= math.Round(BulletData.MuzzleVel * ACF.Scale, 2)
			local ProjMass	= ACF.GetProperMass(BulletData.ProjMass)
			local PropMass	= ACF.GetProperMass(BulletData.PropMass)
			local FLMass	= ACF.GetProperMass(BulletData.FlechetteMass)

			return Text:format(MuzzleVel, ProjMass, PropMass, FLMass)
		end)

		local PenStats = Menu:AddLabel()
		PenStats:TrackClientData("Projectile", "SetText")
		PenStats:TrackClientData("Propellant")
		PenStats:TrackClientData("Flechettes")
		PenStats:DefineSetter(function()
			self:UpdateRoundData(ToolData, BulletData)

			local Text	   = "Penetration : %s mm RHA\nAt 300m : %s mm RHA @ %s m/s\nAt 800m : %s mm RHA @ %s m/s"
			local MaxPen   = math.Round(BulletData.MaxPen, 2)
			local R1V, R1P = ACF.PenRanging(BulletData.MuzzleVel, BulletData.FlechetteDragCoef, BulletData.FlechetteMass, BulletData.FlechettePenArea, BulletData.LimitVel, 300)
			local R2V, R2P = ACF.PenRanging(BulletData.MuzzleVel, BulletData.FlechetteDragCoef, BulletData.FlechetteMass, BulletData.FlechettePenArea, BulletData.LimitVel, 800)

			return Text:format(MaxPen, R1P, R1V, R2P, R2V)
		end)

		Menu:AddLabel("Note: The penetration range data is an approximation and may not be entirely accurate.")
	end
end