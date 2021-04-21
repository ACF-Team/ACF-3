local Ammo = ACF.RegisterAmmoType("HEAT", "AP")

function Ammo:OnLoaded()
	Ammo.BaseClass.OnLoaded(self)

	self.Name		 = "High Explosive Anti-Tank"
	self.Description = "A round with a shaped charge inside. Fires a high-velocity jet on detonation."
	self.Blacklist = {
		AC = true,
		MG = true,
		MO = true,
		SB = true,
		SL = true,
		LAC = true,
		RAC = true,
	}
end

function Ammo:ConeCalc(ConeAngle, Radius)
	local ConeLength = math.tan(math.rad(ConeAngle)) * Radius
	local ConeArea = math.pi * Radius * (Radius ^ 2 + ConeLength ^ 2) ^ 0.5
	local ConeVol = (math.pi * Radius ^ 2 * ConeLength) * 0.33

	return ConeLength, ConeArea, ConeVol
end

function Ammo:CalcSlugMV(Data)
	--keep fillermass/2 so that penetrator stays the same.
	return (Data.HEATFillerMass * 0.5 * ACF.HEPower * math.sin(math.rad(10 + Data.ConeAng) * 0.5) / Data.SlugMass) ^ ACF.HEATMVScale
end

function Ammo:GetPenetration(Bullet, Speed, Detonated)
	if not isnumber(Speed) then
		Speed = Bullet.Flight and Bullet.Flight:Length() / ACF.Scale * 0.0254 or Bullet.MuzzleVel
	end

	local Caliber = Bullet.Diameter
	local Mass    = Bullet.ProjMass

	if Detonated or Bullet.Detonated then
		Speed   = Bullet.SlugMV
		Mass    = Bullet.SlugMass
		Caliber = Bullet.SlugCaliber
	end

	return ACF.Penetration(Speed, Mass, Caliber * 10)
end

function Ammo:GetDisplayData(Data)
	local SlugMV     = self:CalcSlugMV(Data) * (Data.SlugPenMul or 1)
	local Fragments  = math.max(math.floor((Data.HEATFillerMass / Data.CasingMass) * ACF.HEFrag), 2)
	local Display    = {
		HEATFillerMass = Data.HEATFillerMass,
		BoomFillerMass = Data.BoomFillerMass,
		SlugMV         = SlugMV,
		SlugMassUsed   = Data.SlugMass,
		MaxPen         = self:GetPenetration(Data, Data.MuzzleVel, true),
		TotalFragMass  = Data.CasingMass,
		BlastRadius    = Data.BoomFillerMass ^ 0.33 * 8,
		Fragments      = Fragments,
		FragMass       = Data.CasingMass / Fragments,
		FragVel        = (Data.HEATFillerMass * ACF.HEPower * 1000 / Data.CasingMass) ^ 0.5,
	}

	hook.Run("ACF_GetDisplayData", self, Data, Display)

	return Display
end

function Ammo:UpdateRoundData(ToolData, Data, GUIData)
	GUIData = GUIData or Data

	ACF.UpdateRoundSpecs(ToolData, Data, GUIData)


	local FreeVol, FreeLength = ACF.RoundShellCapacity(Data.PropMass, Data.ProjArea, Data.Caliber, Data.ProjLength)
	local MaxConeAng = math.deg(math.atan((FreeLength - Data.Caliber * 0.02) / (Data.Caliber * 0.5)))
	local LinerAngle = math.Clamp(ToolData.LinerAngle, GUIData.MinConeAng, MaxConeAng)
	local _, ConeArea, AirVol = self:ConeCalc(LinerAngle, Data.Caliber * 0.5)
	local FreeFillerVol = FreeVol - AirVol

	local LinerRad    = math.rad(LinerAngle * 0.5)
	local SlugCaliber = Data.Caliber - Data.Caliber * (math.sin(LinerRad) * 0.5 + math.cos(LinerRad) * 1.5) * 0.5
	local SlugArea    = math.pi * (SlugCaliber * 0.5) ^ 2
	local ConeVol     = ConeArea * Data.Caliber * 0.02

	GUIData.MaxConeAng = MaxConeAng

	Data.ConeAng        = LinerAngle
	Data.FillerMass     = FreeFillerVol * ToolData.FillerRatio * ACF.HEDensity
	Data.CasingMass		= (GUIData.ProjVolume - FreeVol) * ACF.SteelDensity
	Data.ProjMass       = (math.max(FreeFillerVol * (1 - ToolData.FillerRatio), 0) + ConeVol) * ACF.SteelDensity + Data.FillerMass + Data.CasingMass
	Data.MuzzleVel      = ACF.MuzzleVelocity(Data.PropMass, Data.ProjMass, Data.Efficiency)
	Data.SlugMass       = ConeVol * ACF.SteelDensity
	Data.SlugCaliber    = SlugCaliber
	Data.SlugDragCoef   = SlugArea * 0.0001 / Data.SlugMass
	Data.BoomFillerMass	= Data.FillerMass * ACF.HEATBoomConvert
	Data.HEATFillerMass = Data.FillerMass
	Data.SlugMV			= self:CalcSlugMV(Data) * (Data.SlugPenMul or 1)
	Data.DragCoef		= Data.ProjArea * 0.0001 / Data.ProjMass
	Data.CartMass		= Data.PropMass + Data.ProjMass

	hook.Run("ACF_UpdateRoundData", self, ToolData, Data, GUIData)

	for K, V in pairs(self:GetDisplayData(Data)) do
		GUIData[K] = V
	end
end

function Ammo:BaseConvert(ToolData)
	local Data, GUIData = ACF.RoundBaseGunpowder(ToolData, {})

	GUIData.MinConeAng	 = 0
	GUIData.MinFillerVol = 0

	Data.SlugRicochet	= 500 -- Base ricochet angle (The HEAT slug shouldn't ricochet at all)
	Data.ShovePower		= 0.1
	Data.LimitVel		= 100 -- Most efficient penetration speed in m/s
	Data.Ricochet		= 60 -- Base ricochet angle
	Data.DetonatorAngle	= 75
	Data.Detonated		= false
	Data.NotFirstPen	= false
	Data.CanFuze		= Data.Caliber * 10 > ACF.MinFuzeCaliber -- Can fuze on calibers > 20mm

	self:UpdateRoundData(ToolData, Data, GUIData)

	return Data, GUIData
end

function Ammo:VerifyData(ToolData)
	Ammo.BaseClass.VerifyData(self, ToolData)

	if not ToolData.FillerMass then
		local Data5 = ToolData.RoundData5

		ToolData.FillerMass = Data5 and tonumber(Data5) or 0
	end

	if not ToolData.LinerAngle then
		local Data6 = ToolData.RoundData6

		ToolData.LinerAngle = Data6 and tonumber(Data6) or 0
	end
end

if SERVER then
	ACF.AddEntityArguments("acf_ammo", "LinerAngle") -- Adding extra info to ammo crates

	function Ammo:OnLast(Entity)
		Ammo.BaseClass.OnLast(self, Entity)

		Entity.FillerMass = nil
		Entity.LinerAngle = nil

		-- Cleanup the leftovers aswell
		Entity.RoundData5 = nil
		Entity.RoundData6 = nil

		Entity:SetNW2Float("FillerMass", 0)
	end

	function Ammo:Network(Entity, BulletData)
		Ammo.BaseClass.Network(self, Entity, BulletData)

		Entity:SetNW2String("AmmoType", "HEAT")
		Entity:SetNW2Float("FillerMass", BulletData.BoomFillerMass)
	end

	function Ammo:GetCrateText(BulletData)
		local Text = "Muzzle Velocity: %s m/s\nMax Penetration: %s mm\nBlast Radius: %s m\n", "Blast Energy: %s KJ"
		local Data = self:GetDisplayData(BulletData)

		return Text:format(math.Round(BulletData.MuzzleVel, 2), math.Round(Data.MaxPen, 2), math.Round(Data.BlastRadius, 2), math.Round(Data.BoomFillerMass * ACF.HEPower, 2))
	end

	function Ammo:Detonate(Bullet, HitPos)
		ACF_HE(HitPos, Bullet.BoomFillerMass, Bullet.CasingMass, Bullet.Owner, Bullet.Filter, Bullet.Gun)

		local SlugMV = self:CalcSlugMV(Bullet) * 39.37 * (Bullet.SlugPenMul or 1)

		Bullet.Detonated = true
		Bullet.Flight    = Bullet.Flight:GetNormalized() * SlugMV
		Bullet.NextPos   = HitPos
		Bullet.DragCoef  = Bullet.SlugDragCoef
		Bullet.ProjMass  = Bullet.SlugMass
		Bullet.Caliber   = Bullet.SlugCaliber
		Bullet.Diameter  = Bullet.Caliber
		Bullet.Ricochet  = Bullet.SlugRicochet
		Bullet.LimitVel  = 999999

		return true
	end

	function Ammo:PropImpact(Bullet, Trace)
		local Target = Trace.Entity

		if ACF.Check(Target) then
			local Speed  = Bullet.Flight:Length() / ACF.Scale
			local HitPos = Trace.HitPos

			Bullet.Speed = Speed

			if Bullet.Detonated then
				local Multiplier = Bullet.NotFirstPen and ACF.HEATPenLayerMul or 1
				local Energy     = ACF.Kinetic(Speed, Bullet.ProjMass)

				Bullet.Energy      = Energy
				Bullet.NotFirstPen = true

				local HitRes = ACF_RoundImpact(Bullet, Trace)

				if HitRes.Overkill > 0 then
					table.insert(Bullet.Filter, Target) --"Penetrate" (Ingoring the prop for the retry trace)

					Bullet.Flight = Bullet.Flight:GetNormalized() * math.sqrt(Energy.Kinetic * (1 - HitRes.Loss) * Multiplier * 2000 / Bullet.ProjMass) * 39.37

					return "Penetrated"
				else
					return false
				end
			else
				Bullet.Energy = ACF.Kinetic(Speed, Bullet.ProjMass - Bullet.FillerMass)

				local HitRes = ACF_RoundImpact(Bullet, Trace)

				if HitRes.Ricochet then
					return "Ricochet"
				else
					if self:Detonate(Bullet, HitPos) then
						return "Penetrated"
					else
						return false
					end
				end
			end
		else
			table.insert(Bullet.Filter, Target)

			return "Penetrated"
		end

		return false
	end

	function Ammo:WorldImpact(Bullet, Trace)
		if not Bullet.Detonated then
			if self:Detonate(Bullet, Trace.HitPos) then
				return "Penetrated"
			else
				return false
			end
		end

		local Function = ACF.Check(Trace.Entity) and ACF_PenetrateMapEntity or ACF_PenetrateGround

		return Function(Bullet, Trace)
	end
else
	ACF.RegisterAmmoDecal("HEAT", "damage/heat_pen", "damage/heat_rico", function(Caliber) return Caliber * 0.1667 end)

	local DecalIndex = ACF.GetAmmoDecalIndex

	function Ammo:GetRangedPenetration(Bullet, Range)
		local Speed = ACF.GetRangedSpeed(Bullet.MuzzleVel, Bullet.DragCoef, Range) * 0.0254

		return math.Round(self:GetPenetration(Bullet, Speed, true), 2), math.Round(Speed, 2)
	end

	function Ammo:ImpactEffect(Effect, Bullet)
		if not Bullet.Detonated then
			self:PenetrationEffect(Effect, Bullet)
		end

		Ammo.BaseClass.ImpactEffect(self, Effect, Bullet)
	end

	function Ammo:PenetrationEffect(Effect, Bullet)
		if Bullet.Detonated then
			local Data = EffectData()
			Data:SetOrigin(Bullet.SimPos)
			Data:SetNormal(Bullet.SimFlight:GetNormalized())
			Data:SetScale(Bullet.SimFlight:Length())
			Data:SetMagnitude(Bullet.RoundMass)
			Data:SetRadius(Bullet.Caliber)
			Data:SetDamageType(DecalIndex(Bullet.AmmoType))

			util.Effect("ACF_Penetration", Data)
		else
			local Data = EffectData()
			Data:SetOrigin(Bullet.SimPos)
			Data:SetNormal(Bullet.SimFlight:GetNormalized())
			Data:SetRadius(math.max(Bullet.FillerMass ^ 0.33 * 8 * 39.37, 1))

			util.Effect("ACF_HEAT_Explosion", Data)

			Bullet.Detonated = true
			Bullet.LimitVel  = 999999

			Effect:SetModel("models/Gibs/wood_gib01e.mdl")
		end
	end

	function Ammo:RicochetEffect(_, Bullet)
		local Detonated = Bullet.Detonated
		local Effect = EffectData()
		Effect:SetOrigin(Bullet.SimPos)
		Effect:SetNormal(Bullet.SimFlight:GetNormalized())
		Effect:SetScale(Bullet.SimFlight:Length())
		Effect:SetMagnitude(Bullet.RoundMass)
		Effect:SetRadius(Bullet.Caliber)
		Effect:SetDamageType(DecalIndex(Detonated and Bullet.AmmoType or "AP"))

		util.Effect("ACF_Ricochet", Effect)
	end

	function Ammo:AddAmmoControls(Base, ToolData, BulletData)
		local LinerAngle = Base:AddSlider("Liner Angle", BulletData.MinConeAng, BulletData.MaxConeAng, 2)
		LinerAngle:SetClientData("LinerAngle", "OnValueChanged")
		LinerAngle:TrackClientData("Projectile")
		LinerAngle:DefineSetter(function(Panel, _, Key, Value)
			if Key == "LinerAngle" then
				ToolData.LinerAngle = math.Round(Value, 2)
			end

			self:UpdateRoundData(ToolData, BulletData)

			Panel:SetMax(BulletData.MaxConeAng)
			Panel:SetValue(BulletData.ConeAng)

			return BulletData.ConeAng
		end)

		local FillerRatio = Base:AddSlider("Filler Ratio", 0, 1, 2)
		FillerRatio:SetClientData("FillerRatio", "OnValueChanged")
		FillerRatio:DefineSetter(function(_, _, Key, Value)
			if Key == "FillerRatio" then
				ToolData.FillerRatio = math.Round(Value, 2)
			end

			self:UpdateRoundData(ToolData, BulletData)

			return BulletData.FillerVol
		end)
	end

	function Ammo:AddCrateDataTrackers(Trackers, ...)
		Ammo.BaseClass.AddCrateDataTrackers(self, Trackers, ...)

		Trackers.FillerRatio = true
		Trackers.LinerAngle = true
	end

	function Ammo:AddAmmoInformation(Base, ToolData, BulletData)
		local RoundStats = Base:AddLabel()
		RoundStats:TrackClientData("Projectile", "SetText")
		RoundStats:TrackClientData("Propellant")
		RoundStats:TrackClientData("FillerRatio")
		RoundStats:TrackClientData("LinerAngle")
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
		FillerStats:TrackClientData("FillerRatio", "SetText")
		FillerStats:TrackClientData("LinerAngle")
		FillerStats:DefineSetter(function()
			self:UpdateRoundData(ToolData, BulletData)

			local Text	   = "Blast Radius : %s m\nFragments : %s\nFragment Mass : %s\nFragment Velocity : %s m/s"
			local Blast	   = math.Round(BulletData.BlastRadius, 2)
			local FragMass = ACF.GetProperMass(BulletData.FragMass)
			local FragVel  = math.Round(BulletData.FragVel, 2)

			return Text:format(Blast, BulletData.Fragments, FragMass, FragVel)
		end)

		local Penetrator = Base:AddLabel()
		Penetrator:TrackClientData("Projectile", "SetText")
		Penetrator:TrackClientData("Propellant")
		Penetrator:TrackClientData("FillerRatio")
		Penetrator:TrackClientData("LinerAngle")
		Penetrator:DefineSetter(function()
			self:UpdateRoundData(ToolData, BulletData)

			local Text	   = "Penetrator Caliber : %s mm\nPenetrator Mass : %s\nPenetrator Velocity : %s m/s"
			local Caliber  = math.Round(BulletData.SlugCaliber * 10, 2)
			local Mass	   = ACF.GetProperMass(BulletData.SlugMassUsed)
			local Velocity = math.Round(BulletData.SlugMV, 2)

			return Text:format(Caliber, Mass, Velocity)
		end)

		local PenStats = Base:AddLabel()
		PenStats:TrackClientData("Projectile", "SetText")
		PenStats:TrackClientData("Propellant")
		PenStats:TrackClientData("FillerRatio")
		PenStats:TrackClientData("LinerAngle")
		PenStats:DefineSetter(function()
			self:UpdateRoundData(ToolData, BulletData)

			local Text   = "Penetration : %s mm RHA\nAt 300m : %s mm RHA @ %s m/s\nAt 800m : %s mm RHA @ %s m/s"
			local MaxPen = math.Round(BulletData.MaxPen, 2)
			local _, R1V = self:GetRangedPenetration(BulletData, 300)
			local _, R2V = self:GetRangedPenetration(BulletData, 800)

			return Text:format(MaxPen, MaxPen, R1V, MaxPen, R2V)
		end)

		Base:AddLabel("Note: The penetration range data is an approximation and may not be entirely accurate.")
	end
end