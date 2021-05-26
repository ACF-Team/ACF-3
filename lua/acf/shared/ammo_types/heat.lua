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
	local Height     = Radius / math.tan(math.rad(ConeAngle))
	local ConeArea   = math.pi * Radius * math.sqrt(Height ^ 2 + Radius ^ 2)
	local ConeVol    = (math.pi * Radius ^ 2 * Height) / 3

	local AngleMult  = (45 + ConeAngle) / 45 -- Shallower cones need thicker liners to survive being made into EFPs
	local LinerThick = ACF.LinerThicknessMult * Radius * AngleMult
	local LinerVol   = ConeArea * LinerThick
	local LinerMass  = LinerVol * ACF.CopperDensity

	return LinerMass, ConeVol, Height
end

function Ammo:GetPenetration(Bullet, Standoff, TargetDensity)
	local BreakupT = Bullet.BreakupTime
	local MinVel   = Bullet.JetMinVel
	local MaxVel   = Bullet.JetMaxVel
	local Gamma    = math.sqrt(TargetDensity / ACF.CopperDensity)

	local Penetration = 0
	if Standoff < Bullet.BreakupDist then
		local JetTravel = BreakupT * MaxVel
		local K1 = 1 + Gamma
		local K2 = 1 / K1
		Penetration = (K1 * (JetTravel * Standoff) ^ K2 - math.sqrt(K1 * ACF.HEATMinPenVel * BreakupT * JetTravel ^ K2 * Standoff ^ (Gamma * K2))) / Gamma - Standoff
	else
		Penetration = (MaxVel * BreakupT - math.sqrt(ACF.HEATMinPenVel * BreakupT * (MaxVel * BreakupT + Gamma * Standoff))) / Gamma
	end

	return Penetration * ACF.HEATPenMul * 1e3 -- m to mm
end

function Ammo:GetDisplayData(Data)
	local Fragments  = math.max(math.floor((Data.BoomFillerMass / Data.CasingMass) * ACF.HEFrag), 2)
	local Display    = {
		BoomFillerMass = Data.BoomFillerMass,
		MaxPen         = self:GetPenetration(Data, Data.Standoff, ACF.SteelDensity),
		TotalFragMass  = Data.CasingMass,
		BlastRadius    = Data.BoomFillerMass ^ 0.33 * 8,
		Fragments      = Fragments,
		FragMass       = Data.CasingMass / Fragments,
		FragVel        = (Data.BoomFillerMass * ACF.HEPower * 1000 / Data.CasingMass) ^ 0.5,
	}

	hook.Run("ACF_GetDisplayData", self, Data, Display)

	return Display
end

function Ammo:UpdateRoundData(ToolData, Data, GUIData)
	GUIData = GUIData or Data

	ACF.UpdateRoundSpecs(ToolData, Data, GUIData)

	local CapLength       = GUIData.MinProjLength * 0.5
	local BodyLength      = Data.ProjLength - CapLength
	local FreeVol, FreeLength, FreeRadius = ACF.RoundShellCapacity(Data.PropMass, Data.ProjArea, Data.Caliber, BodyLength)
	local Standoff        = (CapLength + FreeLength * ToolData.StandoffRatio) * 1e-2 -- cm to m
	FreeVol               = FreeVol * (1 - ToolData.StandoffRatio)
	FreeLength            = FreeLength * (1 - ToolData.StandoffRatio)
	local ChargeDiameter  = 2 * FreeRadius
	local MinConeAng      = math.deg(math.atan(FreeRadius / FreeLength))
	local LinerAngle      = math.Clamp(ToolData.LinerAngle, MinConeAng, 90) -- Cone angle is angle between cone walls, not between a wall and the center line
	local LinerMass, ConeVol, ConeLength = self:ConeCalc(LinerAngle, FreeRadius)

	-- Charge length increases jet velocity, but with diminishing returns. All explosive sorrounding the cone has 100% effectiveness,
	--  but the explosive behind it has diminishing returns. Most papers put the maximum useful head length (explosive length behind the
	--  cone) at around 1.5-1.8 times the charge's diameter. Past that, adding more explosive won't do much.
	local RearFillLen  = FreeLength - ConeLength  -- Length of explosive behind the liner
	local Exponential  = math.exp(2 * RearFillLen / (ChargeDiameter * ACF.MaxChargeHeadLen))
	local EquivFillLen = ChargeDiameter * ACF.MaxChargeHeadLen * ((Exponential - 1) / (Exponential + 1)) -- Equivalent length of explosive
	local FrontFillVol = FreeVol * ConeLength / FreeLength - ConeVol -- Volume of explosive sorounding the liner
	local RearFillVol  = FreeVol * RearFillLen / FreeLength -- Volume behind the liner
	local EquivFillVol = FreeVol * EquivFillLen / FreeLength + FrontFillVol -- Equivalent total explosive volume
	local FillerEnergy = EquivFillVol * ACF.CompBDensity * 1e3 * ACF.TNTPower * ACF.CompBEquivalent
	local FillerVol    = FrontFillVol + RearFillVol
	local FillerMass   = FillerVol * ACF.CompBDensity

	-- At lower cone angles, the explosive crushes the cone inward, expelling a jet. The steeper the cone, the faster the jet, but the less mass expelled
	local MinVelMult = (0.98 - 0.6) * LinerAngle / 90 + 0.6
	local JetMass    = LinerMass * ((1 - 0.8)* LinerAngle / 90  + 0.8)
	local JetAvgVel  = (2 * FillerEnergy / JetMass) ^ 0.5  -- Average velocity of the copper jet
	local JetMinVel  = JetAvgVel * MinVelMult              -- Minimum velocity of the jet (the rear)
	-- Calculates the maximum velocity, considering the velocity distribution is linear from the rear to the tip (integrated this by hand, pain :) )
	local JetMaxVel  = 0.5 * (3 ^ 0.5 * (8 * FillerEnergy - JetMass * JetMinVel ^ 2) ^ 0.5 / JetMass ^ 0.5 - JetMinVel) -- Maximum velocity of the jet (the tip)

	-- Both the "magic numbers" are unitless, tuning constants that were used to fit the breakup time to real world values, I suggest they not be messed with
	local BreakupTime    = 1.6e-6 * (5e9 * JetMass / (JetMaxVel - JetMinVel)) ^ 0.3333  -- Jet breakup time in seconds
	local BreakupDist    = JetMaxVel * BreakupTime

	GUIData.MinConeAng = MinConeAng

	Data.ConeAng        = LinerAngle
	Data.MinConeAng     = MinConeAng
	Data.FillerMass     = FillerMass
	local NonCasingVol  = ACF.RoundShellCapacity(Data.PropMass, Data.ProjArea, Data.Caliber, Data.ProjLength)
	Data.CasingMass		= (GUIData.ProjVolume - NonCasingVol) * ACF.SteelDensity
	Data.ProjMass       = Data.FillerMass + Data.CasingMass + LinerMass
	Data.MuzzleVel      = ACF.MuzzleVelocity(Data.PropMass, Data.ProjMass, Data.Efficiency)
	Data.BoomFillerMass	= Data.FillerMass * ACF.HEATBoomConvert * ACF.CompBEquivalent -- In TNT equivalent
	Data.LinerMass      = LinerMass
	Data.JetMass        = JetMass
	Data.JetMinVel      = JetMinVel
	Data.JetMaxVel      = JetMaxVel
	Data.BreakupTime    = BreakupTime
	Data.Standoff       = Standoff
	Data.BreakupDist    = BreakupDist
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

	Data.ShovePower		= 0.1
	Data.LimitVel		= 100 -- Most efficient penetration speed in m/s
	Data.Ricochet		= 60 -- Base ricochet angle
	Data.DetonatorAngle	= 75
	Data.CanFuze		= Data.Caliber * 10 > ACF.MinFuzeCaliber -- Can fuze on calibers > 20mm

	self:UpdateRoundData(ToolData, Data, GUIData)

	return Data, GUIData
end

function Ammo:VerifyData(ToolData)
	Ammo.BaseClass.VerifyData(self, ToolData)

	if not isnumber(ToolData.FillerRatio) then
		ToolData.FillerRatio = 1
	end

	if not isnumber(ToolData.StandoffRatio) then
		ToolData.StandoffRatio = 0
	end

	if not isnumber(ToolData.LinerAngle) then
		ToolData.LinerAngle = 90
	end
end

if SERVER then
	ACF.AddEntityArguments("acf_ammo", "LinerAngle") -- Adding extra info to ammo crates

	function Ammo:OnLast(Entity)
		Ammo.BaseClass.OnLast(self, Entity)

		Entity.FillerRatio = nil
		Entity.LinerAngle  = nil

		-- Cleanup the leftovers aswell
		Entity.FillerMass = nil
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
		ACF.HE(HitPos, Bullet.BoomFillerMass, Bullet.CasingMass, Bullet.Owner, Bullet.Filter, Bullet.Gun)

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
		local LinerAngle = Base:AddSlider("Liner Angle", BulletData.MinConeAng, 90, 1)
		LinerAngle:SetClientData("LinerAngle", "OnValueChanged")
		LinerAngle:TrackClientData("Projectile")
		LinerAngle:DefineSetter(function(Panel, _, Key, Value)
			if Key == "LinerAngle" then
				ToolData.LinerAngle = math.Round(Value, 2)
			end

			self:UpdateRoundData(ToolData, BulletData)

			Panel:SetMin(BulletData.MinConeAng)
			Panel:SetValue(BulletData.ConeAng)

			return BulletData.ConeAng
		end)

		local FillerRatio = Base:AddSlider("Filler Ratio", 0.5, 1, 2)
		FillerRatio:SetClientData("FillerRatio", "OnValueChanged")
		FillerRatio:DefineSetter(function(_, _, _, Value)
			ToolData.FillerRatio = math.Round(Value, 2)

			self:UpdateRoundData(ToolData, BulletData)

			return BulletData.FillerVol
		end)

		-- Capped the max standoff at 0.4 for historical reasons
		local StandoffRatio = Base:AddSlider("Extra Standoff Ratio", 0, 0.4, 2)
		StandoffRatio:SetClientData("StandoffRatio", "OnValueChanged")
		StandoffRatio:DefineSetter(function(_, _, _, Value)
			ToolData.StandoffRatio = math.Round(Value, 2)

			self:UpdateRoundData(ToolData, BulletData)

			-- TODO what should this be?
			return BulletData.FillerVol
		end)
	end

	function Ammo:AddCrateDataTrackers(Trackers, ...)
		Ammo.BaseClass.AddCrateDataTrackers(self, Trackers, ...)

		Trackers.FillerRatio = true
		Trackers.LinerAngle = true
		Trackers.StandoffRatio = true
	end

	function Ammo:AddAmmoInformation(Base, ToolData, BulletData)
		local RoundStats = Base:AddLabel()
		RoundStats:TrackClientData("Projectile", "SetText")
		RoundStats:TrackClientData("Propellant")
		RoundStats:TrackClientData("FillerRatio")
		RoundStats:TrackClientData("LinerAngle")
		RoundStats:TrackClientData("StandoffRatio")
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
		FillerStats:TrackClientData("Projectile", "SetText")
		FillerStats:TrackClientData("Propellant")
		FillerStats:TrackClientData("FillerRatio")
		FillerStats:TrackClientData("LinerAngle")
		FillerStats:TrackClientData("StandoffRatio")
		FillerStats:DefineSetter(function()
			self:UpdateRoundData(ToolData, BulletData)

			local Text	   = "Blast Radius : %s m\nFragments : %s\nFragment Mass : %s\nFragment Velocity : %s m/s"
			local Blast	   = math.Round(BulletData.BlastRadius, 2)
			local FragMass = ACF.GetProperMass(BulletData.FragMass)
			local FragVel  = math.Round(BulletData.FragVel, 2)

			return Text:format(Blast, BulletData.Fragments, FragMass, FragVel)
		end)

		-- TODO this should prolly be removed
		local Penetrator = Base:AddLabel()
		Penetrator:TrackClientData("Projectile", "SetText")
		Penetrator:TrackClientData("Propellant")
		Penetrator:TrackClientData("FillerRatio")
		Penetrator:TrackClientData("LinerAngle")
		Penetrator:TrackClientData("StandoffRatio")
		Penetrator:DefineSetter(function()
			self:UpdateRoundData(ToolData, BulletData)

			local Text     = "Copper mass : %s g\nJet mass : %s g\nJet velocity : %s m/s - %s m/s"
			local CuMass   = math.Round(BulletData.LinerMass * 1e3, 0)
			local JetMass  = math.Round(BulletData.JetMass * 1e3, 0)
			local MinVel   = math.Round(BulletData.JetMinVel, 0)
			local MaxVel   = math.Round(BulletData.JetMaxVel, 0)

			return Text:format(CuMass, JetMass, MinVel, MaxVel)
		end)

		-- TODO add pen stats at passive standoff + maybe max pen
		local PenStats = Base:AddLabel()
		PenStats:TrackClientData("Projectile", "SetText")
		PenStats:TrackClientData("Propellant")
		PenStats:TrackClientData("FillerRatio")
		PenStats:TrackClientData("LinerAngle")
		PenStats:TrackClientData("StandoffRatio")
		PenStats:DefineSetter(function()
			self:UpdateRoundData(ToolData, BulletData)

			local Text   = "Penetration at passive standoff :\nAt %s mm : %s mm RHA\nMaximum penetration :\nAt %s mm : %s mm RHA"
			local Standoff1 = math.Round(BulletData.Standoff * 1e3, 0)
			local Pen1 = math.Round(self:GetPenetration(BulletData, BulletData.Standoff, ACF.SteelDensity), 1)
			local Standoff2 = math.Round(BulletData.BreakupDist * 1e3, 0)
			local Pen2 = math.Round(self:GetPenetration(BulletData, BulletData.BreakupDist, ACF.SteelDensity), 1)

			return Text:format(Standoff1, Pen1, Standoff2, Pen2)
		end)

		-- TODO remove this?
		Base:AddLabel("Note: The penetration range data is an approximation and may not be entirely accurate.")
	end
end