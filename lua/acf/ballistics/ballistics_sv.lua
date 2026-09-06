local hook        = hook
local ACF         = ACF
local Ballistics  = ACF.Ballistics
local Damage      = ACF.Damage
local Clock       = ACF.Utilities.Clock
local Effects     = ACF.Utilities.Effects
local EventViewer = ACF.EventViewer

Ballistics.Bullets         = Ballistics.Bullets or {}
Ballistics.UnusedIndexes   = Ballistics.UnusedIndexes or {}
Ballistics.HighestIndex    = Ballistics.HighestIndex or 0
Ballistics.SkyboxGraceZone = Ballistics.SkyboxGraceZone or 100

local function GetEventViewerName(Idx) return "Ballistics - Bullet #" .. Idx end


local Bullets      = Ballistics.Bullets
local Unused       = Ballistics.UnusedIndexes
local IndexLimit   = 2000
local SkyGraceZone = Ballistics.SkyboxGraceZone
local FlightTr     = { start = true, endpos = true, filter = true, mask = true }
local GlobalFilter = ACF.GlobalFilter
local AmmoTypes    = ACF.Classes.AmmoTypes
local ArmorTypes   = ACF.Classes.ArmorTypes

-- This will create, or update, the tracer effect on the clientside
function Ballistics.BulletClient(Bullet, Type, Hit, HitPos)
	if Bullet.NoEffect then return end -- No clientside effect will be created for this bullet

	local IsUpdate = Type == "Update"
	local EffectTable = {
		DamageType = Bullet.Index,
		Start = Bullet.Flight * 0.1,
		Attachment = Bullet.Hide and 0 or 1,
		Origin = (IsUpdate and Hit > 0) and HitPos or Bullet.Pos,
		Scale = (not Bullet.Hide and IsUpdate) and Hit or 0,
		EntIndex = not IsUpdate and Bullet.Crate or nil,
	}

	Effects.CreateEffect("ACF_Bullet_Effect", EffectTable, true, true)
end

function Ballistics.RemoveBullet(Bullet)
	if Bullet.Removed then return end

	local Index = Bullet.Index

	Bullets[Index] = nil
	Unused[Index]  = true

	if Bullet.OnRemoved then
		Bullet:OnRemoved()
	end

	if EventViewer.Enabled() then
		EventViewer.AppendEvent(GetEventViewerName(Index), "Ballistics.RemoveBullet")
	end
	Bullet.Removed = true

	if not next(Bullets) then
		hook.Remove("ACF_OnTick", "ACF Iterate Bullets")
	end
end

function Ballistics.CalcBulletFlight(Bullet)
	local ClockTime = Clock.CurTime

	if Bullet.KillTime and ClockTime >= Bullet.KillTime then
		return Ballistics.RemoveBullet(Bullet)
	end

	if Bullet.PreCalcFlight then
		Bullet:PreCalcFlight()
	end

	local DeltaTime  = ClockTime - Bullet.LastThink
	local Flight     = Bullet.Flight
	local Drag       = Flight:GetNormalized() * (Bullet.DragCoef * Flight:LengthSqr()) / ACF.DragDiv
	local Accel      = Bullet.Accel or ACF.Gravity
	local Correction = 0.5 * (Accel - Drag) * DeltaTime

	Bullet.NextPos   = Bullet.Pos + ACF.Scale * DeltaTime * (Flight + Correction)
	Bullet.TraceTo   = Bullet.Pos + ACF.Scale * (DeltaTime * 2) * (Flight + Correction)
	Bullet.Flight    = Flight + (Accel - Drag) * DeltaTime
	Bullet.LastThink = ClockTime
	Bullet.DeltaTime = DeltaTime

	Ballistics.DoBulletsFlight(Bullet)

	if Bullet.PostCalcFlight then
		Bullet:PostCalcFlight()
	end

	debugoverlay.Line(Bullet.Pos, Bullet.NextPos, 15, Bullet.Color, true)
	Bullet.Pos = Bullet.NextPos
end

function Ballistics.GetBulletIndex()
	if next(Unused) then
		local Index = next(Unused)

		Unused[Index] = nil

		return Index
	end

	local Index = Ballistics.HighestIndex + 1

	if Index > IndexLimit then return end

	Ballistics.HighestIndex = Index

	return Index
end

function Ballistics.IterateBullets()
	for _, Bullet in pairs(Bullets) do
		if not Bullet.HandlesOwnIteration then
			Ballistics.CalcBulletFlight(Bullet)
		end
	end
end


local RequiredBulletDataProperties = {"Pos", "Flight"}
function Ballistics.CreateBullet(BulletData)
	local Index = Ballistics.GetBulletIndex()
	if not Index then return end -- Too many bullets in the air

	-- Validate BulletData, so we can catch these problems easier

	for _, RequiredProp in ipairs(RequiredBulletDataProperties) do
		if not BulletData[RequiredProp] then
			error(("Ballistics.CreateBullet: Expected '%s' to be present in BulletData, got nil!"):format(RequiredProp))
		end
	end

	local Bullet = table.Copy(BulletData)

	if not Bullet.Filter then
		Bullet.Filter = IsValid(Bullet.Gun) and { Bullet.Gun } or {}
	end

	Bullet.Index       = Index
	Bullet.LastThink   = Clock.CurTime
	Bullet.Fuze        = Bullet.Fuze and Bullet.Fuze + Clock.CurTime or nil -- Convert Fuze from fuze length to time of detonation
	if Bullet.Caliber then
		Bullet.Mask		= (Bullet.Caliber < 3 and bit.band(MASK_SOLID, MASK_SHOT) or MASK_SOLID) -- I hope CONTENTS_AUX isn't used for anything important? I can't find any references outside of the wiki to it so hopefully I can use this
	else
		Bullet.Mask		= MASK_SOLID
	end

	Bullet.Ricochets   = Bullet.Ricochets or 0
	Bullet.GroundRicos = Bullet.GroundRicos or 0
	Bullet.Color       = ColorRand(100, 255)

	-- Purely to allow someone to shoot out of a seat without hitting themselves and dying
	if IsValid(Bullet.Owner) and Bullet.Owner:IsPlayer() and Bullet.Owner:InVehicle() and (Bullet.Gun and Bullet.Gun:GetClass() ~= "acf_gun") then
		Bullet.Filter[#Bullet.Filter + 1] = Bullet.Owner:GetVehicle()
	end

	if EventViewer.Enabled() then
		EventViewer.StartEvent(GetEventViewerName(Index))
		-- Network the whole bullet state when event viewer is active.
		EventViewer.AppendEvent(GetEventViewerName(Index), "Ballistics.CreateBullet", Bullet)
	end

	-- TODO: Make bullets use a metatable instead
	-- Bullet.PenetrationOverride lets standoff-dependent ammo types (HEAT) report their real current penetration instead of the Standoff-less placeholder.
	function Bullet:GetPenetration()
		if Bullet.PenetrationOverride then return Bullet.PenetrationOverride end

		local Ammo = AmmoTypes.Get(Bullet.Type)

		return Ammo:GetPenetration(self)
	end

	if not next(Bullets) then
		hook.Add("ACF_OnTick", "ACF Iterate Bullets", Ballistics.IterateBullets)
	end

	Bullets[Index] = Bullet

	Ballistics.BulletClient(Bullet, "Init", 0)
	Ballistics.CalcBulletFlight(Bullet)

	return Bullet
end

function Ballistics.GetImpactType(Trace, Entity)
	if Trace.HitWorld then return "World" end
	if Entity:IsPlayer() or Entity:IsNPC() or Entity:IsNextBot() then return "Prop" end

	return IsValid(Entity:CPPIGetOwner()) and "Prop" or "World"
end

function Ballistics.OnImpact(Bullet, Trace, Ammo, Type)
	local Func  = Type == "World" and Ammo.WorldImpact or Ammo.PropImpact
	local Retry = Func(Ammo, Bullet, Trace)

	if Retry == "Penetrated" then
		if Bullet.OnPenetrated then
			Bullet.OnPenetrated(Bullet, Trace)
		end

		Ballistics.BulletClient(Bullet, "Update", 2, Trace.HitPos)
		Ballistics.DoBulletsFlight(Bullet)
		if EventViewer.Enabled() then
			EventViewer.AppendEvent(GetEventViewerName(Bullet.Index), "Ballistics.OnImpact.Penetrated", Trace.StartPos, Trace.HitPos, Trace)
		end
	elseif Retry == "Ricochet" then
		if Bullet.OnRicocheted then
			Bullet.OnRicocheted(Bullet, Trace)
		end

		Ballistics.BulletClient(Bullet, "Update", 3, Trace.HitPos)
		Ballistics.DoBulletsFlight(Bullet)
		if EventViewer.Enabled() then
			EventViewer.AppendEvent(GetEventViewerName(Bullet.Index), "Ballistics.OnImpact.Ricochet", Trace.StartPos, Trace.HitPos, Trace)
		end
	else
		if Bullet.OnEndFlight then
			Bullet.OnEndFlight(Bullet, Trace)
		end

		Ballistics.BulletClient(Bullet, "Update", 1, Trace.HitPos)
		if EventViewer.Enabled() then
			EventViewer.AppendEvent(GetEventViewerName(Bullet.Index), "Ballistics.OnImpact.Unknown", Trace.StartPos, Trace.HitPos, Trace)
		end
		Ammo:OnFlightEnd(Bullet, Trace)
	end
end

-- Marks a single convex of an entity as transparent to this bullet for the rest of its flight.
-- Used when a projectile penetrates a convex so subsequent re-traces advance to the next one.
function Ballistics.FilterConvex(Bullet, Entity, ConvexID)
	local ConvexFilter = Bullet.ConvexFilter

	if not ConvexFilter then
		ConvexFilter = {}
		Bullet.ConvexFilter = ConvexFilter
	end

	local EntFilter = ConvexFilter[Entity]

	if not EntFilter then
		EntFilter = {}
		ConvexFilter[Entity] = EntFilter
	end

	EntFilter[ConvexID] = true
end

function Ballistics.TestFilter(Entity, Bullet)
	if not IsValid(Entity) then return true end

	if GlobalFilter[Entity:GetClass()] then return false end

	if not hook.Run("ACF_OnFilterBullet", Entity, Bullet) then return false end

	local EntTbl = Entity:GetTable()

	if ACF.FilterMakeSpherical and EntTbl._IsSpherical then return false end -- TODO: Remove when damage changes make props unable to be destroyed, as physical props can have friction reduced (good for wheels)
	if EntTbl.ACF_InvisibleToBallistics then return false end
	if EntTbl.ACF_KillableButIndestructible then
		local EntACF = EntTbl.ACF
		if EntACF and EntACF.Health <= 0 then return false end
	end
	if EntTbl.ACF_TestFilter then return EntTbl.ACF_TestFilter(Entity, Bullet) end

	return true
end

-- Resolves the earliest live, unfiltered convex any ACF-meshed entity along the ray presents --
-- e.g. a component clipped inside an armor shell. Same shape as ACF.GetConvexHit (plus
-- Entity), or nil if nothing's left to hit in this bullet's flight segment.
function Ballistics.GetMeshConvexHit(Bullet, HitPos, Direction)
	local Start     = HitPos - Direction * 2 -- same backoff ACF.GetConvexHits uses
	local FoundEnts = ents.FindAlongRay(Start, Bullet.TraceTo) -- bounds discovery to this segment, same as the physics trace already covers

	local Intersections = {}

	for _, Ent in ipairs(FoundEnts) do
		if not Ent.ACF_Volumetric_Mesh then continue end
		if table.HasValue(Bullet.Filter, Ent) then continue end

		if not Ballistics.TestFilter(Ent, Bullet) then
			table.insert(Bullet.Filter, Ent) -- same "filtered for the rest of this bullet's life" semantics as today's whole-entity filter
			continue
		end

		local EntConvexFilter = Bullet.ConvexFilter and Bullet.ConvexFilter[Ent]
		local Hits            = ACF.RayIntersectMesh(Ent, Start, Direction, false, EntConvexFilter)

		for _, Hit in ipairs(Hits) do
			Intersections[#Intersections + 1] = Hit
		end
	end

	return ACF.ResolveConvexStack(Intersections, Direction, true)
end

function Ballistics.DoBulletsFlight(Bullet)
	local CanFly = hook.Run("ACF_PreBulletFlight", Bullet)

	if not CanFly then return end

	if Bullet.SkyLvL then
		if Clock.CurTime - Bullet.LifeTime > 30 then
			return Ballistics.RemoveBullet(Bullet)
		end

		if Bullet.NextPos.z + SkyGraceZone > Bullet.SkyLvL then
			if Bullet.Fuze and Bullet.Fuze <= Clock.CurTime then -- Fuze detonated outside map
				Ballistics.RemoveBullet(Bullet)
			end

			return
		elseif not util.IsInWorld(Bullet.NextPos) then
			return Ballistics.RemoveBullet(Bullet)
		else
			Bullet.SkyLvL = nil
			Bullet.LifeTime = nil

			return
		end
	end

	FlightTr.mask 	= Bullet.Mask
	FlightTr.filter = Bullet.Filter
	FlightTr.start 	= Bullet.Pos
	FlightTr.endpos = Bullet.TraceTo

	local traceRes = ACF.trace(FlightTr) -- Does not modify the bullet's original filter

	if Bullet.Fuze and Bullet.Fuze <= Clock.CurTime then
		if not util.IsInWorld(Bullet.Pos) then -- Outside world, just delete
			return Ballistics.RemoveBullet(Bullet)
		else
			local DeltaTime = Bullet.DeltaTime
			local DeltaFuze = Clock.CurTime - Bullet.Fuze
			local Lerp = DeltaFuze / DeltaTime

			if not traceRes.Hit or Lerp < traceRes.Fraction then -- Fuze went off before running into something
				Bullet.Pos       = LerpVector(Lerp, Bullet.Pos, Bullet.NextPos)
				Bullet.DetByFuze = true

				if Bullet.OnEndFlight then
					Bullet.OnEndFlight(Bullet, traceRes)
				end

				Ballistics.BulletClient(Bullet, "Update", 1, Bullet.Pos)

				AmmoTypes.Get(Bullet.Type):OnFlightEnd(Bullet, traceRes)
				if EventViewer.Enabled() then
					EventViewer.AppendEvent(GetEventViewerName(Bullet.Index), "Ballistics.DoBulletsFlight.Fuze")
				end

				return
			end
		end
	end


	if EventViewer.Enabled() then
		EventViewer.AppendEvent(GetEventViewerName(Bullet.Index), "Ballistics.DoBulletsFlight", Bullet.Pos, Bullet.NextPos, FlightTr)
	end

	if traceRes.Hit then
		if traceRes.HitSky then
			if traceRes.HitNormal == -vector_up then
				Bullet.SkyLvL = traceRes.HitPos.z
				Bullet.LifeTime = Clock.CurTime
			else
				Ballistics.RemoveBullet(Bullet)
			end
		else
			local Entity = traceRes.Entity

			if not Ballistics.TestFilter(Entity, Bullet) then
				-- Retries the same trace immediately after adding the entity to the filter; important in case
				-- something is embedded in something that shouldn't be hit. Retrying via timer would let
				-- CalcBulletFlight advance Bullet.Pos first, skipping anything behind this entity this segment.
				table.insert(Bullet.Filter, Entity)

				return Ballistics.DoBulletsFlight(Bullet)
			end

			-- Resolve against the earliest live convex across every meshed entity in range, not just
			-- the one the physics trace reported -- so an entity embedded in another (e.g. a
			-- component inside an armor shell) still gets hit properly. If nothing's left anywhere,
			-- filter Entity and retry.
			local ConvexHit
			if Entity.ACF_Volumetric_Mesh then
				ConvexHit = Ballistics.GetMeshConvexHit(Bullet, traceRes.HitPos, Bullet.Flight:GetNormalized())

				if not ConvexHit then
					-- Re-trace immediately (not via timer) from the same position: deferring until the next
					-- frame lets CalcBulletFlight advance Bullet.Pos to NextPos first, so the retry would start
					-- mid-segment and skip any props sitting behind this transparent one in the current segment.
					table.insert(Bullet.Filter, Entity)

					return Ballistics.DoBulletsFlight(Bullet)
				end

				-- Splice the mesh-resolved hit into the trace so downstream code sees the entity
				-- actually struck, even when it differs from what the physics trace reported.
				traceRes.Entity    = ConvexHit.Entity
				traceRes.HitPos    = ConvexHit.EntryPos
				traceRes.HitNormal = ConvexHit.EntryNormal
			end

			-- Stored on the bullet rather than the trace: the EventViewer networks the trace table, and a
			-- convex hit carries its ArmorType (a class object with functions) which can't be serialized.
			Bullet.ConvexHit = ConvexHit

			local Type = Ballistics.GetImpactType(traceRes, traceRes.Entity)

			Ballistics.OnImpact(Bullet, traceRes, AmmoTypes.Get(Bullet.Type), Type)
		end
	end
end

do -- Terminal ballistics --------------------------
	function Ballistics.GetRicochetVector(Flight, HitNormal)
		local Normal = Flight:GetNormalized()

		return Normal - (2 * Normal:Dot(HitNormal)) * HitNormal
	end

	-- Re-seeds a bullet's flight after a ricochet and resets Pos/NextPos/TraceTo so the immediate
	-- re-trace this tick (triggered by OnImpact's "Ricochet" branch) starts from the ricochet point.
	-- Speed is unscaled (real-world) velocity; Spread is the VectorRand jitter magnitude.
	function Ballistics.ApplyRicochet(Bullet, Position, HitNormal, Speed, Ricochet, Spread, DeltaTime)
		local Direction = Ballistics.GetRicochetVector(Bullet.Flight, HitNormal) + VectorRand() * Spread
		local Flight    = Direction:GetNormalized() * Speed * Ricochet * ACF.Scale

		Bullet.Flight  = Flight
		Bullet.Pos     = Position
		Bullet.NextPos = Position + Flight * DeltaTime
		Bullet.TraceTo = Position + Flight * (DeltaTime * 2)
	end

	-- HitAngle (optional) overrides the angle derived from the physical trace; the per-convex impact
	-- path passes the struck convex's entry angle so ricochets evaluate against the real convex face.
	function Ballistics.CalculateRicochet(Bullet, Trace, HitAngle)
		HitAngle = HitAngle or ACF.GetHitAngle(Trace, Bullet.Flight)
		-- Ricochet distribution center
		local sigmoidCenter = Bullet.DetonatorAngle or (Bullet.Ricochet - math.abs(Bullet.Speed / ACF.MeterToInch - Bullet.LimitVel) / 100)

		-- Ricochet probability (sigmoid distribution); up to 5% minimal ricochet probability for projectiles with caliber < 20 mm
		local ricoProb = math.Clamp(1 / (1 + math.exp((HitAngle - sigmoidCenter) / -4)), math.max(-0.05 * (Bullet.Caliber - 2) / 2, 0), 1)

		-- Checking for ricochet
		local Ricochet = 0
		local Loss     = 0
		if ricoProb > math.random() and HitAngle < 90 then
			Ricochet = math.Clamp(HitAngle / 90, 0.05, 1) -- atleast 5% of energy is kept
			Loss     = 0.25 - Ricochet
		end
		return Ricochet, Loss
	end

	function Ballistics.DoRoundImpact(Bullet, Trace)
		local DmgResult, DmgInfo = Damage.getBulletDamage(Bullet, Trace)
		local Speed    = Bullet.Speed
		local Energy   = Bullet.Energy
		local Entity   = Trace.Entity
		local HitRes   = Damage.dealDamage(Entity, DmgResult, DmgInfo)
		local Ricochet = 0

		-- When the impact was resolved against a specific convex, ricochet, knockback and effects
		-- should use that convex's entry face/position instead of the entity's outer physical surface.
		local ConvexHit  = Bullet.ConvexHit
		local ImpactPos  = ConvexHit and ConvexHit.EntryPos or Trace.HitPos
		local HitNormal  = ConvexHit and ConvexHit.EntryNormal or Trace.HitNormal
		local HitAngle   = ConvexHit and ConvexHit.HitAngle or nil

		-- Determine this before ricochetting
		if (HitRes.Kill or (HitRes.Overkill and HitRes.Overkill > 0)) and not Bullet.IsSpall and not Bullet.IsCookOff then
			-- Penetrated or killed plate
			Ballistics.DoSpall(Bullet, Trace, HitRes, Bullet.Flight:Length(), DmgInfo)
		end

		-- Detonate any explosive reactive armor the round struck (guards on round type and kinetic energy internally)
		Ballistics.DoReactiveArmor(Bullet, Trace, DmgInfo)

		-- The round punched through the struck convex; mark it transparent so the flight loop's next
		-- re-trace advances to the convex behind it instead of resolving against this one again.
		if ConvexHit and HitRes.Overkill and HitRes.Overkill > 0 then
			Ballistics.FilterConvex(Bullet, Entity, ConvexHit.ConvexID)
		end

		if HitRes.Loss == 1 then
			-- If the there's more armor than penetration, the bullet ricochets
			Ricochet, HitRes.Loss = Ballistics.CalculateRicochet(Bullet, Trace, HitAngle)
		end

		-- Transfer bullet momentum into target
		if ACF.KEPush then
			ACF.KEShove(
				Entity,
				ImpactPos,
				-Bullet.Flight:GetNormalized(),
				Energy.Kinetic * HitRes.Loss * 1000 * Bullet.ShovePower
			)
		end

		-- If the entity should be killed, kill it
		if HitRes.Kill and IsValid(Entity) then
			ACF.APKill(Entity, Bullet.Flight:GetNormalized(), Energy.Kinetic, DmgInfo)
		end

		HitRes.Ricochet = false

		-- Apply the ricochet for the next bullet iteration if needed
		if Ricochet > 0 and Bullet.Ricochets < 3 then
			Bullet.Ricochets = Bullet.Ricochets + 1

			Ballistics.ApplyRicochet(Bullet, ImpactPos, HitNormal, Speed, Ricochet, 0.025, Bullet.DeltaTime)

			HitRes.Ricochet = true
		end

		return HitRes
	end

	function Ballistics.DoRicochet(Bullet, Trace)
		local HitAngle = ACF.GetHitAngle(Trace, Bullet.Flight)
		local Speed    = Bullet.Flight:Length() / ACF.Scale
		local MinAngle = math.min(Bullet.Ricochet - Speed / ACF.MeterToInch / 30 + 20, 89.9) -- Making the chance of a ricochet get higher as the speeds increase
		local Ricochet = 0

		if HitAngle < 89.9 and HitAngle > math.random(MinAngle, 90) then -- Checking for ricochet
			Ricochet = HitAngle / 90 * 0.75
		end

		if Ricochet > 0 and Bullet.GroundRicos < 2 then
			local DeltaTime = engine.TickInterval()

			Bullet.GroundRicos = Bullet.GroundRicos + 1

			Ballistics.ApplyRicochet(Bullet, Trace.HitPos, Trace.HitNormal, Speed, Ricochet, 0.05, DeltaTime)

			return "Ricochet"
		end

		return false
	end

	-- Tuning constants for DoSpall; kept as locals (rather than ACF globals) so they can be edited and hot-reloaded from this file alone, without a full game restart.
	local SpallFragFraction   = 0.01 -- Fraction of the spall energy budget that goes into forming countable fragments
	local SpallEnergyFraction = 0.005 -- Fraction of the spall energy budget imparted to the ejected mass as kinetic energy
	local SpallMinCone        = 30     -- Degrees, spall cone half angle with maximum overmatch (Loss near 0)
	local SpallMaxCone        = 90    -- Degrees, spall cone half angle near the ballistic limit (Loss near 1)
	local SpallAnglePower     = 2 -- Bias for angle sampling; higher packs more fragments near the cone axis
	local SpallEnergyFalloff  = 2   -- Power of the cos(angle) energy falloff used to split speed across fragments

	local SpallMinFragCount   = 1 -- Minimum number of fragments created; ensures at least one fragment is formed even with very low energy
	local SpallMaxFragCount   = 20 -- Hard limit on the number of fragments created; prevents server overload from a single overmatch

	function Ballistics.DoSpall(Bullet, Trace, HitRes, Speed, DmgInfo)
		-- Only ever called during overpenetration
		local Energy = Bullet.Energy.Kinetic -- Energy the projectile carries (kJ)

		-- Spall is generated from the convex the bullet exited through; its material determines the removed mass and how readily it fragments
		local RemovedMass
		local Density
		local SpallMul   = 1
		local MeshData   = Trace.Entity.ACF_Volumetric_Mesh
		local ConvexHits = DmgInfo and DmgInfo:GetConvexHits()

		if MeshData and ConvexHits and #ConvexHits > 0 then
			local ExitHit   = ConvexHits[#ConvexHits]
			local Convex    = MeshData.Convexes[ExitHit.ConvexID]
			local ArmorType = ArmorTypes.Get(Convex.Material) or ArmorTypes.Get("Default")

			RemovedMass = ExitHit.Volume * ACF.InchToMCu * ArmorType.Density -- ExitHit.Volume is the actual penetration channel volume (in^3), Density is kg/m^3
			Density     = ArmorType.Density * 1e-6 -- kg/m^3 to kg/cm^3, to match FragSize's cm-based units below
			SpallMul    = ArmorType.SpallMul
		else
			RemovedMass = HitRes.Damage * ACF.RHADensity -- Damage is used as a proxy for volume (cm^3) and RHA density is in kg/cm^3
			Density     = ACF.RHADensity
		end

		if RemovedMass <= 0 then return end -- Nothing was actually removed, so there's no mass to turn into fragments

		-- Both the fragment count and the fragments' kinetic energy are drawn from the penetrator's kinetic energy, scaled by how readily this material spalls.
		local SpallEnergy = Energy * SpallMul -- kJ

		local FragsFormed = SpallEnergy * SpallFragFraction
		local FragCount = math.Clamp(math.floor(FragsFormed), SpallMinFragCount, SpallMaxFragCount) -- Atleast 1, up to 20 fragments (let's not kill the server)

		if FragCount < 1 then return end -- No fragments formed

		local FragMassAvg = RemovedMass / FragCount 	-- Average mass of the fragments (kg)
		local MottMu      = FragMassAvg / 2 			-- Mott's characteristic mass; mean fragment mass = 2*mu

		-- Total kinetic energy budget for the spall, split per-fragment below so mass, angle and speed all vary together instead of one bulk speed for everyone.
		local TotalFragEnergy = SpallEnergy * SpallEnergyFraction * 1000 -- kJ to J

		-- Half angle of the spall cone: closer to the ballistic limit (Loss near 1) the plate barely fails and sprays debris wide, while heavy overmatch (Loss near 0) keeps debris close to the original flight direction.
		local BaseCone = SpallMinCone + (SpallMaxCone - SpallMinCone) * HitRes.Loss
		local FragPos = (Bullet.ConvexHit and Bullet.ConvexHit.ExitPos) or Trace.HitPos -- Spall originates at the convex the bullet exited through
		local FragDirInit = Bullet.Flight:GetNormalized()

		-- Filter what the bullet has travelled through + the hit entity itself if applicable
		local Filter = table.Copy(Bullet.Filter)
		if Trace.Entity:IsValid() then Filter[#Filter + 1] = Trace.Entity end

		-- Define a plane for the spread
		local Right = FragDirInit:Cross(Vector(0, 0, 1)):GetNormalized()
		local Up = FragDirInit:Cross(Right):GetNormalized()

		-- Sample fragment masses from Mott's distribution (m = mu * ln(1/u)^2, decreasing in u) and reuse the same draw for this fragment's cone angle (BaseCone * u^SpallAnglePower, increasing in u), so a heavy fragment naturally pairs with a small angle and a light one with a wide angle.
		local Masses, Weights, MassSum, WeightSum = {}, {}, 0, 0
		for i = 1, FragCount do
			local U = 1 - math.random()

			local Mass = math.max(MottMu * math.log(1 / U) ^ 2, 1e-6)
			Masses[i] = Mass
			MassSum = MassSum + Mass

			local Angle = BaseCone * U ^ SpallAnglePower
			local Weight = math.cos(math.rad(Angle)) ^ SpallEnergyFalloff
			Weights[i] = { Angle = Angle, Weight = Weight }
			WeightSum = WeightSum + Weight
		end

		-- Rescale so the sampled masses still sum to RemovedMass, since a small sample of fragments won't average to 2*mu exactly.
		local MassScale = RemovedMass / MassSum

		-- Create the fragments
		for i = 1, FragCount do
			local FragMass   = Masses[i] * MassScale
			local FragVolume = FragMass / Density -- cm^3, assuming the fragment has the same density as the removed material
			local FragSize   = (6 * FragVolume / math.pi) ^ (1 / 3) -- Diameter of a sphere of that volume (cm)

			-- Copied from AP ammotype definition
			local ProjArea = math.pi * (FragSize / 2) ^ 2
			local DragCoef = ProjArea * 0.0001 / FragMass

			-- This fragment's share of the total energy budget, via energy conservation (Speed = sqrt(2 * KE / Mass)), clamped to the impact speed since spall can't outrun its source.
			local FragEnergy = TotalFragEnergy * Weights[i].Weight / WeightSum
			local FragSpeed  = math.min((2 * FragEnergy / FragMass) ^ 0.5 * ACF.MeterToInch, Speed)

			-- Point on a circle at this fragment's sampled angle, placed at a random rotation around the cone axis
			local SpreadRadius = math.tan(math.rad(Weights[i].Angle))
			local SpreadAngle = math.random() * 2 * math.pi
			local SpreadDir = Up * SpreadRadius * math.cos(SpreadAngle) + Right * SpreadRadius * math.sin(SpreadAngle)
			local FragDir = (FragDirInit + SpreadDir):GetNormalized()

			Ballistics.CreateFragment({
				Diameter = FragSize,
				Owner    = Bullet.Owner,
				Entity   = Bullet.Entity,
				Gun      = Bullet.Gun,
				Pos      = FragPos,
				ProjArea = ProjArea,
				ProjMass = FragMass,
				DragCoef = DragCoef,
				Flight   = FragDir * FragSpeed,
				Filter   = Filter,
			})
		end
	end

	-- Explosive Reactive Armor: when a round carrying enough kinetic energy passes through an explosive
	-- armor convex, that convex detonates. The spent convex is zeroed out (becoming transparent to ballistics)
	-- and its filler is set off as an HE blast at the impact point.
	function Ballistics.DoReactiveArmor(Bullet, Trace, DmgInfo)
		if Bullet.IsSpall or Bullet.IsCookOff then return end -- Neither carries a warhead that could set the plate off

		local Entity = Trace.Entity
		if not IsValid(Entity) then return end

		local MeshData = Entity.ACF_Volumetric_Mesh
		if not MeshData or not MeshData.HasReactiveArmor then return end -- Nothing reactive on this entity; bail before any work

		local ConvexHits = DmgInfo and DmgInfo.GetConvexHits and DmgInfo:GetConvexHits()
		if not ConvexHits then return end

		local KE = Bullet.Energy and Bullet.Energy.Kinetic or 0
		print(KE)

		for _, Hit in ipairs(ConvexHits) do
			local Convex = MeshData.Convexes[Hit.ConvexID]
			if not Convex or not Convex.IsExplosive or Convex.Detonated then continue end

			local ArmorType = ArmorTypes.Get(Convex.Material)
			if not ArmorType then continue end
			if KE < (ArmorType.ExplosiveThreshold or math.huge) then continue end

			-- Spend the convex; zero health makes it transparent to subsequent projectiles
			Convex.Detonated = true
			Convex.Health    = 0
			Damage.NetworkConvex(Entity, Hit.ConvexID)

			local Filler = Convex.Mass * (ArmorType.ExplosiveFiller or 0)
			-- print("Filler", 	Filler)
			if Filler <= 0 then continue end

			local FragMass  = math.max(Convex.Mass - Filler)
			local Position  = (Bullet.ConvexHit and Bullet.ConvexHit.EntryPos) or Trace.HitPos
			local BlastInfo = Damage.Objects.DamageInfo(Bullet.Owner, Bullet.Gun)

			Damage.createExplosion(Position, Filler, FragMass, { Entity }, BlastInfo)
			Damage.explosionEffect(Position, nil, Filler)
		end
	end
end
