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

	local AngleMult  = (15 + ConeAngle) / 15 -- Shallower cones need thicker liners to survive being made into EFPs
	local LinerThick = ACF.LinerThicknessMult * Radius * AngleMult + 0.2
	local LinerVol   = ConeArea * LinerThick
	local LinerMass  = LinerVol * ACF.CopperDensity
	print(LinerThick)

	return LinerMass, ConeVol, Height
end

function Ammo:GetPenetration(Bullet, Standoff)
	if not isnumber(Standoff) then
		return 1 -- Does not matter, just so calls to damage functions don't go sneedmode
	end

	local BreakupT      = Bullet.BreakupTime
	local MaxVel        = Bullet.JetMaxVel
	local PenMul        = Bullet.PenMul or 1
	local TargetDensity = ACF.RHADensity -- Assuming RHA
	local Gamma         = math.sqrt(TargetDensity / ACF.CopperDensity)

	local Penetration = 0
	if Standoff < Bullet.BreakupDist then
		local JetTravel = BreakupT * MaxVel
		local K1 = 1 + Gamma
		local K2 = 1 / K1
		Penetration = (K1 * (JetTravel * Standoff) ^ K2 - math.sqrt(K1 * ACF.HEATMinPenVel * BreakupT * JetTravel ^ K2 * Standoff ^ (Gamma * K2))) / Gamma - Standoff
	else
		Penetration = (MaxVel * BreakupT - math.sqrt(ACF.HEATMinPenVel * BreakupT * (MaxVel * BreakupT + Gamma * Standoff))) / Gamma
	end

	return math.max(Penetration * ACF.HEATPenMul * PenMul * 1e3, 0) -- m to mm
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

function ACF_HEATRecalcBullet(Data)

end

function Ammo:UpdateRoundData(ToolData, Data, GUIData)
	GUIData = GUIData or Data

	ACF.UpdateRoundSpecs(ToolData, Data, GUIData)

	local CapLength       = GUIData.MinProjLength * 0.5
	local BodyLength      = Data.ProjLength - CapLength
	local FreeVol, FreeLength, FreeRadius = ACF.RoundShellCapacity(Data.PropMass, Data.ProjArea, Data.Caliber, BodyLength)
	-- Considering most of the cap gets crushed (early HEAT suffered from this)
	local Standoff        = (0.3 * CapLength + FreeLength * ToolData.StandoffRatio) * 1e-2 -- cm to m
	local WarheadVol      = FreeVol * (1 - ToolData.StandoffRatio)
	local WarheadLength   = FreeLength * (1 - ToolData.StandoffRatio)
	local WarheadDiameter = 2 * FreeRadius
	local MinConeAng      = math.deg(math.atan(FreeRadius / WarheadLength))
	local LinerAngle      = math.Clamp(ToolData.LinerAngle, MinConeAng, 90) -- Cone angle is angle between cone walls, not between a wall and the center line
	local LinerMass, ConeVol, ConeLength = self:ConeCalc(LinerAngle, FreeRadius)

	-- Charge length increases jet velocity, but with diminishing returns. All explosive sorrounding the cone has 100% effectiveness,
	--  but the explosive behind it sees it reduced. Most papers put the maximum useful head length (explosive length behind the
	--  cone) at around 1.5-1.8 times the charge's diameter. Past that, adding more explosive won't do much.
	local RearFillLen  = WarheadLength - ConeLength  -- Length of explosive behind the liner
	local Exponential  = math.exp(2 * RearFillLen / (WarheadDiameter * ACF.MaxChargeHeadLen))
	local EquivFillLen = WarheadDiameter * ACF.MaxChargeHeadLen * ((Exponential - 1) / (Exponential + 1)) -- Equivalent length of explosive
	local FrontFillVol = WarheadVol * ConeLength / WarheadLength - ConeVol -- Volume of explosive sorounding the liner
	local RearFillVol  = WarheadVol * RearFillLen / WarheadLength -- Volume behind the liner
	local EquivFillVol = WarheadVol * EquivFillLen / WarheadLength + FrontFillVol -- Equivalent total explosive volume
	local LengthPct    = Data.ProjLength / (Data.MaxProjLength or Data.ProjLength * 2)
	local OverEnergy   = math.min(math.Remap(LengthPct, 0.6, 1, 1, 0.3), 1) -- Excess explosive power makes the jet lose velocity
	local FillerEnergy = OverEnergy * EquivFillVol * ACF.CompBDensity * 1e3 * ACF.TNTPower * ACF.CompBEquivalent * ACF.HEATEfficiency
	local FillerVol    = FrontFillVol + RearFillVol
	local FillerMass   = FillerVol * ACF.CompBDensity

	-- At lower cone angles, the explosive crushes the cone inward, expelling a jet. The steeper the cone, the faster the jet, but the less mass expelled
	local MinVelMult = (0.99 - 0.6) * LinerAngle / 90 + 0.6
	local JetMass    = LinerMass * ((1 - 0.25) * LinerAngle / 90  + 0.25)
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

	-- Recalculate the standoff for missiles
	if Data.MissileStandoff then
		Data.Standoff = (FreeLength * ToolData.StandoffRatio + Data.MissileStandoff) * 1e-2
	end

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

	local SpallingSin = math.sqrt(1 - ACF.HEATSpallingArc * ACF.HEATSpallingArc)
	function Ammo:Detonate(Bullet, HitPos)
		-- Apply HE damage
		ACF.HE(HitPos, Bullet.BoomFillerMass, Bullet.CasingMass, Bullet.Owner, Bullet.Filter, Bullet.Gun)
		self:HEATExplosionEffect(Bullet, HitPos)

		-- Find ACF entities in the range of the damage (or simplify to like 6m)
		local FoundEnts = ents.FindInSphere(HitPos, 250)
		local Squishies = {}
		for _, v in ipairs(FoundEnts) do
			local Class = v:GetClass()

			-- Blacklist armor and props, the most common entities
			if Class ~= "acf_armor" and Class ~= "prop_physics" and (Class:find("^acf") or Class:find("^gmod_wire") or Class:find("^prop_vehicle") or v:IsPlayer()) then
				Squishies[#Squishies + 1] = v
			end
		end

		-- Move the jet start to the impact point and back it up by the passive standoff
		local Direction = Bullet.Flight:GetNormalized()
		local JetStart  = HitPos - Direction * Bullet.Standoff * 39.37
		local JetEnd    = HitPos + Direction * 3000
		local Caliber   = Bullet.Diameter * 10

		local TraceData = {start = JetStart, endpos = JetEnd, filter = {}, mask = Bullet.Mask}
		local Penetrations = 0
		local JetMassPct   = 1
		-- Main jet penetrations
		while Penetrations < 20 do
			local TraceRes  = ACF.Trace(TraceData)
			local PenHitPos = TraceRes.HitPos
			local Ent       = TraceRes.Entity
			debugoverlay.Line(JetStart, PenHitPos, 15, ColorRand(100, 255))

			-- Get the (full jet's) penetration
			local Standoff    = (PenHitPos - JetStart):Length() * 0.0254 -- Back to m
			local Penetration = self:GetPenetration(Bullet, Standoff)
			-- If it's out of range, stop here
			if Penetration == 0 then break end

			-- Get the effective armor thickness
			local BaseArmor = 0
			local Damage    = nil
			if TraceRes.HitWorld then
				-- Get the surface and calculate the RHA equivalent
				local Surface = util.GetSurfaceData(TraceRes.SurfaceProps)
				local Density = ((Surface and Surface.density * 0.5 or 500) * math.Rand(0.9, 1.1)) ^ 0.9 / 10000
				local Penetrated, Exit = ACF_DigTrace(PenHitPos + Direction, PenHitPos + Direction * math.max(Penetration / Density, 1) / 25.4)
				-- Base armor is the RHAe if penetrated, or simply more than the penetration so the jet loses all mass and penetration stops
				BaseArmor = Penetrated and ((Exit - PenHitPos):Length() * Density * 25.4) or (Penetration + 1)
				-- Update the starting position of the trace because world is not filterable
				TraceData.start = Exit
			elseif Ent:CPPIGetOwner() == game.GetWorld() then
				-- TODO: Fix world entity penetration
				BaseArmor = Penetration + 1
			elseif TraceRes.Hit then
				BaseArmor = Ent.GetArmor and Ent:GetArmor(TraceRes) or Ent.ACF.Armour
				-- Enable damage if a valid entity is hit
				Damage = 0
			end
			local SlopeFactor    = BaseArmor / Caliber
			local Angle          = math.Clamp(ACF_GetHitAngle(TraceRes.HitNormal, Direction), -90, 90)
			local EffectiveArmor = Ent.GetArmor and BaseArmor or BaseArmor / math.abs(math.cos(math.rad(Angle)) ^ SlopeFactor)

			-- Percentage of total jet mass lost to this penetration
			local LostMassPct = EffectiveArmor / Penetration
			-- Deal damage based on the volume of the lost mass
			local Cavity = ACF.HEATCavityMul * LostMassPct * Bullet.JetMass / ACF.CopperDensity -- in cm^3
			if Damage == 0 then
				ACF_VolumeDamage(Bullet, TraceRes, Cavity)
			end
			-- Reduce the jet mass by the lost mass
			JetMassPct = JetMassPct - LostMassPct

			print("\nPenetration " .. Penetrations + 1)
			print("Hit entity:          " .. TraceRes.Entity:GetClass())
			print("Effective armor:     " .. EffectiveArmor)
			print("Standoff:            " .. Standoff)
			print("Penetration at dist: " .. Penetration)
			print("Lost mass pct:       " .. LostMassPct)
			print("Remaining mass pct:  " .. JetMassPct)
			print("Cavity:              " .. Cavity)
			-- If no mass is left (jet penetration stopped) stop here
			if JetMassPct < 0 then break end

			self:PenetrationEffect(Bullet, PenHitPos, Cavity)

			-- If the target is explosive and the armor is penetrated, detonate
			if Ent.Detonate then
				Ent.Damaged = true
				Ent:Detonate()
			end

			-- Filter the hit entity
			if TraceRes.Entity then TraceData.filter[#TraceData.filter + 1] = TraceRes.Entity end

			-- Determine how much damage the squishies will take
			local Damageables = {}
			local AreaSum     = 0
			local AvgDist     = 0
			for _, v in ipairs(Squishies) do
				local TargetPos = v:GetPos()
				local DotProd   = (TargetPos - PenHitPos):GetNormalized():Dot(Direction)
				-- If within the arc of spalling
				if DotProd > 0 then
					-- Run a trace to determine if the target is occluded
					local TargetTrace = {start = PenHitPos, endpos = TargetPos, filter = TraceData.filter, mask = Bullet.Mask}
					local TargetRes   = ACF.Trace(TargetTrace)
					local SpallEnt    = TargetRes.Entity
					-- If the trace hits something, deal damage to it (doesn't matter if it's not the squishy we wanted)
					if TraceRes.HitNonWorld and ACF.Check(SpallEnt) then
						debugoverlay.Line(PenHitPos, TargetPos, 15, ColorRand(100, 255))

						local DistSqr = (TargetRes.HitPos - PenHitPos):LengthSqr()
						-- Calculate how much shrapnel will hit the target based on it's relative area
						-- Divided by the distance because far away things seem smaller, mult'd by the dot product because
						--  spalling is concentrated around the main jet, and divided by 6 because (simplifying the target
						--  as a cube, good enough) one of the 6 faces is visible
						local Area    = 0
						if ACF.Check(SpallEnt) then Area = SpallEnt.ACF.Area else continue end
						local RelArea = (DotProd ^ 3) * Area / (DistSqr * 6)
						AreaSum = AreaSum + RelArea
						AvgDist = AvgDist + math.sqrt(DistSqr)
						Damageables[#Damageables + 1] = {SpallEnt, RelArea}
					end
				end
			end
			AvgDist = AvgDist / #Damageables

			local Radius  = AvgDist * SpallingSin
			-- Minimum area is the base of the spalling cone, with the distance being the average squishy distance
			-- Divided by the average distance squared so it's the same as the relative area
			local MinArea = Radius * Radius * math.pi / (AvgDist * AvgDist)
			AreaSum = math.max(AreaSum, MinArea)
			-- The only information used from the trace is the entity, so we can use a fake TraceRes with placeholder information,
			--  which the damage function checks but doesn't use. Scuffed, but alas - rework damage
			local FakeTrace = {HitNormal = Vector(1,0,0), StartPos = Vector(1,0,0), HitPos = Vector(0,0,0), EndPos = Vector(0,0,0)}
			for _, v in ipairs(Damageables) do
				FakeTrace.Entity  = v[1]
				-- Damage is proportional to how much relative surface area the target occupies from the jet's POV
				local SpallDamage = Cavity * v[2] / AreaSum
				ACF_VolumeDamage(Bullet, FakeTrace, SpallDamage)
			end

			Penetrations = Penetrations + 1
		end
	end

	local function OnRicochet(Bullet, Trace, Ricochet)
		if Ricochet > 0 and Bullet.Ricochets < 3 then
			Bullet.Ricochets = Bullet.Ricochets + 1
			Bullet.NextPos = Trace.HitPos
			Bullet.Flight = (ACF_RicochetVector(Bullet.Flight, Trace.HitNormal) + VectorRand() * 0.025):GetNormalized() * Bullet.Flight:Length() * Ricochet
		end
	end

	function Ammo:PropImpact(Bullet, Trace)
		local Target = Trace.Entity

		if ACF.Check(Target) then
			local Ricochet, _ = ACF_CalcRicochet(Bullet, Trace)

			if Ricochet ~= 0 then
				OnRicochet(Bullet, Trace, Ricochet)
				return "Ricochet"
			else
				self:Detonate(Bullet, Trace.HitPos)
				return false
			end
		else
			table.insert(Bullet.Filter, Target)

			return "Penetrated"
		end
	end

	function Ammo:WorldImpact()
		return false
	end


	function Ammo:PenetrationEffect(Bullet, Pos, Cavity)
		local Data = EffectData()
		Data:SetOrigin(Pos)
		Data:SetNormal(Bullet.Flight:GetNormalized())
		Data:SetScale(Bullet.JetMaxVel * 3)
		Data:SetMagnitude(Cavity)
		Data:SetRadius(Bullet.Caliber)
		--Data:SetDamageType(DecalIndex(Bullet.AmmoType))

		util.Effect("ACF_Penetration", Data)
	end

	function Ammo:HEATExplosionEffect(Bullet, Pos)
		local Data = EffectData()
		Data:SetOrigin(Pos)
		Data:SetNormal(Bullet.Flight:GetNormalized())
		Data:SetRadius(math.max(Bullet.FillerMass ^ 0.33 * 8 * 39.37, 1))

		util.Effect("ACF_HEAT_Explosion", Data)
	end

else
	ACF.RegisterAmmoDecal("HEAT", "damage/heat_pen", "damage/heat_rico", function(Caliber) return Caliber * 0.1667 end)

	local DecalIndex = ACF.GetAmmoDecalIndex

	function Ammo:ImpactEffect()
		return
		--[[
			if not Bullet.Detonated then
				self:PenetrationEffect(Effect, Bullet)
			end

			Ammo.BaseClass.ImpactEffect(self, Effect, Bullet)
		--]]
	end

	function Ammo:PenetrationEffect()
		return
		--[[
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
		--]]
	end

	function Ammo:RicochetEffect(_, Bullet)
		local Effect = EffectData()
		Effect:SetOrigin(Bullet.SimPos)
		Effect:SetNormal(Bullet.SimFlight:GetNormalized())
		Effect:SetScale(Bullet.SimFlight:Length())
		Effect:SetMagnitude(Bullet.RoundMass)
		Effect:SetRadius(Bullet.Caliber)
		Effect:SetDamageType(DecalIndex(Bullet.AmmoType))

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

		-- Capped the max standoff at 0.4 for historical reasons
		local StandoffRatio = Base:AddSlider("Extra Standoff Ratio", 0, 0.2, 2)
		StandoffRatio:SetClientData("StandoffRatio", "OnValueChanged")
		StandoffRatio:DefineSetter(function(_, _, _, Value)
			ToolData.StandoffRatio = math.Round(Value, 2)

			self:UpdateRoundData(ToolData, BulletData)

			return ToolData.StandoffRatio
		end)
	end

	function Ammo:AddCrateDataTrackers(Trackers, ...)
		Ammo.BaseClass.AddCrateDataTrackers(self, Trackers, ...)

		Trackers.LinerAngle = true
		Trackers.StandoffRatio = true
	end

	function Ammo:AddAmmoInformation(Base, ToolData, BulletData)
		local RoundStats = Base:AddLabel()
		RoundStats:TrackClientData("Projectile", "SetText")
		RoundStats:TrackClientData("Propellant")
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

		local Penetrator = Base:AddLabel()
		Penetrator:TrackClientData("Projectile", "SetText")
		Penetrator:TrackClientData("Propellant")
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

		local PenStats = Base:AddLabel()
		PenStats:TrackClientData("Projectile", "SetText")
		PenStats:TrackClientData("Propellant")
		PenStats:TrackClientData("LinerAngle")
		PenStats:TrackClientData("StandoffRatio")
		PenStats:DefineSetter(function()
			self:UpdateRoundData(ToolData, BulletData)

			local Text   = "Penetration at passive standoff :\nAt %s mm : %s mm RHA\nMaximum penetration :\nAt %s mm : %s mm RHA"
			local Standoff1 = math.Round(BulletData.Standoff * 1e3, 0)
			local Pen1 = math.Round(self:GetPenetration(BulletData, BulletData.Standoff), 1)
			local Standoff2 = math.Round(BulletData.BreakupDist * 1e3, 0)
			local Pen2 = math.Round(self:GetPenetration(BulletData, BulletData.BreakupDist), 1)

			return Text:format(Standoff1, Pen1, Standoff2, Pen2)
		end)
	end
end