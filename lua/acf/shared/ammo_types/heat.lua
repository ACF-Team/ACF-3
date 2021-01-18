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
	return (HEATFillerMass * 0.5 * ACF.HEPower * math.sin(math.rad(10 + Data.ConeAng) * 0.5) / Data.SlugMass) ^ ACF.HEATMVScale
end

function Ammo:GetDisplayData(Data)
	local Crushed, HEATFiller, BoomFiller = self:CrushCalc(Data.MuzzleVel, Data.FillerMass)
	local SlugMV	= self:CalcSlugMV(Data, HEATFiller) * (Data.SlugPenMul or 1)
	local MassUsed	= Data.SlugMass * (1 - Crushed)
	local Energy	= ACF_Kinetic(SlugMV * 39.37, MassUsed, 999999)
	local FragMass	= Data.CasingMass + Data.SlugMass * Crushed
	local Fragments	= math.max(math.floor((BoomFiller / FragMass) * ACF.HEFrag), 2)
	local Display   = {
		Crushed        = Crushed,
		HEATFillerMass = HEATFiller,
		BoomFillerMass = BoomFiller,
		SlugMV         = SlugMV,
		SlugMassUsed   = MassUsed,
		MaxPen         = (Energy.Penetration / Data.SlugPenArea) * ACF.KEtoRHA,
		TotalFragMass  = FragMass,
		BlastRadius    = BoomFiller ^ 0.33 * 8,
		Fragments      = Fragments,
		FragMass       = FragMass / Fragments,
		FragVel        = (BoomFiller * ACF.HEPower * 1000 / FragMass) ^ 0.5,
	}

	hook.Run("ACF_GetDisplayData", self, Data, Display)

	return Display
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
	Data.PenArea		= Data.FrArea ^ ACF.PenAreaMod
	Data.LimitVel		= 100 -- Most efficient penetration speed in m/s
	Data.KETransfert	= 0.1 -- Kinetic energy transfert to the target for movement purposes
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
		Entity:SetNW2Float("FillerMass", BulletData.FillerMass)
	end

	function Ammo:GetCrateText(BulletData)
		local Text = "Muzzle Velocity: %s m/s\nMax Penetration: %s mm\nBlast Radius: %s m\n", "Blast Energy: %s KJ"
		local Data = self:GetDisplayData(BulletData)

		return Text:format(math.Round(BulletData.MuzzleVel, 2), math.Round(Data.MaxPen, 2), math.Round(Data.BlastRadius, 2), math.Round(Data.BoomFillerMass * ACF.HEPower, 2))
	end

	function Ammo:Detonate(Bullet, HitPos)
		local Crushed, HEATFillerMass, BoomFillerMass = self:CrushCalc(Bullet.Flight:Length() * 0.0254, Bullet.FillerMass)

		ACF_HE(HitPos, BoomFillerMass, Bullet.CasingMass + Bullet.SlugMass * Crushed, Bullet.Owner, Bullet.Filter, Bullet.Gun)

		if Crushed == 1 then return false end -- no HEAT jet to fire off, it was all converted to HE

		local SlugMV = self:CalcSlugMV(Bullet, HEATFillerMass) * 39.37 * (Bullet.SlugPenMul or 1)

		Bullet.Detonated = true
		Bullet.Flight    = Bullet.Flight:GetNormalized() * SlugMV
		Bullet.NextPos   = HitPos
		Bullet.DragCoef  = Bullet.SlugDragCoef
		Bullet.ProjMass  = Bullet.SlugMass * (1 - Crushed)
		Bullet.Caliber   = Bullet.SlugCaliber
		Bullet.PenArea   = Bullet.SlugPenArea
		Bullet.Ricochet  = Bullet.SlugRicochet
		Bullet.LimitVel  = 999999

		return true
	end

	function Ammo:PropImpact(Bullet, Trace)
		local Target = Trace.Entity

		if ACF.Check(Target) then
			local Speed = Bullet.Flight:Length() / ACF.Scale
			local HitPos = Trace.HitPos
			local HitNormal = Trace.HitNormal
			local Bone = Trace.HitGroup

			-- TODO: Figure out why bullets are missing 10% of their penetration
			if Bullet.Detonated then
				local Multiplier = Bullet.NotFirstPen and ACF.HEATPenLayerMul or 1
				local Energy     = ACF_Kinetic(Speed, Bullet.ProjMass, Bullet.LimitVel)
				local HitRes     = ACF_RoundImpact(Bullet, Speed, Energy, Target, HitPos, HitNormal, Bone)

				Bullet.NotFirstPen = true

				if HitRes.Overkill > 0 then
					table.insert(Bullet.Filter, Target) --"Penetrate" (Ingoring the prop for the retry trace)

					Bullet.Flight = Bullet.Flight:GetNormalized() * math.sqrt(Energy.Kinetic * (1 - HitRes.Loss) * Multiplier * 2000 / Bullet.ProjMass) * 39.37

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

		local Function = IsValid(Trace.Entity) and ACF_PenetrateMapEntity or ACF_PenetrateGround

		return Function(Bullet, Trace)
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

		local FillerMass = Base:AddSlider("Filler Volume", 0, BulletData.MaxFillerVol, 2)
		FillerMass:SetClientData("FillerMass", "OnValueChanged")
		FillerMass:TrackClientData("Projectile")
		FillerMass:TrackClientData("LinerAngle")
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
		Trackers.LinerAngle = true
	end

	function Ammo:AddAmmoInformation(Base, ToolData, BulletData)
		local RoundStats = Base:AddLabel()
		RoundStats:TrackClientData("Projectile", "SetText")
		RoundStats:TrackClientData("Propellant")
		RoundStats:TrackClientData("FillerMass")
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
		FillerStats:TrackClientData("FillerMass", "SetText")
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
		Penetrator:TrackClientData("FillerMass")
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
		PenStats:TrackClientData("FillerMass")
		PenStats:TrackClientData("LinerAngle")
		PenStats:DefineSetter(function()
			self:UpdateRoundData(ToolData, BulletData)

			local Text	 = "Penetration : %s mm RHA\nAt 300m : %s mm RHA @ %s m/s\nAt 800m : %s mm RHA @ %s m/s"
			local MaxPen = math.Round(BulletData.MaxPen, 2)
			local R1V    = ACF.PenRanging(BulletData.MuzzleVel, BulletData.DragCoef, BulletData.ProjMass, BulletData.PenArea, BulletData.LimitVel, 300)
			local R2V    = ACF.PenRanging(BulletData.MuzzleVel, BulletData.DragCoef, BulletData.ProjMass, BulletData.PenArea, BulletData.LimitVel, 800)

			return Text:format(MaxPen, MaxPen, R1V, MaxPen, R2V)
		end)

		Base:AddLabel("Note: The penetration range data is an approximation and may not be entirely accurate.")
	end
end