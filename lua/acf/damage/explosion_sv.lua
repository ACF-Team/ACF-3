local ACF         = ACF
local Damage      = ACF.Damage
local ModelData   = ACF.ModelData
local Objects     = Damage.Objects
local Ballistics  = ACF.Ballistics
local Debug       = ACF.Debug
local EventViewer = ACF.EventViewer

-- library functions
local ents       = ents
local util       = util
local math       = math
local sqrt       = math.sqrt
local floor      = math.floor
local max        = math.max
local min        = math.min
local pi         = math.pi
local random     = math.random
local Rand       = math.Rand
local IsValid    = IsValid
local Sort       = table.sort
local ACFTrace   = ACF.trace

-- ACF constants
local HEPower    = ACF.HEPower
local InchToCm   = ACF.InchToCm
local BlastAreaCoef = ACF.BlastAreaCoef
local InchToMeter = ACF.InchToMeter

-- Debugging
local White      = Color(255, 255, 255)
local Red        = Color(255, 0, 0)
local Green      = Color(0, 255, 0)

-- Trace data
local TraceResult = {}
local TraceData  = {
	start  = true,
	endpos = true,
	filter = true,
	mask   = MASK_SOLID + CONTENTS_AUX,
	output = TraceResult
}

local function SortByDistSqr(a, b)
	return a.DistSqr < b.DistSqr
end

--- Checks whether an entity can be affected by ACF explosions.
-- @param Entity The entity to be checked.
-- @return True if the entity can be affected by explosions, false otherwise.
function Damage.isValidTarget(Entity)
	local EntTbl = Entity:GetTable()
	if EntTbl.ACF_Killed or EntTbl.Exploding then return false end

	local EntACF = EntTbl.ACF
	local Type = EntACF and EntACF.Type or ACF.Check(Entity)

	if not Type then return false end
	if not Ballistics.TestFilter(Entity) then return false end

	if Type ~= "Squishy" then return true end

	return Entity:Health() > 0
end

--- Returns a random position on the given entity.
-- @param Entity The entity to get a random position from.
-- @param A world position based on the shape and size of the given entity.
local function getRandomPos(Entity)
	local IsChar = Entity.ACF and Entity.ACF.Type == "Squishy"

	if IsChar then
		-- Scale down the "hitbox" since most of the character is in the middle
		local Mins, Maxs = Entity:GetCollisionBounds()
		local X    = Rand(Mins[1], Maxs[1])
		local Y    = Rand(Mins[2], Maxs[2])
		local Z    = Rand(Mins[3], Maxs[3])

		return Entity:LocalToWorld(Vector(X, Y, Z) * 0.65)
	end

	if Entity._IsSpherical then
		local Radius = Entity:BoundingRadius() * 0.5

		return Entity:GetPos() + VectorRand() * Rand(1, Radius)
	end

	local Model    = Entity:GetModel()
	local Data     = ModelData.GetModelData(Model) -- Used instead of GetModelMesh, which does a full copy
	local Mesh     = Data.Mesh                     -- Accessing the raw mesh, read-only
	local Hull     = Mesh[random(1, #Mesh)]        -- Random hull
	local TriCount = floor(#Hull / 3)              -- Number of triangles in the hull
	local TriIndex = random(0, TriCount - 1)       -- Random triangle selection
	local Base     = TriIndex * 3 + 1              -- Multiply back up to the real index

	-- Get the three vertices of the triangle
	local V1, V2, V3 = Hull[Base], Hull[Base + 1], Hull[Base + 2]

	-- Sample a random point within the triangle using barycentric coordinates
	local r1, r2 = random(), random()

	if r1 + r2 > 1 then r1, r2 = 1 - r1, 1 - r2 end

	local Point = V1 + r1 * (V2 - V1) + r2 * (V3 - V1)

	-- Apply scale only to the single sampled point
	local Scale = ModelData.GetEntityScale(Entity)

	Point = Point * Scale

	return Entity:LocalToWorld(Point)
end

--- Creates an explosion at the given position.
-- @param Position The world coordinates where the explosion will be created at.
-- @param FillerMass The amount of HE filler in kilograms.
-- @param FragMass The amount of steel containing the filler in kilograms.
-- @param Filter Optional, a list of entities that will not be affected by the explosion.
-- @param DmgInfo A DamageInfo object.
function Damage.createExplosion(Position, FillerMass, FragMass, Filter, DmgInfo)
	local ExplosionName
	if EventViewer.Enabled() then
		ExplosionName = "ACF Explosion @ " .. SysTime()
		EventViewer.StartEvent(ExplosionName)
	end

	local Power       = FillerMass * HEPower
	local Radius      = Damage.getBlastRadius(FillerMass)
	local RadiusScale = math.exp(max(Radius / Damage.getBlastRadius(1) - 1, 0))
	local Found       = ents.FindInSphere(Position, Radius)

	if EventViewer.Enabled() then
		EventViewer.AppendEvent(ExplosionName, "Damage.createExplosion", Position, Power, Radius, Found)
	end

	do -- Screen shaking
		local Amp = min(Power * 0.0005, 50)
		util.ScreenShake(Position, Amp, Amp, Amp / 15, Radius * 10)
	end

	if not next(Found) then return end -- No targets found, nothing to do

	if not Filter then Filter = {} end

	TraceData.start  = Position
	TraceData.filter = Filter

	Debug.Cross(Position, 15, 15, White, true)

	DmgInfo:SetOrigin(Position)

	-- Phase 1: Build sorted target list
	-- Validate targets, sort by distance, cache target positions

	local TargetList  = {} -- Array for sorting
	local TargetData  = {} -- Lookup table for quick access
	local TargetCount = 0

	for _, Entity in ipairs(Found) do
		if Damage.isValidTarget(Entity) then
			local RandomPos   = getRandomPos(Entity)
			local Delta       = RandomPos - Position
			local DistSqr     = Delta:LengthSqr()
			local Dist        = sqrt(DistSqr)
			local TraceEndPos = Position + Delta * ((Dist + 24) / Dist)

			local Data = {
				Entity      = Entity,
				TraceEndPos = TraceEndPos,
				DistSqr     = DistSqr,
				Processed   = false,
			}

			TargetCount = TargetCount + 1
			TargetList[TargetCount] = Data
			TargetData[Entity] = Data
		else
			Filter[#Filter + 1] = Entity
		end
	end

	if TargetCount == 0 then return end

	-- Sort by distance (closest first)
	Sort(TargetList, SortByDistSqr)

	-- Per-explosion fragment constants, consumed per target in Phase 2
	local FragInfo     = Damage.getFragmentInfo(FillerMass, FragMass)
	local Fragments    = FragInfo.Count
	local FragMassCalc = FragInfo.Mass
	local BaseFragV    = FragInfo.Velocity
	local FragArea     = FragInfo.Area
	local FragCaliber  = FragInfo.Caliber

	if EventViewer.Enabled() then
		local MaxSphere = 4 * pi * (Radius * InchToCm) ^ 2
		EventViewer.AppendEvent(ExplosionName, "Damage.createExplosion Init", Position, FillerMass, FragMass, Filter, MaxSphere, Fragments)
	end

	-- Phase 2: Process targets
	-- Iterate through targets and check for occlusion
	-- Blockers (occluders) track which entities they block
	-- Blocked entities get added to top of stack if blocker is destroyed

	local Blocking = {} -- Blocking[Entity] = {list of entities this one blocks}
	local Index    = 1

	while Index <= TargetCount and Power > 0 do
		local Data = TargetList[Index]
		Index = Index + 1

		if Data.Processed then continue end

		local Entity = Data.Entity

		TraceData.endpos = Data.TraceEndPos

		ACFTrace(TraceData)

		if TraceResult.HitWorld then
			-- Hit world - this entity is permanently blocked from this angle
			-- Don't mark as processed - give another chance if we happen to hit it while tracing towards another target
			Debug.Line(Position, Data.TraceEndPos, 15, Green, true)

			continue
		end

		local HitPos = TraceResult.HitPos
		local HitEnt = TraceResult.Entity

		if HitEnt ~= Entity then
			-- We hit something that wasn't our intended target
			local BlockerData = TargetData[HitEnt]

			if not BlockerData then
				-- Entity wasn't in our sphere search (model extends into radius)
				-- Check if it's a valid target and add it to our tracking
				if IsValid(HitEnt) and Damage.isValidTarget(HitEnt) then
					local RandomPos   = getRandomPos(HitEnt)
					local Delta       = RandomPos - Position
					local DistSqr     = Delta:LengthSqr()
					local Dist        = sqrt(DistSqr)
					local TraceEndPos = Position + Delta * ((Dist + 24) / Dist)

					BlockerData = {
						Entity      = HitEnt,
						TraceEndPos = TraceEndPos,
						DistSqr     = DistSqr,
						Processed   = false,
					}

					TargetCount = TargetCount + 1

					TargetData[HitEnt]      = BlockerData
					TargetList[TargetCount] = BlockerData
				else
					-- Not a valid target, filter it and mark our original target as unreachable
					Filter[#Filter + 1] = HitEnt
					Data.Processed      = true

					--Debug.Line(Position, HitPos, 15, White, true)

					continue
				end
			elseif not BlockerData.Processed then
				-- Blocked by another valid target we haven't processed yet
				-- If the blocker dies or is penetrated, we'll try to hit this target again
				local BlockList = Blocking[HitEnt]

				if not BlockList then
					BlockList = {}
					Blocking[HitEnt] = BlockList
				end

				BlockList[#BlockList + 1] = Data

				--Debug.Line(Position, HitPos, 15, Blue, true)
			else
				-- Blocker already processed, we're permanently blocked
				Data.Processed = true
				--Debug.Line(Position, HitPos, 15, White, true)
			end

			continue
		end

		-- Direct hit on our target!
		Data.Processed = true

		local Delta         = HitPos - Position
		local Distance      = Delta:Length()
		local Direction     = Delta / Distance -- Normalize without second sqrt

		-- Inverse-square spreading: the blast wavefront is a sphere whose area grows with distance.
		-- The target catches the fraction of that wavefront its surface subtends (its solid angle),
		-- capped at 0.5 since a surface can face at most a hemisphere of the blast.
		local Sphere        = max(4 * pi * (Distance * InchToCm) ^ 2, 1) -- Wavefront area at the target (cm²)
		local EntArea       = HitEnt.ACF.Area
		local SolidAngle    = min(EntArea / Sphere, 0.5)                 -- Fraction of the wavefront caught
		local PowerFraction = Power * SolidAngle * RadiusScale            -- Blast energy intercepted (kJ)

		-- Hopkinson-Cranz cube-root scaling: the lethal radius already scales as filler^(1/3), so the
		-- scaled distance is simply Distance/Radius. The deposited blast impulse decays linearly across
		-- it and vanishes at the lethal radius (raise the exponent for a sharper near-field falloff).
		local ScaledDist    = min(Distance / Radius, 1)
		local Falloff       = 1 - ScaledDist
		local BlastArea     = EntArea * BlastAreaCoef * Falloff * RadiusScale
		local BlastResult, FragResult, Losses, Penetration

		Debug.Line(Position, HitPos, 15, Red, true)

		DmgInfo:SetHitPos(HitPos)
		DmgInfo:SetHitGroup(TraceResult.HitGroup)

		-- Measure armor face-on, along the surface normal at the impact point. The blast ray runs from
		-- the detonation to a random point on the target, so it can strike at an arbitrarily oblique
		-- angle; tracing thickness along it would inflate GeoThick by 1/cos(angle) and make penetration
		-- swing with the random sample. Direction stays radial for energy, debris and shove below.
		local SurfaceNormal = TraceResult.HitNormal
		local ThickDir      = SurfaceNormal:IsZero() and Direction or -SurfaceNormal
		local ConvexHits    = ACF.GetConvexHits(HitEnt, HitPos, ThickDir)

		-- Penetration is computed up front so the convex loop can limit how deep each layer is gouged.
		-- A blast/fragment spends penetration to cross each layer and only removes material to the depth
		-- it actually reaches, so thicker armor is genuinely protective (a thick plate loses only a
		-- shallow layer per hit) instead of cancelling out against volume-proportional convex health.
		-- Use intercepted power directly so splitting one large detonation into many small ones does
		-- not gain extra total penetration from the old concave scaling curve.
		local BlastPen = Damage.getBlastPenetration(PowerFraction * BlastArea, BlastArea)

		local FragHit  = floor(Fragments * SolidAngle)
		local FragPen  = 0

		if FragHit > 0 then
			local Loss    = BaseFragV * Distance / Radius
			local FragVel = max(BaseFragV - Loss, 0) * InchToMeter
			FragPen       = ACF.Penetration(FragVel, FragMassCalc, FragCaliber)
		end

		local BlastThickness, FragThickness, HitAngle, BlastHits, FragHits

		if #ConvexHits > 0 then
			BlastThickness, FragThickness = 0, 0
			BlastHits, FragHits = {}, {}

			local BlastLeft = BlastPen -- RHA mm of penetration remaining as we pass through each layer
			local FragLeft  = FragPen

			for _, Hit in ipairs(ConvexHits) do
				local GeoThick    = Hit.GeoThick
				local ChemicalMul = Hit.ArmorType.ChemicalMul
				local KineticMul  = Hit.ArmorType.KineticMul
				local BlastWeight = GeoThick * ChemicalMul -- RHA mm this layer costs to cross
				local FragWeight  = GeoThick * KineticMul

				BlastThickness = BlastThickness + BlastWeight
				FragThickness  = FragThickness + FragWeight

				-- Geometric depth reached into this layer (mm), capped by the layer thickness and the
				-- penetration left; crossing d mm of geometry costs d * mul of RHA penetration.
				local BlastDepth = ChemicalMul > 0 and min(GeoThick, BlastLeft / ChemicalMul) or GeoThick
				local FragDepth  = KineticMul  > 0 and min(GeoThick, FragLeft  / KineticMul)  or GeoThick

				BlastLeft = max(BlastLeft - BlastWeight, 0)
				FragLeft  = max(FragLeft  - FragWeight,  0)

				-- (mm)(mm to cm)(cm^2) = cm^3, then cm^3 to in^3
				if BlastDepth > 0 then BlastHits[#BlastHits + 1] = { ConvexID = Hit.ConvexID, Volume = BlastDepth * 0.1 * BlastArea / ACF.InchToCmCu } end
				if FragDepth  > 0 then FragHits[#FragHits + 1]   = { ConvexID = Hit.ConvexID, Volume = FragDepth  * 0.1 * FragArea  / ACF.InchToCmCu } end
			end

			HitAngle = 0 -- GeoThick is measured face-on, so there is no obliquity to apply
		else
			BlastThickness = 0
			FragThickness  = 0
			HitAngle       = ACF.GetHitAngle(TraceResult, Direction)
		end

		do -- Blast damage
			local BlastDmg = Objects.DamageResult(BlastArea, BlastPen, BlastThickness)

			DmgInfo:SetType(DMG_BLAST)
			if BlastHits then DmgInfo:SetConvexHits(BlastHits) end

			BlastResult = Damage.dealDamage(HitEnt, BlastDmg, DmgInfo)
			Losses      = BlastResult.Loss * 0.5
			Penetration = BlastPen > BlastThickness
		end

		do -- Fragment damage
			if FragHit > 0 then
				local FragDmg = Objects.DamageResult(FragArea, FragPen, FragThickness, HitAngle, nil, Fragments)

				DmgInfo:SetType(DMG_BULLET)
				if FragHits then DmgInfo:SetConvexHits(FragHits) end

				FragResult  = Damage.dealDamage(HitEnt, FragDmg, DmgInfo)
				Losses      = Losses + FragResult.Loss * 0.5
				Penetration = Penetration or (FragResult.Overkill or 0) > 0 -- TODO: Sometimes Overkill ends up being nil, but that should never be the case??
			end
		end

		do -- Killed or penetrated
			local Killed = BlastResult.Kill or (FragResult and FragResult.Kill)

			if Killed or Penetration then
				Filter[#Filter + 1] = HitEnt

				if Killed then
					local Debris = ACF.HEKill(HitEnt, Direction, PowerFraction, Position, DmgInfo)

					for Chunk in pairs(Debris) do
						if IsValid(Chunk) then Filter[#Filter + 1] = Chunk end
					end
				end

				-- Add newly-visible entities to the top of the target list
				local BlockedList = Blocking[HitEnt]

				if BlockedList then
					for _, BlockedData in ipairs(BlockedList) do
						if not BlockedData.Processed then
							TargetCount = TargetCount + 1
							TargetList[TargetCount] = BlockedData
						end
					end

					Blocking[HitEnt] = nil
				end
			elseif ACF.HEPush then
				ACF.KEShove(HitEnt, Position, Direction, PowerFraction * 33.3)
			end
		end

		Power = Power - PowerFraction * Losses
	end
end