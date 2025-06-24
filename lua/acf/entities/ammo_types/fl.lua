local ACF       = ACF
local Classes   = ACF.Classes
local AmmoTypes = Classes.AmmoTypes
local Ammo      = AmmoTypes.Register("FL", "AP")


function Ammo:OnLoaded()
	Ammo.BaseClass.OnLoaded(self)

	self.Name		 = "Flechette"
	self.Model		 = "models/munitions/dart_100mm.mdl"
	self.Description = "#acf.descs.ammo.fl"
	self.Blacklist = {
		AC = true,
		GL = true,
		MG = true,
		MO = true,
		SA = true,
		SL = true,
		LAC = true,
		RAC = true,
	}
end

-- Packing function to get the rough caliber of a flechette
-- based on the caliber of the full round and the amount of them
function Ammo:GetFlechetteCaliber(Caliber, Count)
	return (0.95231 * Caliber * 0.5 / Count ^ 0.5) * 2
end

function Ammo:GetPenetration(Bullet, Speed)
	if not isnumber(Speed) then
		Speed = Bullet.Flight and Bullet.Flight:Length() / ACF.Scale * ACF.InchToMeter or Bullet.MuzzleVel
	end

	return ACF.Penetration(Speed, Bullet.FlechetteMass, Bullet.FlechetteCaliber * 10)
end

function Ammo:GetDisplayData(Data)
	local Display = {
		MaxPen = self:GetPenetration(Data, Data.MuzzleVel)
	}

	hook.Run("ACF_OnRequestDisplayData", self, Data, Display)

	return Display
end

function Ammo:UpdateRoundData(ToolData, Data, GUIData)
	GUIData = GUIData or Data

	ACF.UpdateRoundSpecs(ToolData, Data, GUIData)

	local Flechettes = math.Clamp(ToolData.Flechettes, Data.MinFlechettes, Data.MaxFlechettes)

	Data.Flechettes		   = Flechettes
	Data.FlechetteSpread   = math.Clamp(ToolData.Spread, Data.MinSpread, Data.MaxSpread)
	Data.FlechetteCaliber  = self:GetFlechetteCaliber(Data.Caliber, Flechettes)
	Data.FlechetteArea	   = math.pi * (Data.FlechetteCaliber * 0.5) ^ 2 -- area of a single flechette
	Data.FlechetteMass	   = Data.FlechetteArea * Data.ProjLength * ACF.SteelDensity -- volume of single flechette * density of steel
	Data.FlechetteDragCoef = Data.FlechetteArea * 0.0001 / Data.FlechetteMass
	Data.ProjMass		   = Flechettes * Data.FlechetteMass -- total mass of all flechettes
	Data.DragCoef		   = Data.ProjArea * 0.0001 / Data.ProjMass
	Data.MuzzleVel		   = ACF.MuzzleVelocity(Data.PropMass, Data.ProjMass, Data.Efficiency)
	Data.CartMass		   = Data.PropMass + Data.ProjMass

	hook.Run("ACF_OnUpdateRound", self, ToolData, Data, GUIData)

	for K, V in pairs(self:GetDisplayData(Data)) do
		GUIData[K] = V
	end
end

function Ammo:BaseConvert(ToolData)
	local Data, GUIData = ACF.RoundBaseGunpowder(ToolData, { LengthAdj = 0.5 })

	Data.MaxFlechettes = math.Clamp(math.floor(Data.Caliber * 4), 12, 64)
	Data.MinFlechettes = math.min(12, Data.MaxFlechettes) --force bigger guns to have higher min count
	Data.MinSpread	   = 1
	Data.MaxSpread	   = 10
	Data.ShovePower	   = 0.2
	Data.LimitVel	   = 500 --Most efficient penetration speed in m/s
	Data.Ricochet	   = 75 --Base ricochet angle

	self:UpdateRoundData(ToolData, Data, GUIData)

	return Data, GUIData
end

function Ammo:VerifyData(ToolData)
	Ammo.BaseClass.VerifyData(self, ToolData)

	if not isnumber(ToolData.Flechettes) then
		ToolData.Flechettes = ACF.CheckNumber(ToolData.RoundData5, 0)
	end

	if not isnumber(ToolData.Spread) then
		ToolData.Spread = ACF.CheckNumber(ToolData.RoundData6, 0)
	end
end

if SERVER then
	local Ballistics = ACF.Ballistics
	local Entities   = Classes.Entities

	Entities.AddArguments("acf_ammo", "Flechettes", "Spread") -- Adding extra info to ammo crates

	function Ammo:OnLast(Entity)
		Ammo.BaseClass.OnLast(self, Entity)

		Entity.Flechettes = nil
		Entity.Spread = nil

		-- Cleanup the leftovers aswell
		Entity.RoundData5 = nil
		Entity.RoundData6 = nil
	end

	function Ammo:Create(Gun, BulletData)
		local Caliber = math.Round(BulletData.FlechetteCaliber, 2)

		local FlechetteData = {
			Caliber    = Caliber,
			Diameter   = Caliber,
			Id         = BulletData.Id,
			Type       = "AP",
			Owner      = BulletData.Owner,
			Entity     = BulletData.Entity,
			Crate      = BulletData.Crate,
			Gun        = BulletData.Gun,
			Pos        = BulletData.Pos,
			ProjArea   = BulletData.FlechetteArea,
			ProjMass   = BulletData.FlechetteMass,
			DragCoef   = BulletData.FlechetteDragCoef,
			Tracer     = BulletData.Tracer,
			LimitVel   = BulletData.LimitVel,
			Ricochet   = BulletData.Ricochet,
			ShovePower = BulletData.ShovePower,
		}

		--if ammo is cooking off, shoot in random direction
		if Gun:GetClass() == "acf_ammo" then
			local MuzzleVec = VectorRand()

			for _ = 1, BulletData.Flechettes do
				local Inaccuracy = VectorRand() / 360 * ((Gun.Spread or 0) + BulletData.FlechetteSpread)

				FlechetteData.Flight = (MuzzleVec + Inaccuracy):GetNormalized() * BulletData.MuzzleVel * ACF.MeterToInch + Gun:GetVelocity()

				Ballistics.CreateBullet(FlechetteData)
			end
		else
			local BaseInaccuracy = math.tan(math.rad(Gun:GetSpread()))
			local AddInaccuracy	 = math.tan(math.rad(BulletData.FlechetteSpread))
			local MuzzleVec		 = Gun:GetForward()

			for _ = 1, BulletData.Flechettes do
				local GunUp, GunRight	 = Gun:GetUp(), Gun:GetRight()
				local BaseInaccuracyMult = math.random() ^ (1 / math.Clamp(ACF.GunInaccuracyBias, 0.5, 4)) * (GunUp * (2 * math.random() - 1) + GunRight * (2 * math.random() - 1)):GetNormalized()
				local AddSpreadMult		 = math.random() ^ (1 / math.Clamp(ACF.GunInaccuracyBias, 0.5, 4)) * (GunUp * (2 * math.random() - 1) + GunRight * (2 * math.random() - 1)):GetNormalized()

				local BaseSpread = BaseInaccuracy * BaseInaccuracyMult
				local AddSpread  = AddInaccuracy * AddSpreadMult

				FlechetteData.Flight = (MuzzleVec + BaseSpread + AddSpread):GetNormalized() * BulletData.MuzzleVel * ACF.MeterToInch + Gun:GetVelocity()

				Ballistics.CreateBullet(FlechetteData)
			end
		end
	end

	function Ammo:Network(Entity, BulletData)
		Ammo.BaseClass.Network(self, Entity, BulletData)

		Entity:SetNW2String("AmmoType", "FL")
		Entity:SetNW2Float("Caliber", math.Round(BulletData.FlechetteCaliber, 2))
		Entity:SetNW2Float("ProjMass", BulletData.FlechetteMass)
		Entity:SetNW2Float("DragCoef", BulletData.FlechetteDragCoef)
	end

	function Ammo:GetCrateText(BulletData)
		local Text	  = "Muzzle Velocity: %s m/s\nMax Penetration: %s mm\nMax Spread: %s degrees"
		local Data	  = self:GetDisplayData(BulletData)
		local Destiny = ACF.FindWeaponrySource(BulletData.Id)
		local Class   = Classes.GetGroup(Destiny, BulletData.Id)
		local Spread  = Class and Class.Spread * ACF.GunInaccuracyScale or 0

		return Text:format(math.Round(BulletData.MuzzleVel, 2), math.Round(Data.MaxPen, 2), math.Round(BulletData.FlechetteSpread + Spread, 2))
	end
else
	ACF.RegisterAmmoDecal("FL", "damage/ap_pen", "damage/ap_rico")

	function Ammo:GetRangedPenetration(Bullet, Range)
		local Speed = ACF.GetRangedSpeed(Bullet.MuzzleVel, Bullet.FlechetteDragCoef, Range) * ACF.InchToMeter

		return math.Round(self:GetPenetration(Bullet, Speed), 2), math.Round(Speed, 2)
	end

	function Ammo:OnCreateAmmoControls(Base, ToolData, BulletData)
		local Flechettes = Base:AddSlider("#acf.menu.ammo.flechette_amount", BulletData.MinFlechettes, BulletData.MaxFlechettes)
		Flechettes:SetClientData("Flechettes", "OnValueChanged")
		Flechettes:DefineSetter(function(Panel, _, _, Value)
			ToolData.Flechettes = math.floor(Value)

			Ammo:UpdateRoundData(ToolData, BulletData)

			Panel:SetValue(BulletData.Flechettes)

			return BulletData.Flechettes
		end)

		local Spread = Base:AddSlider("#acf.menu.ammo.flechette_spread", BulletData.MinSpread, BulletData.MaxSpread, 2)
		Spread:SetClientData("Spread", "OnValueChanged")
		Spread:DefineSetter(function(Panel, _, _, Value)
			ToolData.Spread = Value

			Ammo:UpdateRoundData(ToolData, BulletData)

			Panel:SetValue(BulletData.FlechetteSpread)

			return BulletData.FlechetteSpread
		end)
	end

	function Ammo:OnCreateCrateInformation(Base, Label, ...)
		Ammo.BaseClass.OnCreateCrateInformation(self, Base, Label, ...)

		Label:TrackClientData("Flechettes")
	end

	function Ammo:OnCreateAmmoInformation(Menu, ToolData, BulletData)
		local RoundStats = Menu:AddLabel()
		RoundStats:TrackClientData("Projectile", "SetText")
		RoundStats:TrackClientData("Propellant")
		RoundStats:TrackClientData("Flechettes")
		RoundStats:DefineSetter(function()
			self:UpdateRoundData(ToolData, BulletData)

			local Text		= language.GetPhrase("acf.menu.ammo.round_stats_fl")
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

			local Text	   = language.GetPhrase("acf.menu.ammo.pen_stats_ap")
			local MaxPen   = math.Round(BulletData.MaxPen, 2)
			local R1P, R1V = self:GetRangedPenetration(BulletData, 300)
			local R2V, R2P = self:GetRangedPenetration(BulletData, 800)

			return Text:format(MaxPen, R1P, R1V, R2P, R2V)
		end)

		Menu:AddLabel("#acf.menu.ammo.approx_pen_warning")
	end
end