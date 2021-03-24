local Ammo = ACF.RegisterAmmoType("APHE", "AP")

function Ammo:OnLoaded()
	Ammo.BaseClass.OnLoaded(self)

	self.Name		 = "Armor Piercing High Explosive"
	self.Description = "Less capable armor piercing round with an explosive charge inside."
	self.Blacklist = {
		GL = true,
		MG = true,
		MO = true,
		SB = true,
		SL = true,
		RAC = true,
	}
end

function Ammo:GetDisplayData(Data)
	local Display  = Ammo.BaseClass.GetDisplayData(self, Data)
	local FragMass = Data.ProjMass - Data.FillerMass

	Display.BlastRadius = Data.FillerMass ^ 0.33 * 8
	Display.Fragments   = math.max(math.floor((Data.FillerMass / FragMass) * ACF.HEFrag), 2)
	Display.FragMass    = FragMass / Display.Fragments
	Display.FragVel     = (Data.FillerMass * ACF.HEPower * 1000 / Display.FragMass / Display.Fragments) ^ 0.5

	hook.Run("ACF_GetDisplayData", self, Data, Display)

	return Display
end

function Ammo:UpdateRoundData(ToolData, Data, GUIData)
	GUIData = GUIData or Data

	ACF.UpdateRoundSpecs(ToolData, Data, GUIData)

	local HEDensity	= ACF.HEDensity * 0.001
	--Volume of the projectile as a cylinder - Volume of the filler * density of steel + Volume of the filler * density of TNT
	local ProjMass	= math.max(GUIData.ProjVolume - ToolData.FillerMass, 0) * 0.0079 + math.min(ToolData.FillerMass, GUIData.ProjVolume) * HEDensity
	local MuzzleVel	= ACF_MuzzleVelocity(Data.PropMass, ProjMass)
	local Energy	= ACF_Kinetic(MuzzleVel * 39.37, ProjMass, Data.LimitVel)
	local MaxVol	= ACF.RoundShellCapacity(Energy.Momentum, Data.ProjArea, Data.Caliber, Data.ProjLength)

	GUIData.MaxFillerVol = math.Round(math.min(GUIData.ProjVolume, MaxVol * 0.9), 2)
	GUIData.FillerVol	 = math.min(ToolData.FillerMass, GUIData.MaxFillerVol)

	Data.FillerMass	= GUIData.FillerVol * HEDensity
	Data.ProjMass	= math.max(GUIData.ProjVolume - GUIData.FillerVol, 0) * 0.0079 + Data.FillerMass
	Data.MuzzleVel	= ACF_MuzzleVelocity(Data.PropMass, Data.ProjMass)
	Data.DragCoef	= Data.ProjArea * 0.0001 / Data.ProjMass
	Data.CartMass	= Data.PropMass + Data.ProjMass

	hook.Run("ACF_UpdateRoundData", self, ToolData, Data, GUIData)

	for K, V in pairs(self:GetDisplayData(Data)) do
		GUIData[K] = V
	end
end

function Ammo:BaseConvert(ToolData)
	local Data, GUIData = ACF.RoundBaseGunpowder(ToolData, {})

	Data.ShovePower		 = 0.1
	Data.PenArea		 = Data.ProjArea ^ ACF.PenAreaMod
	Data.LimitVel		 = 700 --Most efficient penetration speed in m/s
	Data.Ricochet		 = 65 --Base ricochet angle
	Data.CanFuze		 = Data.Caliber * 10 > ACF.MinFuzeCaliber -- Can fuze on calibers > 20mm

	GUIData.MinFillerVol = 0

	self:UpdateRoundData(ToolData, Data, GUIData)

	return Data, GUIData
end

function Ammo:VerifyData(ToolData)
	Ammo.BaseClass.VerifyData(self, ToolData)

	if not ToolData.FillerMass then
		local Data5 = ToolData.RoundData5

		ToolData.FillerMass = Data5 and tonumber(Data5) or 0
	end
end

if SERVER then
	ACF.AddEntityArguments("acf_ammo", "FillerMass") -- Adding extra info to ammo crates

	function Ammo:OnLast(Entity)
		Ammo.BaseClass.OnLast(self, Entity)

		Entity.FillerMass = nil
		Entity.RoundData5 = nil -- Cleanup the leftovers aswell

		Entity:SetNW2Float("FillerMass", 0)
	end

	function Ammo:Network(Entity, BulletData)
		Ammo.BaseClass.Network(self, Entity, BulletData)

		Entity:SetNW2String("AmmoType", "APHE")
		Entity:SetNW2Float("FillerMass", BulletData.FillerMass)
	end

	function Ammo:GetCrateText(BulletData)
		local BaseText = Ammo.BaseClass.GetCrateText(self, BulletData)
		local Text	   = BaseText .. "\nBlast Radius: %s m\nBlast Energy: %s KJ"
		local Data	   = self:GetDisplayData(BulletData)

		return Text:format(math.Round(Data.BlastRadius, 2), math.Round(BulletData.FillerMass * ACF.HEPower, 2))
	end

	function Ammo:OnFlightEnd(Bullet, Trace)
		ACF_HE(Trace.HitPos, Bullet.FillerMass, Bullet.ProjMass - Bullet.FillerMass, Bullet.Owner, nil, Bullet.Gun)

		Ammo.BaseClass.OnFlightEnd(self, Bullet, Trace)
	end
else
	ACF.RegisterAmmoDecal("APHE", "damage/ap_pen", "damage/ap_rico")

	function Ammo:ImpactEffect(_, Bullet)
		local Effect = EffectData()
		Effect:SetOrigin(Bullet.SimPos)
		Effect:SetNormal(Bullet.SimFlight:GetNormalized())
		Effect:SetScale(math.max(Bullet.FillerMass ^ 0.33 * 8 * 39.37, 1))
		Effect:SetRadius(Bullet.Caliber)

		util.Effect("ACF_Explosion", Effect)
	end

	function Ammo:AddAmmoControls(Base, ToolData, BulletData)
		local FillerMass = Base:AddSlider("Filler Volume", 0, BulletData.MaxFillerVol, 2)
		FillerMass:SetClientData("FillerMass", "OnValueChanged")
		FillerMass:TrackClientData("Projectile")
		FillerMass:DefineSetter(function(Panel, _, Key, Value)
			if Key == "FillerMass" then
				ToolData.FillerMass = math.Round(Value, 2)
			end

			self:UpdateRoundData(ToolData, BulletData)

			Panel:SetMax(BulletData.MaxFillerVol)
			Panel:SetValue(BulletData.FillerVol)

			return BulletData.FillerVol
		end)
	end

	function Ammo:AddCrateDataTrackers(Trackers, ...)
		Ammo.BaseClass.AddCrateDataTrackers(self, Trackers, ...)

		Trackers.FillerMass = true
	end

	function Ammo:AddAmmoInformation(Base, ToolData, BulletData)
		local RoundStats = Base:AddLabel()
		RoundStats:TrackClientData("Projectile", "SetText")
		RoundStats:TrackClientData("Propellant")
		RoundStats:TrackClientData("FillerMass")
		RoundStats:DefineSetter(function()
			self:UpdateRoundData(ToolData, BulletData)

			local Text		= "Muzzle Velocity : %s m/s\nProjectile Mass : %s\nPropellant Mass : %s\nExplosive Mass : %s"
			local MuzzleVel	= math.Round(BulletData.MuzzleVel * ACF.Scale, 2)
			local ProjMass	= ACF.GetProperMass(BulletData.ProjMass)
			local PropMass	= ACF.GetProperMass(BulletData.PropMass)
			local Filler	= ACF.GetProperMass(BulletData.FillerMass)

			return Text:format(MuzzleVel, ProjMass, PropMass, Filler)
		end)

		local FillerStats = Base:AddLabel()
		FillerStats:TrackClientData("FillerMass", "SetText")
		FillerStats:DefineSetter(function()
			self:UpdateRoundData(ToolData, BulletData)

			local Text	   = "Blast Radius : %s m\nFragments : %s\nFragment Mass : %s\nFragment Velocity : %s m/s"
			local Blast	   = math.Round(BulletData.BlastRadius, 2)
			local FragMass = ACF.GetProperMass(BulletData.FragMass)
			local FragVel  = math.Round(BulletData.FragVel, 2)

			return Text:format(Blast, BulletData.Fragments, FragMass, FragVel)
		end)

		local PenStats = Base:AddLabel()
		PenStats:TrackClientData("Projectile", "SetText")
		PenStats:TrackClientData("Propellant")
		PenStats:TrackClientData("FillerMass")
		PenStats:DefineSetter(function()
			self:UpdateRoundData(ToolData, BulletData)

			local Text	   = "Penetration : %s mm RHA\nAt 300m : %s mm RHA @ %s m/s\nAt 800m : %s mm RHA @ %s m/s"
			local MaxPen   = math.Round(BulletData.MaxPen, 2)
			local R1V, R1P = ACF.PenRanging(BulletData.MuzzleVel, BulletData.DragCoef, BulletData.ProjMass, BulletData.PenArea, BulletData.LimitVel, 300)
			local R2V, R2P = ACF.PenRanging(BulletData.MuzzleVel, BulletData.DragCoef, BulletData.ProjMass, BulletData.PenArea, BulletData.LimitVel, 800)

			return Text:format(MaxPen, R1P, R1V, R2P, R2V)
		end)

		Base:AddLabel("Note: The penetration range data is an approximation and may not be entirely accurate.")
	end
end