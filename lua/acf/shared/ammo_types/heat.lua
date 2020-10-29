local Ammo = ACF.RegisterAmmoType("HEAT", "AP")

function Ammo:OnLoaded()
	Ammo.BaseClass.OnLoaded(self)

	self.Name		 = "High Explosive Anti-Tank"
	self.Description = "A round with a shaped charge inside. Fires a high-velocity jet on detonation."
	self.Blacklist = {
		AC = true,
		MG = true,
		SB = true,
		SL = true,
		HMG = true,
		RAC = true,
	}
end

function Ammo:ConeCalc(ConeAngle, Radius)
	local ConeLength = math.tan(math.rad(ConeAngle)) * Radius
	local ConeArea = 3.1416 * Radius * (Radius ^ 2 + ConeLength ^ 2) ^ 0.5
	local ConeVol = (3.1416 * Radius ^ 2 * ConeLength) * 0.33

	return ConeLength, ConeArea, ConeVol
end

-- calculates conversion of filler from powering HEAT jet to raw HE based on crush vel
-- above a threshold vel, HEAT jet doesn't have time to form properly, converting to raw HE proportionally
-- Vel needs to be in m/s (gmu*0.0254)
function Ammo:CrushCalc(Vel, FillerMass)
	local Crushed = math.Clamp((Vel - ACF.HEATMinCrush) / (ACF.HEATMaxCrush - ACF.HEATMinCrush), 0, 1)
	local HE_Filler = Lerp(Crushed, FillerMass * ACF.HEATBoomConvert, FillerMass)
	local HEAT_Filler = Lerp(Crushed, FillerMass, 0)

	return Crushed, HEAT_Filler, HE_Filler
end

-- coneang now required for slug recalculation at detonation, defaults to 55 if not present
function Ammo:CalcSlugMV(Data, HEATFillerMass)
	--keep fillermass/2 so that penetrator stays the same.
	return (HEATFillerMass * 0.5 * ACF.HEPower * math.sin(math.rad(10 + (Data.ConeAng or 55)) * 0.5) / Data.SlugMass) ^ ACF.HEATMVScale
end

function Ammo:GetDisplayData(Data)
	local Crushed, HEATFiller, BoomFiller = self:CrushCalc(Data.MuzzleVel, Data.FillerMass)
	local SlugMV	= self:CalcSlugMV(Data, HEATFiller) * (Data.SlugPenMul or 1)
	local MassUsed	= Data.SlugMass * (1 - Crushed)
	local Energy	= ACF_Kinetic(Data.MuzzleVel * 39.37 + SlugMV * 39.37, MassUsed, 999999)
	local FragMass	= Data.CasingMass + Data.SlugMass * Crushed
	local Fragments	= math.max(math.floor((BoomFiller / FragMass) * ACF.HEFrag), 2)

	return {
		Crushed		   = Crushed,
		HEATFillerMass = HEATFiller,
		BoomFillerMass = BoomFiller,
		SlugMV		   = SlugMV,
		SlugMassUsed   = MassUsed,
		MaxPen		   = (Energy.Penetration / Data.SlugPenArea) * ACF.KEtoRHA,
		TotalFragMass  = FragMass,
		BlastRadius	   = BoomFiller ^ 0.33 * 8,
		Fragments	   = Fragments,
		FragMass	   = FragMass / Fragments,
		FragVel		   = (BoomFiller * ACF.HEPower * 1000 / FragMass) ^ 0.5,
	}
end

function Ammo:UpdateRoundData(ToolData, Data, GUIData)
	GUIData = GUIData or Data

	ACF.UpdateRoundSpecs(ToolData, Data, GUIData)

	local MaxConeAng = math.deg(math.atan((Data.ProjLength - Data.Caliber * 0.02) / (Data.Caliber * 0.5)))
	local LinerAngle = math.Clamp(ToolData.LinerAngle, GUIData.MinConeAng, MaxConeAng)
	local _, ConeArea, AirVol = self:ConeCalc(LinerAngle, Data.Caliber * 0.5)

	local LinerRad	  = math.rad(LinerAngle * 0.5)
	local SlugCaliber = Data.Caliber - Data.Caliber * (math.sin(LinerRad) * 0.5 + math.cos(LinerRad) * 1.5) / 2
	local SlugFrArea  = 3.1416 * (SlugCaliber * 0.5) ^ 2
	local ConeVol	  = ConeArea * Data.Caliber * 0.02
	local ProjMass	  = math.max(GUIData.ProjVolume - ToolData.FillerMass, 0) * 0.0079 + math.min(ToolData.FillerMass, GUIData.ProjVolume) * ACF.HEDensity * 0.001 + ConeVol * 0.0079 --Volume of the projectile as a cylinder - Volume of the filler - Volume of the crush cone * density of steel + Volume of the filler * density of TNT + Area of the cone * thickness * density of steel
	local MuzzleVel	  = ACF_MuzzleVelocity(Data.PropMass, ProjMass)
	local Energy	  = ACF_Kinetic(MuzzleVel * 39.37, ProjMass, Data.LimitVel)
	local MaxVol	  = ACF.RoundShellCapacity(Energy.Momentum, Data.FrArea, Data.Caliber, Data.ProjLength)

	GUIData.MaxConeAng	 = MaxConeAng
	GUIData.MaxFillerVol = math.max(math.Round(MaxVol - AirVol - ConeVol, 2), GUIData.MinFillerVol)
	GUIData.FillerVol	 = math.Clamp(ToolData.FillerMass, GUIData.MinFillerVol, GUIData.MaxFillerVol)

	Data.ConeAng	  = LinerAngle
	Data.FillerMass	  = GUIData.FillerVol * ACF.HEDensity * 0.00069
	Data.ProjMass	  = math.max(GUIData.ProjVolume - GUIData.FillerVol - AirVol - ConeVol, 0) * 0.0079 + Data.FillerMass + ConeVol * 0.0079
	Data.MuzzleVel	  = ACF_MuzzleVelocity(Data.PropMass, Data.ProjMass)
	Data.SlugMass	  = ConeVol * 0.0079
	Data.SlugCaliber  = SlugCaliber
	Data.SlugPenArea  = SlugFrArea ^ ACF.PenAreaMod
	Data.SlugDragCoef = SlugFrArea * 0.0001 / Data.SlugMass

	local _, HEATFiller, BoomFiller = self:CrushCalc(Data.MuzzleVel, Data.FillerMass)

	Data.BoomFillerMass	= BoomFiller
	Data.SlugMV			= self:CalcSlugMV(Data, HEATFiller)
	Data.CasingMass		= Data.ProjMass - Data.FillerMass - ConeVol * 0.0079
	Data.DragCoef		= Data.FrArea * 0.0001 / Data.ProjMass
	Data.CartMass		= Data.PropMass + Data.ProjMass

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
	Data.PenArea		= Data.FrArea ^ ACF.PenAreaMod
	Data.LimitVel		= 100 -- Most efficient penetration speed in m/s
	Data.KETransfert	= 0.1 -- Kinetic energy transfert to the target for movement purposes
	Data.Ricochet		= 60 -- Base ricochet angle
	Data.DetonatorAngle	= 75
	Data.Detonated		= false
	Data.NotFirstPen	= false
	Data.CanFuze		= Data.Caliber > ACF.MinFuzeCaliber -- Can fuze on calibers > 20mm

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
		Entity:SetNW2Float("FillerMass", BulletData.FillerMass)
	end

	function Ammo:GetCrateText(BulletData)
		local Text = "Muzzle Velocity: %s m/s\nMax Penetration: %s mm\nBlast Radius: %s m\n", "Blast Energy: %s KJ"
		local Data = self:GetDisplayData(BulletData)

		return Text:format(math.Round(BulletData.MuzzleVel, 2), math.Round(Data.MaxPen, 2), math.Round(Data.BlastRadius, 2), math.Round(Data.BoomFillerMass * ACF.HEPower, 2))
	end

	function Ammo:Detonate(Bullet, HitPos)
		local Crushed, HEATFillerMass, BoomFillerMass = self:CrushCalc(Bullet.Flight:Length() * 0.0254, Bullet.FillerMass)

		ACF_HE(HitPos, BoomFillerMass, Bullet.CasingMass + Bullet.SlugMass * Crushed, Bullet.Owner, nil, Bullet.Gun)

		if Crushed == 1 then return false end -- no HEAT jet to fire off, it was all converted to HE

		local DeltaTime = ACF.CurTime - Bullet.LastThink

		Bullet.Detonated  = true
		Bullet.InitTime	  = ACF.CurTime
		Bullet.Flight	  = Bullet.Flight + Bullet.Flight:GetNormalized() * self:CalcSlugMV(Bullet, HEATFillerMass) * 39.37
		Bullet.Pos		  = HitPos
		Bullet.DragCoef	  = Bullet.SlugDragCoef
		Bullet.ProjMass	  = Bullet.SlugMass * (1 - Crushed)
		Bullet.Caliber	  = Bullet.SlugCaliber
		Bullet.PenArea	  = Bullet.SlugPenArea
		Bullet.Ricochet	  = Bullet.SlugRicochet
		Bullet.StartTrace = Bullet.Pos - Bullet.Flight:GetNormalized() * math.min(ACF.PhysMaxVel * DeltaTime, Bullet.FlightTime * Bullet.Flight:Length())
		Bullet.NextPos	  = Bullet.Pos + (Bullet.Flight * ACF.Scale * DeltaTime) --Calculates the next shell position

		return true
	end

	function Ammo:PropImpact(_, Bullet, Target, HitNormal, HitPos, Bone)
		if ACF_Check(Target) then
			local Speed = Bullet.Flight:Length() / ACF.Scale

			if Bullet.Detonated then
				Bullet.NotFirstPen = true

				local Energy = ACF_Kinetic(Speed, Bullet.ProjMass, 999999)
				local HitRes = ACF_RoundImpact(Bullet, Speed, Energy, Target, HitPos, HitNormal, Bone)

				if HitRes.Overkill > 0 then
					table.insert(Bullet.Filter, Target) --"Penetrate" (Ingoring the prop for the retry trace)

					Bullet.Flight = Bullet.Flight:GetNormalized() * math.sqrt(Energy.Kinetic * (1 - HitRes.Loss) * ((Bullet.NotFirstPen and ACF.HEATPenLayerMul) or 1) * 2000 / Bullet.ProjMass) * 39.37

					return "Penetrated"
				else
					return false
				end
			else
				local Energy = ACF_Kinetic(Speed, Bullet.ProjMass - Bullet.FillerMass, Bullet.LimitVel)
				local HitRes = ACF_RoundImpact(Bullet, Speed, Energy, Target, HitPos, HitNormal, Bone)

				if HitRes.Ricochet then
					return "Ricochet"
				else
					if self:Detonate(Bullet, HitPos, HitNormal) then
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

	function Ammo:WorldImpact(_, Bullet, HitPos, HitNormal)
		if not Bullet.Detonated then
			if self:Detonate(Bullet, HitPos, HitNormal) then
				return "Penetrated"
			else
				return false
			end
		end

		local Energy = ACF_Kinetic(Bullet.Flight:Length() / ACF.Scale, Bullet.ProjMass, 999999)
		local HitRes = ACF_PenetrateGround(Bullet, Energy, HitPos, HitNormal)

		if HitRes.Penetrated then
			return "Penetrated"
		else
			return false
		end
	end
else
	ACF.RegisterAmmoDecal("HEAT", "damage/heat_pen", "damage/heat_rico", function(Caliber) return Caliber * 0.1667 end)

	local DecalIndex = ACF.GetAmmoDecalIndex

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
			local _, _, BoomFillerMass = self:CrushCalc(Bullet.SimFlight:Length() * 0.0254, Bullet.FillerMass)
			local Data = EffectData()
			Data:SetOrigin(Bullet.SimPos)
			Data:SetNormal(Bullet.SimFlight:GetNormalized())
			Data:SetRadius(math.max(BoomFillerMass ^ 0.33 * 8 * 39.37, 1))

			util.Effect("ACF_HEAT_Explosion", Data)

			Bullet.Detonated = true

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

	function Ammo:MenuAction(Menu, ToolData, Data)
		local LinerAngle = Menu:AddSlider("Liner Angle", Data.MinConeAng, Data.MaxConeAng, 2)
		LinerAngle:SetDataVar("LinerAngle", "OnValueChanged")
		LinerAngle:TrackDataVar("Projectile")
		LinerAngle:SetValueFunction(function(Panel)
			ToolData.LinerAngle = math.Round(ACF.ReadNumber("LinerAngle"), 2)

			self:UpdateRoundData(ToolData, Data)

			Panel:SetMax(Data.MaxConeAng)
			Panel:SetValue(Data.ConeAng)

			return Data.ConeAng
		end)

		local FillerMass = Menu:AddSlider("Filler Volume", 0, Data.MaxFillerVol, 2)
		FillerMass:SetDataVar("FillerMass", "OnValueChanged")
		FillerMass:TrackDataVar("Projectile")
		FillerMass:TrackDataVar("LinerAngle")
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
		RoundStats:TrackDataVar("LinerAngle")
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
		FillerStats:TrackDataVar("LinerAngle")
		FillerStats:SetValueFunction(function()
			self:UpdateRoundData(ToolData, Data)

			local Text	   = "Blast Radius : %s m\nFragments : %s\nFragment Mass : %s\nFragment Velocity : %s m/s"
			local Blast	   = math.Round(Data.BlastRadius, 2)
			local FragMass = ACF.GetProperMass(Data.FragMass)
			local FragVel  = math.Round(Data.FragVel, 2)

			return Text:format(Blast, Data.Fragments, FragMass, FragVel)
		end)

		local Penetrator = Menu:AddLabel()
		Penetrator:TrackDataVar("Projectile", "SetText")
		Penetrator:TrackDataVar("Propellant")
		Penetrator:TrackDataVar("FillerMass")
		Penetrator:TrackDataVar("LinerAngle")
		Penetrator:SetValueFunction(function()
			self:UpdateRoundData(ToolData, Data)

			local Text	   = "Penetrator Caliber : %s mm\nPenetrator Mass : %s\nPenetrator Velocity : %s m/s"
			local Caliber  = math.Round(Data.SlugCaliber * 10, 2)
			local Mass	   = ACF.GetProperMass(Data.SlugMassUsed)
			local Velocity = math.Round(Data.MuzzleVel + Data.SlugMV, 2)

			return Text:format(Caliber, Mass, Velocity)
		end)

		local PenStats = Menu:AddLabel()
		PenStats:TrackDataVar("Projectile", "SetText")
		PenStats:TrackDataVar("Propellant")
		PenStats:TrackDataVar("FillerMass")
		PenStats:TrackDataVar("LinerAngle")
		PenStats:SetValueFunction(function()
			self:UpdateRoundData(ToolData, Data)

			local Text	   = "Penetration : %s mm RHA\nAt 300m : %s mm RHA @ %s m/s\nAt 800m : %s mm RHA @ %s m/s"
			local MaxPen   = math.Round(Data.MaxPen, 2)
			local R1V, R1P = ACF.PenRanging(Data.MuzzleVel, Data.DragCoef, Data.ProjMass, Data.PenArea, Data.LimitVel, 300)
			local R2V, R2P = ACF.PenRanging(Data.MuzzleVel, Data.DragCoef, Data.ProjMass, Data.PenArea, Data.LimitVel, 800)

			R1P = math.Round((ACF_Kinetic((R1V + Data.SlugMV) * 39.37, Data.SlugMassUsed, 999999).Penetration / Data.SlugPenArea) * ACF.KEtoRHA, 2)
			R2P = math.Round((ACF_Kinetic((R2V + Data.SlugMV) * 39.37, Data.SlugMassUsed, 999999).Penetration / Data.SlugPenArea) * ACF.KEtoRHA, 2)

			return Text:format(MaxPen, R1P, R1V, R2P, R2V)
		end)

		Menu:AddLabel("Note: The penetration range data is an approximation and may not be entirely accurate.")
	end
end