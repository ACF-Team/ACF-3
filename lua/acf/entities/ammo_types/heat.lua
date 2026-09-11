local ACF       = ACF
local Classes   = ACF.Classes
local Damage    = ACF.Damage
local Debug		= ACF.Debug
local Clock 	= ACF.Utilities.Clock

Classes.DefineClass("ACF.Ammunition.HEAT", "ACF.Ammunition.AP", function(CLASS, BASE)
	CLASS.Name		 = "High Explosive Anti-Tank"
	CLASS.SpawnIcon   = "acf/icons/shell_heat.png"
	CLASS.Bodygroup   = 8 -- HEAT bodygroup index
	CLASS.MortarBodygroup = 3 -- HEAT mortar submodel
	CLASS.Description = "#acf.descs.ammo.heat"
	CLASS.IsChemical  = true
	CLASS.Blacklist = {
		["ACF.Guns.Autocannon"] = true,
		["ACF.Guns.Machinegun"] = true,
		["ACF.Guns.SmokeLauncher"] = true,
		["ACF.Guns.LightAutocannon"] = true,
		["ACF.Guns.RotaryAutocannon"] = true,
	}

	MENU_FIELD("Number", "LinerAngleRatio", {Default = 1})
	MENU_FIELD("Number", "StandoffRatio", {Default = 0})

	function CLASS:ConeCalc(ConeAngle, Radius)
		local Height     = Radius / math.tan(math.rad(ConeAngle))
		local ConeArea   = math.pi * Radius * math.sqrt(Height ^ 2 + Radius ^ 2)
		local ConeVol    = (math.pi * Radius ^ 2 * Height) / 3

		local AngleMult  = math.Remap(ConeAngle ^ 4, 0, 90 ^ 4, 1, 5) -- Shallower cones need thicker liners to survive being made into EFPs
		local LinerThick = ACF.LinerThicknessMult * Radius * AngleMult + 0.1
		local LinerVol   = ConeArea * LinerThick
		local LinerMass  = LinerVol * ACF.CopperDensity

		return LinerMass, ConeVol, Height
	end

	function CLASS:GetPenetration(Bullet, Standoff)
		if not isnumber(Standoff) then
			return 1 -- Does not matter, just so calls to damage functions don't go sneedmode
		end

		local BreakupT      = Bullet.BreakupTime
		local MaxVel        = Bullet.JetMaxVel
		local PenMul        = Bullet.PenMul or 1
		local Gamma         = 1 --math.sqrt(TargetDensity / ACF.CopperDensity) (Set to 1 to maintain continuity)

		local Penetration = 0
		if Standoff < Bullet.BreakupDist then
			local JetTravel = BreakupT * MaxVel
			local K1 = 1 + Gamma
			local K2 = 1 / K1
			Penetration = (K1 * (JetTravel * Standoff) ^ K2 - math.sqrt(K1 * ACF.HEATMinPenVel * BreakupT * JetTravel ^ K2 * Standoff ^ (Gamma * K2))) / Gamma - Standoff
		else
			Penetration = (MaxVel * BreakupT - math.sqrt(ACF.HEATMinPenVel * BreakupT * (MaxVel * BreakupT + Gamma * Standoff))) / Gamma
		end

		local Ret = math.max(Penetration * ACF.HEATPenMul * PenMul * 1e3, 0) -- m to mm
		return Ret
	end

	function CLASS:GetDisplayData(Data)
		local FragInfo   = ACF.Damage.getFragmentInfo(Data.BoomFillerMass, Data.CasingMass) -- Single source of truth shared with the damage code
		local Display    = {
			BoomFillerMass = Data.BoomFillerMass,
			MaxPen         = self:GetPenetration(Data, Data.Standoff, ACF.SteelDensity),
			TotalFragMass  = Data.CasingMass,
			BlastRadius    = Data.BoomFillerMass ^ 0.33 * 8,
			Fragments      = FragInfo.Count,
			FragMass       = FragInfo.Mass,
			FragVel        = FragInfo.Velocity * ACF.InchToMeter, -- in/s (sim units) to m/s for display
		}

		hook.Run("ACF_OnRequestDisplayData", self, Data, Display)

		return Display
	end

	function CLASS:UpdateRoundData()
		local Data    = self.BulletData
		local GUIData = self.GUIData

		ACF.UpdateRoundSpecs(self)

		local CapLength       = GUIData.MinProjLength * 0.5
		local BodyLength      = Data.ProjLength - CapLength
		local FreeVol, FreeLength, FreeRadius = ACF.RoundShellCapacity(Data.PropMass, Data.ProjArea, Data.Caliber, BodyLength)
		-- Considering most of the cap gets crushed (early HEAT suffered from this)
		local Standoff        = (0.3 * CapLength + FreeLength * self.StandoffRatio) * 1e-2 * ACF.HEATStandOffMul -- cm to m
		local WarheadVol      = FreeVol * (1 - self.StandoffRatio)
		local WarheadLength   = FreeLength * (1 - self.StandoffRatio)
		local WarheadDiameter = 2 * FreeRadius
		local MinConeAng      = math.deg(math.atan(FreeRadius / WarheadLength))

		-- Migrates rounds saved with an absolute LinerAngle in degrees. Needs MinConeAng, so it can
		-- only run here rather than in VerifyData. Runs once, LinerAngle is cleared right after.
		if not isnumber(self.LinerAngleRatio) then
			if isnumber(self.LinerAngle) then
				self.LinerAngleRatio = math.Remap(math.Clamp(self.LinerAngle, MinConeAng, 90), MinConeAng, 90, 0, 1)
				self.LinerAngle = nil
			else
				self.LinerAngleRatio = 1
			end
		end

		local LinerAngleRatio = math.Clamp(self.LinerAngleRatio, 0, 1)
		local LinerAngle      = math.Remap(LinerAngleRatio, 0, 1, MinConeAng, 90) -- Cone angle is angle between cone walls, not between a wall and the center line
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
		local LengthPct    = math.min(Data.ProjLength / (Data.Caliber * 7.8), 1)
		local OverEnergy   = math.min(math.Remap(LengthPct, 0.4, 1, 1, 0.2), 1) -- Excess explosive power makes the jet lose velocity
		local FillerEnergy = OverEnergy * EquivFillVol * ACF.CompBDensity * 1e3 * ACF.TNTPower * ACF.CompBEquivalent * ACF.HEATEfficiency
		local FillerVol    = FrontFillVol + RearFillVol
		local FillerMass   = FillerVol * ACF.CompBDensity

		-- At lower cone angles, the explosive crushes the cone inward, expelling a jet. The steeper the cone, the faster the jet, but the less mass expelled
		local MinVelMult = math.Remap(LinerAngle, 0, 90, 0.5, 0.99)
		local JetMass    = LinerMass * math.Remap(LinerAngle, 0, 90, 0.25, 1)
		local JetAvgVel  = (2 * FillerEnergy / JetMass) ^ 0.5  -- Average velocity of the copper jet
		local JetMinVel  = JetAvgVel * MinVelMult              -- Minimum velocity of the jet (the rear)
		-- Calculates the maximum velocity, considering the velocity distribution is linear from the rear to the tip (integrated this by hand, pain :) )
		local JetMaxVel  = 0.5 * (3 ^ 0.5 * (8 * FillerEnergy - JetMass * JetMinVel ^ 2) ^ 0.5 / JetMass ^ 0.5 - JetMinVel) -- Maximum velocity of the jet (the tip)

		-- Both the "magic numbers" are unitless, tuning constants that were used to fit the breakup time to real world values, I suggest they not be messed with
		local BreakupTime    = 1.6e-6 * (5e9 * JetMass / (JetMaxVel - JetMinVel)) ^ 0.3333 * ACF.HEATBreakUpMul -- Jet breakup time in seconds
		local BreakupDist    = JetMaxVel * BreakupTime

		GUIData.MinConeAng = MinConeAng

		Data.ConeAng         = LinerAngle
		Data.MinConeAng      = MinConeAng
		Data.LinerAngleRatio = LinerAngleRatio
		Data.FillerMass      = FillerMass
		local NonCasingVol  = ACF.RoundShellCapacity(Data.PropMass, Data.ProjArea, Data.Caliber, Data.ProjLength)
		Data.CasingMass		= (GUIData.ProjVolume - NonCasingVol) * ACF.SteelDensity
		Data.ProjMass       = Data.FillerMass + Data.CasingMass + LinerMass
		Data.MuzzleVel      = ACF.MuzzleVelocity(Data.PropMass, Data.ProjMass, Data.Efficiency)
		Data.BoomFillerMass	= Data.FillerMass * ACF.HEATBoomConvert * ACF.CompBEquivalent -- In TNT equivalent
		Data.LinerMass      = LinerMass
		Data.JetMass        = JetMass
		Data.JetMinVel      = JetMinVel
		Data.JetMaxVel      = JetMaxVel
		Data.JetAvgVel	  	= JetAvgVel
		Data.BreakupTime    = BreakupTime
		Data.Standoff       = Standoff
		Data.BreakupDist    = BreakupDist
		Data.DragCoef		= Data.ProjArea * 0.0001 / Data.ProjMass
		Data.CartMass		= Data.PropMass + Data.ProjMass

		hook.Run("ACF_OnUpdateRound", self, self, Data, GUIData)

		-- Recalculate the standoff for missiles
		if Data.MissileStandoff then
			Data.Standoff = (FreeLength * self.StandoffRatio + Data.MissileStandoff) * 1e-2 * ACF.HEATStandOffMul
		end
		-- God weeped when this spaghetto was written (for missile roundinject)
		if Data.FillerMul or Data.LinerMassMul then
			local LinerMassMul = Data.LinerMassMul or 1
			Data.LinerMass     = LinerMass * LinerMassMul
			local FillerMul    = Data.FillerMul or 1
			Data.FillerEnergy  = OverEnergy * EquivFillVol * ACF.CompBDensity * 1e3 * ACF.TNTPower * ACF.CompBEquivalent * ACF.HEATEfficiency * FillerMul
			local _FillerEnergy = Data.FillerEnergy
			local _LinerAngle   = Data.ConeAng
			local _MinVelMult   = math.Remap(_LinerAngle, 0, 90, 0.5, 0.99)
			local _JetMass      = LinerMass * math.Remap(_LinerAngle, 0, 90, 0.25, 1)
			local _JetAvgVel    = (2 * _FillerEnergy / _JetMass) ^ 0.5
			local _JetMinVel    = _JetAvgVel * _MinVelMult
			local _JetMaxVel    = 0.5 * (3 ^ 0.5 * (8 * _FillerEnergy - _JetMass * _JetMinVel ^ 2) ^ 0.5 / _JetMass ^ 0.5 - JetMinVel)
			Data.BreakupTime   = 1.6e-6 * (5e9 * _JetMass / (_JetMaxVel - _JetMinVel)) ^ 0.3333 * ACF.HEATBreakUpMul
			Data.BreakupDist   = _JetMaxVel * Data.BreakupTime
			Data.JetMass       = _JetMass
			Data.JetMinVel     = _JetMinVel
			Data.JetMaxVel     = _JetMaxVel
			Data.JetAvgVel	  	= _JetAvgVel
		end

		-- Jet's cross-sectional area (cm^2), same role as ProjArea for a kinetic round.
		Data.JetArea = (Data.JetMass / ACF.CopperDensity) / (Data.BreakupDist * 100)

		for K, V in pairs(self:GetDisplayData(Data)) do
			GUIData[K] = V
		end
	end

	function CLASS:BaseConvert()
		self.BulletData = {}

		local Data = ACF.RoundBaseGunpowder(self)

		self.GUIData.MinConeAng	 = 0
		self.GUIData.MinFillerVol = 0

		Data.ShovePower		= 0.1
		Data.LimitVel		= 100 -- Most efficient penetration speed in m/s
		Data.Ricochet		= 60 -- Base ricochet angle
		Data.DetonatorAngle	= 75
		Data.CanFuze		= Data.Caliber * 10 >= ACF.MinFuzeCaliber -- Can fuze on calibers >= 25mm

		self:UpdateRoundData()

		return self.BulletData, self.GUIData
	end

	function CLASS:VerifyData()
		BASE.VerifyData(self)

		if not isnumber(self.StandoffRatio) then
			self.StandoffRatio = 0
		else
			self.StandoffRatio = math.Clamp(self.StandoffRatio, 0, self.MaxStandoffRatio or 0.2)
		end
	end

	-- Shared with the client so the spawn menu can price a crate without spawning it.
	local Conversion = ACF.PointConversion

	function CLASS:GetCost(BulletData)
		return (BulletData.CasingMass * Conversion.Steel) + (BulletData.PropMass * Conversion.Propellant) + (BulletData.FillerMass * Conversion.CompB) + (BulletData.LinerMass * Conversion.Copper)
	end

	if SERVER then
		local Ballistics = ACF.Ballistics
		local Objects    = Damage.Objects



		function CLASS:OnLast(Entity)
			BASE.OnLast(self, Entity)

			Entity.LinerAngleRatio = nil

			-- Cleanup the leftovers aswell
			Entity.FillerMass = nil
			Entity.RoundData5 = nil
			Entity.RoundData6 = nil

			Entity:SetNW2Float("FillerMass", 0)
		end

		function CLASS:Network(Entity, BulletData)
			BASE.Network(self, Entity, BulletData)

			Entity:SetNW2String("AmmoType", "ACF.Ammunition.HEAT")
			Entity:SetNW2Float("FillerMass", BulletData.BoomFillerMass)
		end

		function CLASS:UpdateCrateOverlay(BulletData, State)
			local Data = self:GetDisplayData(BulletData)
			State:AddNumber("Muzzle Velocity", BulletData.MuzzleVel, " m/s")
			State:AddNumber("Max Penetration", Data.MaxPen, " mm")
			State:AddNumber("Blast Radius", Data.BlastRadius, " m")
			State:AddNumber("Blast Energy", BulletData.FillerMass * ACF.HEPower, " kJ")
		end

		function CLASS:Detonate(Bullet, HitPos)
			if Bullet.Detonated then return end	-- Prevents GLATGM spawned HEAT projectiles from detonating twice, or for that matter this running twice at all
			Bullet.Detonated = true

			local Filler    = Bullet.BoomFillerMass
			local Fragments = Bullet.CasingMass
			local DmgInfo   = Objects.DamageInfo(Bullet.Owner, Bullet.Gun)

			Bullet.KillTime = Clock.CurTime
			Damage.createExplosion(HitPos, Filler, Fragments, nil, DmgInfo)

			-- Move the jet start to the impact point and back it up by the passive standoff
			local Start		= Bullet.Standoff * ACF.MeterToInch
			local End		= Bullet.BreakupDist * 10 * ACF.MeterToInch
			local Direction = Bullet.Flight:GetNormalized()
			local JetStart  = HitPos - Direction * Start
			local JetEnd    = HitPos + Direction * End

			Debug.Cross(JetStart, 15, 15, Color(0, 255, 0), true)
			Debug.Cross(JetEnd, 15, 15, Color(255, 0, 0), true)

			local TraceData = {start = JetStart, endpos = JetEnd, filter = {}, mask = Bullet.Mask}
			local Penetrations = 0
			local JetMassPct   = 1

			Bullet.DamageArea = Bullet.JetArea -- Everything past this point is bored by the jet, not by the shell
			-- Main jet penetrations
			while Penetrations < 20 do
				local TraceRes  = ACF.trace(TraceData)
				local PenHitPos = TraceRes.HitPos
				local Ent       = TraceRes.Entity

				if TraceRes.Fraction == 1 and not IsValid(Ent) then break end

				Debug.Line(JetStart, PenHitPos, 15, ColorRand(100, 255))

				if not Ballistics.TestFilter(Ent, Bullet) then TraceData.filter[#TraceData.filter + 1] = TraceRes.Entity continue end

				-- Get the (full jet's) penetration. Floor Standoff so a dead convex's still-solid collision, hit again at ~0 distance, can't zero out GetPenetration and abort the whole jet.
				local Standoff    = math.max((PenHitPos - JetStart):Length() * ACF.InchToMeter, 0.01)
				local Penetration = self:GetPenetration(Bullet, Standoff) * math.max(0, JetMassPct)
				-- If it's out of range, stop here
				if Penetration == 0 then break end

				-- Set to override Bullet:GetPenetration()
				Bullet.PenetrationOverride = Penetration

				-- Get the effective armor thickness
				local BaseArmor = 0
				local DamageDealt
				local ConvexHits
				if TraceRes.HitWorld or TraceRes.Entity and TraceRes.Entity:IsWorld() then
					-- Get the surface and calculate the RHA equivalent
					local Surface = util.GetSurfaceData(TraceRes.SurfaceProps)
					local Density = ((Surface and Surface.density * 0.5 or 500) * math.Rand(0.9, 1.1)) ^ 0.9 / 10000
					local Penetrated, Exit = Ballistics.DigTrace(PenHitPos + Direction, PenHitPos + Direction * math.max(Penetration / Density, 1) / ACF.InchToMm)
					-- Base armor is the RHAe if penetrated, or simply more than the penetration so the jet loses all mass and penetration stops
					BaseArmor = Penetrated and ((Exit - PenHitPos):Length() * Density * ACF.InchToMm) or (Penetration + 1)
					-- Update the starting position of the trace because world is not filterable
					TraceData.start = Exit
				--elseif Ent:CPPIGetOwner() == game.GetWorld() then
					-- TODO: Fix world entity penetration
					--BaseArmor = Penetration + 1
				elseif TraceRes.Hit then
					ConvexHits = ACF.GetConvexHits(Ent, PenHitPos, Direction)

					if #ConvexHits > 0 then
						BaseArmor = 0
						for _, Hit in ipairs(ConvexHits) do
							BaseArmor = BaseArmor + Hit.GeoThick * Hit.ArmorType.ChemicalMul
						end
					else
						BaseArmor = Ent.GetArmor and Ent:GetArmor(TraceRes) or 0
					end

					-- Enable damage if a valid entity is hit
					DamageDealt = 0
				end

				local Angle          = ACF.GetHitAngle(TraceRes, Direction)
				local EffectiveArmor
				if ConvexHits and #ConvexHits > 0 then
					EffectiveArmor = BaseArmor -- GeoThick already accounts for obliquity
				elseif Ent.GetArmor then
					EffectiveArmor = BaseArmor
				else
					EffectiveArmor = BaseArmor / math.abs(math.cos(math.rad(Angle)))
				end
				EffectiveArmor = math.max(EffectiveArmor, 0.01) -- Prevent divide by zero and nan armor

				-- Percentage of total jet mass lost to this penetration
				local LostMassPct =  EffectiveArmor / Penetration
				if DamageDealt == 0 then
					-- Each jet layer resolves its own convex chain above, so clear any stale entry convex from the original impact and let getBulletDamage re-derive it here.
					Bullet.ConvexHit = nil

					-- Damage result, Damage info. Computed the same way as a kinetic round.
					local JetDmg, JetInfo = Damage.getBulletDamage(Bullet, TraceRes)

					JetInfo:SetType(DMG_BULLET)

					local Speed = Bullet.JetAvgVel

					Bullet.Energy = {}
					Bullet.Energy.Kinetic = ACF.Kinetic(Speed, Bullet.JetMass * JetMassPct).Kinetic * 1000
					local JetResult = Damage.dealDamage(Ent, JetDmg, JetInfo)

					-- Only spall on layers the jet actually broke through with mass to spare.
					local Overpenetrated = LostMassPct < JetMassPct

					if (JetResult.Kill or Overpenetrated) and not Bullet.IsSpall and not Bullet.IsCookOff then
						Ballistics.DoSpall(Bullet, TraceRes, JetResult, Speed, JetInfo)
					end

					-- Detonate any explosive reactive armor the jet struck, same as a kinetic round does in DoRoundImpact
					Ballistics.DoReactiveArmor(Bullet, TraceRes, JetInfo)

					if JetResult.Kill then
						ACF.APKill(Ent, Direction, 0, JetInfo)
					end
				end
				-- Reduce the jet mass by the lost mass
				JetMassPct = JetMassPct - LostMassPct

				if JetMassPct < 0 then break end

				-- Filter the hit entity
				if TraceRes.Entity then TraceData.filter[#TraceData.filter + 1] = TraceRes.Entity end

				Penetrations = Penetrations + 1
			end
		end

		local function OnRicochet(Bullet, Trace, Ricochet)
			if Ricochet > 0 and Bullet.Ricochets < 3 then
				local Direction = Ballistics.GetRicochetVector(Bullet.Flight, Trace.HitNormal) + VectorRand() * 0.025

				Bullet.Ricochets = Bullet.Ricochets + 1
				Bullet.NextPos = Trace.HitPos
				Bullet.Flight = Direction:GetNormalized() * Bullet.Flight:Length() * Ricochet
			end
		end

		function CLASS:PropImpact(Bullet, Trace)
			local Target = Trace.Entity

			if ACF.Check(Target) then
				local Ricochet = Ballistics.CalculateRicochet(Bullet, Trace)

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

		function CLASS:WorldImpact(Bullet, Trace)
			local Ricochet = Ballistics.CalculateRicochet(Bullet, Trace)

			if Ricochet ~= 0 then
				OnRicochet(Bullet, Trace, Ricochet)
				return "Ricochet"
			else
				self:Detonate(Bullet, Trace.HitPos)
				return false
			end
		end

	else
		ACF.RegisterAmmoDecal("ACF.Ammunition.HEAT", "damage/heat_pen", "damage/heat_rico", function(Caliber) return Caliber * 0.1667 end)
		local DecalIndex = ACF.GetAmmoDecalIndex
		local Effects    = ACF.Utilities.Effects

		function CLASS:ImpactEffect(Effect, Bullet)
			if not Bullet.Detonated then
				self:PenetrationEffect(Effect, Bullet)
			end

			BASE.ImpactEffect(self, Effect, Bullet)
		end

		function CLASS:PenetrationEffect(Effect, Bullet)
			local Detonated   = Bullet.Detonated
			local EffectName  = Detonated and "ACF_Penetration" or "ACF_HEAT_Explosion"
			local Radius      = Detonated and Bullet.Caliber or math.max(Bullet.FillerMass ^ 0.33 * 8 * ACF.MeterToInch, 1)
			local EffectTable = {
				Origin = Bullet.SimPos,
				Normal = Bullet.SimFlight:GetNormalized(),
				Radius = Radius,
				Magnitude = Detonated and Bullet.RoundMass or nil,
				Scale = Detonated and Bullet.SimFlight:Length() or nil,
				DamageType = Detonated and DecalIndex(Bullet.AmmoType) or nil,
			}

			Effects.CreateEffect(EffectName, EffectTable)

			if not Detonated then
				Bullet.Detonated = true
				Bullet.LimitVel  = 999999

				Effect:SetModel("models/Gibs/wood_gib01e.mdl")
			end
		end

		function CLASS:RicochetEffect(_, Bullet)
			local EffectTable = {
				Origin = Bullet.SimPos,
				Normal = Bullet.SimFlight:GetNormalized(),
				Scale = Bullet.SimFlight:Length(),
				Magnitude = Bullet.RoundMass,
				Radius = Bullet.Caliber,
				DamageType = DecalIndex(Bullet.AmmoType),
			}

			Effects.CreateEffect("ACF_Ricochet", EffectTable)
		end

		function CLASS:OnCreateAmmoControls(Base)
			ACF.AmmoMenu.Slider(Base, "#acf.menu.ammo.liner_angle_ratio", 0, 1, 2, "LinerAngleRatio", function(Value)
				self.LinerAngleRatio = math.Round(Value, 2)
				self:UpdateRoundData()
			end)

			-- Capped the max standoff at 0.4 for historical reasons
			ACF.AmmoMenu.Slider(Base, "#acf.menu.ammo.standoff_ratio", 0, 0.2, 2, "StandoffRatio", function(Value)
				self.StandoffRatio = math.Round(Value, 2)
				self:UpdateRoundData()
			end)
		end

		function CLASS:OnCreateAmmoInformation(Base, _, BulletData)
			local RoundStats = Base:AddLabel()
			ACF.AmmoMenu.Reactive(RoundStats, function()
				self:UpdateRoundData()

				local Text		= language.GetPhrase("acf.menu.ammo.round_stats_he")
				local MuzzleVel	= math.Round(BulletData.MuzzleVel * ACF.Scale, 2)
				local ProjMass	= ACF.FormatMass(BulletData.ProjMass)
				local PropMass	= ACF.FormatMass(BulletData.PropMass)
				local Filler	= ACF.FormatMass(BulletData.FillerMass)

				RoundStats:SetText(Text:format(MuzzleVel, ProjMass, PropMass, Filler))
			end)

			local FillerStats = Base:AddLabel()
			ACF.AmmoMenu.Reactive(FillerStats, function()
				self:UpdateRoundData()

				local Text	   = language.GetPhrase("acf.menu.ammo.filler_stats_he")
				local Blast	   = math.Round(self.GUIData.BlastRadius, 2)
				local FragMass = ACF.FormatMass(self.GUIData.FragMass)
				local FragVel  = math.Round(self.GUIData.FragVel, 2)

				FillerStats:SetText(Text:format(Blast, self.GUIData.Fragments, FragMass, FragVel))
			end)

			local Penetrator = Base:AddLabel()
			ACF.AmmoMenu.Reactive(Penetrator, function()
				self:UpdateRoundData()

				local Text     = language.GetPhrase("acf.menu.ammo.penetrator_heat")
				local CuMass   = math.Round(BulletData.LinerMass * 1e3, 0)
				local JetMass  = math.Round(BulletData.JetMass * 1e3, 0)
				local MinVel   = math.Round(BulletData.JetMinVel, 0)
				local MaxVel   = math.Round(BulletData.JetMaxVel, 0)

				Penetrator:SetText(Text:format(CuMass, JetMass, MinVel, MaxVel))
			end)

			local PenStats = Base:AddLabel()
			ACF.AmmoMenu.Reactive(PenStats, function()
				self:UpdateRoundData()

				local Text   = language.GetPhrase("acf.menu.ammo.pen_stats_heat")
				local Standoff1 = math.Round(BulletData.Standoff * 1e3, 0)
				local Pen1 = math.Round(self:GetPenetration(BulletData, BulletData.Standoff), 1)
				local Standoff2 = math.Round(BulletData.BreakupDist * 1e3, 0)
				local Pen2 = math.Round(self:GetPenetration(BulletData, BulletData.BreakupDist), 1)

				PenStats:SetText(Text:format(Standoff1, Pen1, Standoff2, Pen2))
			end)
		end

		-- Ammo menu graph: penetration over standoff distance.
		function CLASS:PlotAmmoGraph(Panel, _, BulletData)
			local Colors  = ACF.GraphColors
			local PenText = language.GetPhrase("acf.menu.ammo.penetration")

			local PassiveStandoffPen = self:GetPenetration(BulletData, BulletData.Standoff)
			local BreakupDistPen     = self:GetPenetration(BulletData, BulletData.BreakupDist)

			Panel:SetYRange(0, math.max(BreakupDistPen, PassiveStandoffPen) * 1.5)
			Panel:SetXRange(0, BulletData.BreakupDist * 1000 * 2.5) -- HEAT doesn't care how long the shell has been flying for penetration, just the instant it detonates
			Panel:SetXLabel("#acf.menu.ammo.standoff")

			Panel:PlotPoint(language.GetPhrase("acf.menu.ammo.passive"), BulletData.Standoff * 1000, PassiveStandoffPen, Colors.Blue)
			Panel:PlotPoint(language.GetPhrase("acf.menu.ammo.breakup"), BulletData.BreakupDist * 1000, BreakupDistPen, Colors.Red)

			Panel:PlotFunction(PenText, Colors.RedAlt, function(X)
				return self:GetPenetration(BulletData, X / 1000)
			end)
		end

		-- Ammo menu visual: built from a GeoPrim tree (see acf/core/geo_prim_sh.lua) rather than hand-rolled
		-- pixel math, so the shell's geometry -- casing, warhead, and the conical liner cavity carved into
		-- the nose -- has one definition shared between rendering and (eventually) volume-derived quantities.
		function CLASS:DrawAmmoVisual(Panel, w, h, _, BulletData)
			local GeoPrim = ACF.GeoPrim
			local Margin  = 10
			local DrawW   = w - Margin * 2

			local ConeAngle = math.max(BulletData.ConeAng or 45, 5)
			local Diameter  = BulletData.Diameter or BulletData.Caliber
			local ConeDepth = math.min((Diameter * 0.5) / math.tan(math.rad(ConeAngle)), BulletData.ProjLength * 0.8)

			-- The standoff gap is a real distance (BulletData.Standoff, in meters) rather than a fixed
			-- fraction of the shell, so it's budgeted into the layout length up front -- capped to the
			-- shell's own length so a long standoff doesn't dwarf the round in the schematic -- rather
			-- than squeezed into whatever pixels happen to be left over after the casing and warhead.
			local ShellLength = BulletData.ProjLength + BulletData.PropLength
			local StandoffCm  = math.min((BulletData.Standoff or 0) * 100, ShellLength)
			local Length = ShellLength + StandoffCm

			if Length <= 0 then return end

			-- Cap Scale by the case, the widest part, so the case/bore step survives the height budget
			local CaseDia = BulletData.CaseDiameter

			if CaseDia <= 0 then return end

			local Scale      = math.min(DrawW / Length, ((h - Margin * 2) * 0.6) / CaseDia)
			local DiameterPx = CaseDia * Scale
			local BoreDiaPx  = Diameter * Scale -- The warhead's own width, which the standoff probe keys off
			local CenterY    = h * 0.5

			local Propellant = GeoPrim.New("Cylinder", { Radius = CaseDia * 0.5, Height = BulletData.PropLength })
			Propellant:SetMaterial("Propellant")

			local Warhead = GeoPrim.New("Cylinder", { Radius = Diameter * 0.5, Height = BulletData.ProjLength })
			Warhead:SetMaterial("Explosive")

			-- Liner cavity: apex (Radius 0) buried ConeDepth behind the nose, mouth (full bore) opening
			-- flush with the front face -- matches the shaped charge pointing its jet forward on impact.
			local Liner = GeoPrim.New("Cone", { Radius = 0, TipRadius = Diameter * 0.5, Height = ConeDepth })
			Liner:SetVoid(true):SetMaterial("Copper Liner (Shaped Charge)")
			Warhead:AddChild(Liner, BulletData.ProjLength - ConeDepth)

			local X = Margin
			X = Propellant:Draw(Panel, X, CenterY, Scale, DiameterPx, Color(180, 150, 60), Color(30, 30, 30))
			X = Warhead:Draw(Panel, X, CenterY, Scale, DiameterPx, Color(150, 90, 40), Color(30, 30, 30))

			-- Standoff gap: distance the jet needs before hitting the target for full penetration
			local StandoffPx = StandoffCm * Scale

			if StandoffPx > 1 then
				local StandoffMm = math.Round(StandoffCm * 10)
				local StandoffDiameterMm = math.Round(Diameter * 0.5 * 10)

				surface.SetDrawColor(255, 200, 60, 120)
				surface.DrawRect(X, CenterY - BoreDiaPx * 0.25, StandoffPx, BoreDiaPx * 0.5)
				Panel:AddRegion(X, CenterY - BoreDiaPx * 0.25, StandoffPx, BoreDiaPx * 0.5, ("Standoff Probe\n%dx%d mm"):format(StandoffDiameterMm, StandoffMm))
			end
		end
	end
end)