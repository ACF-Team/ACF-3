local ACF    = ACF
local Damage = ACF.Damage
local Fire   = Damage.Fire
local Debug  = ACF.Debug

local VENT_WALL_RHA  = 10 -- mm RHA, thinner walls give way to a cookoff and count as openings
local VENT_RAYS      = 128 -- Directions surveyed around an entity, evenly spread; crates are found by aimed rays instead
local AIM_SPREAD     = 0.35 -- Rays aimed at a crate go to its middle and this share of its length either way
local VENT_RANGE     = 600 -- gmu, how far to look for walls; past it the gas is out
local RAYS_PER_TICK  = 64 -- Survey rays traced each server tick across every survey waiting, so a cookoff never stalls a tick

local DEBUG_LIFE = 6
local COLOR_WALL = Color(80, 220, 80, 120)
local COLOR_GAP  = Color(255, 70, 70)
local COLOR_OPEN = Color(80, 140, 255, 80)

local Directions = {}

do -- Evenly spread over the sphere (golden spiral)
	local Golden = math.pi * (3 - math.sqrt(5))

	for I = 0, VENT_RAYS - 1 do
		local Z = 1 - I / (VENT_RAYS - 1) * 2
		local R = math.sqrt(1 - Z * Z)

		Directions[I + 1] = Vector(math.cos(Golden * I) * R, math.sin(Golden * I) * R, Z)
	end
end

-- The vehicle's own bounding box, as no enclosure in it can be bigger
local function GetBoundingVolume(Contraption)
	local MinX, MinY, MinZ = math.huge, math.huge, math.huge
	local MaxX, MaxY, MaxZ = -math.huge, -math.huge, -math.huge

	for Ent in pairs(Contraption.ents) do
		if IsValid(Ent) then
			local Mins, Maxs = Ent:WorldSpaceAABB()

			MinX, MinY, MinZ = math.min(MinX, Mins.x), math.min(MinY, Mins.y), math.min(MinZ, Mins.z)
			MaxX, MaxY, MaxZ = math.max(MaxX, Maxs.x), math.max(MaxY, Maxs.y), math.max(MaxZ, Maxs.z)
		end
	end

	return (MaxX - MinX) * (MaxY - MinY) * (MaxZ - MinZ) * ACF.InchToMeter ^ 3
end

-- How many survey directions would reach the panel from Center if nothing stood in the way
local function CountAimedAt(Panel, Center)
	local Mins, Maxs = Panel:OBBMins(), Panel:OBBMaxs()
	local Start      = Panel:WorldToLocal(Center)
	local Count      = 0

	for _, Dir in ipairs(Directions) do
		local Delta  = Panel:WorldToLocal(Center + Dir) - Start
		local T0, T1 = 0, VENT_RANGE

		for Axis = 1, 3 do
			local From, Step = Start[Axis], Delta[Axis]

			if Step == 0 then
				if From < Mins[Axis] or From > Maxs[Axis] then T0 = T1 + 1 break end
			else
				local TA, TB = (Mins[Axis] - From) / Step, (Maxs[Axis] - From) / Step

				if TA > TB then TA, TB = TB, TA end

				T0, T1 = math.max(T0, TA), math.min(T1, TB)

				if T0 > T1 then break end
			end
		end

		if T0 <= T1 then Count = Count + 1 end
	end

	return Count
end

-- Rays aimed at the vehicle's other crates within reach, so one sharing the space is found however few directions are
-- surveyed. They only look for crates; walls, room and openings come from the even spread.
local function GetAimed(Entity, Center, Contraption)
	local Aimed = {}

	if not Contraption then return Aimed end

	for Other in pairs(Contraption.ACF_Entities or Contraption.ents) do
		if Other ~= Entity and IsValid(Other) and Other:GetClass() == "acf_ammo" then
			local Mins, Maxs = Other:OBBMins(), Other:OBBMaxs()
			local Size       = Maxs - Mins
			local Middle     = (Mins + Maxs) * 0.5
			local Along

			if Size.x >= Size.y and Size.x >= Size.z then
				Along = Vector(Size.x * AIM_SPREAD, 0, 0)
			elseif Size.y >= Size.z then
				Along = Vector(0, Size.y * AIM_SPREAD, 0)
			else
				Along = Vector(0, 0, Size.z * AIM_SPREAD)
			end

			for _, Point in ipairs({ Middle, Middle + Along, Middle - Along }) do
				local To = Other:LocalToWorld(Point) - Center

				if To:LengthSqr() < VENT_RANGE * VENT_RANGE then Aimed[#Aimed + 1] = To:GetNormalized() end
			end
		end
	end

	return Aimed
end

-- MARK: Survey jobs
-- A survey is hundreds of rays, so it's worked through a share of them each server tick rather than all at once.

local Queue = {} -- Surveys waiting, oldest first

local function Visit(Job, Result)
	local Distance = Result.HitPos:Distance(Job.Center) * ACF.InchToMeter
	local Hit      = Result.Entity

	-- Other vehicles and loose props are no part of this one's walls, and nor is anything bullets pass, such as
	-- destroyed components. The ground isn't either: a vehicle's fires stay within it.
	if not Job.Contraption or Hit:CFW_GetContraption() ~= Job.Contraption or ACF.IsInvisibleToTrace(Hit) then return end

	-- Crates racked together are one store of rounds the gas runs through, so the rack's room is all the crate's
	if Hit:GetClass() == "acf_ammo" then
		Job.Crates[Hit] = true

		return
	end

	-- Entities that hold the gas whatever their armor, such as blow-out panels until a cookoff opens them
	if Hit.ACF_HoldsGas and Hit:ACF_HoldsGas() then
		if not Job.Aiming then Job.PanelHits[Hit] = (Job.PanelHits[Hit] or 0) + 1 end
		Job.Walled, Job.Last = true, Distance

		return true
	end

	if Fire.IsStructure(Hit) then
		Job.Wall = Hit

		Damage.ForEachLayer(Hit, Result.HitPos, Job.Direction, Job.VisitLayer)
	else -- Components block like anything else, but aren't walls a breach goes through
		Job.Armor = Job.Armor + Damage.GetSolidArmor(Hit, Result.HitPos, Job.Direction)
	end

	Job.Last = Distance

	if Job.Armor >= VENT_WALL_RHA then
		Job.Walled = true

		return true
	end
end

-- Traces up to Count more of a survey's rays
local function Step(Job, Count)
	local Center = Job.Center
	local Share  = 4 * math.pi / VENT_RAYS -- Steradians each direction stands for
	local Draw   = Debug.SetDeveloperLevel(1)

	for _ = 1, Count do
		local Index  = Job.Next
		local Aiming = Index > VENT_RAYS
		local Dir    = Aiming and Job.Aimed[Index - VENT_RAYS] or Directions[Index]

		if not Dir then return true end

		Job.Next = Index + 1
		Job.Direction, Job.Armor, Job.Walled, Job.Last, Job.Aiming = Dir, 0, false, nil, Aiming

		Damage.PierceLine(Center, Center + Dir * VENT_RANGE, Job.Ignore, Job.VisitHit, true)

		if Draw then
			local Length = Job.Last and Job.Last / ACF.InchToMeter or VENT_RANGE

			Debug.Line(Center, Center + Dir * Length, DEBUG_LIFE, Job.Walled and COLOR_WALL or Job.Last and COLOR_GAP or COLOR_OPEN)
		end

		if Aiming then -- Only looking for crates
		elseif Job.Walled then
			Job.Walls   = Job.Walls + 1
			Job.WallSum = Job.WallSum + Job.Last
			Job.Volume  = Job.Volume + Share * Job.Last ^ 3 / 3
		elseif Job.Last then
			Job.Vent = Job.Vent + Share * Job.Last ^ 2 -- Cone of the opening where the gas leaves
		else
			Job.Free = Job.Free + 1
		end
	end

	return Job.Next > VENT_RAYS + #Job.Aimed
end

local function Finish(Job)
	local Share = 4 * math.pi / VENT_RAYS

	-- Directions that met nothing are gaps in the walls, as big as the walls are far away. The fewer directions are
	-- walled, the less of an enclosure there is, so the gaps grow with it: twice the area with half the directions
	-- open, and as far as the survey looks once none are walled, with no point where it jumps.
	local RangeSq = (VENT_RANGE * ACF.InchToMeter) ^ 2
	local Open    = Job.Free / VENT_RAYS
	local ReachSq = Job.Walls > 0 and math.min((Job.WallSum / Job.Walls) ^ 2 / (1 - Open), RangeSq) or RangeSq

	Job.Vent = Job.Vent + Job.Free * Share * ReachSq

	if Job.Contraption then Job.Volume = math.min(Job.Volume, GetBoundingVolume(Job.Contraption)) end

	if Debug.SetDeveloperLevel(1) then Debug.Text(Job.Center, ("Survey: vent %.3f m², volume %.2f m³"):format(Job.Vent, Job.Volume), DEBUG_LIFE) end

	local WallList = {}

	for _, Entry in pairs(Job.Boundary) do
		WallList[#WallList + 1] = Entry
	end

	-- A panel's reach is the share of the rays aimed at it that got there
	local PanelReach = {}

	for Panel, Hits in pairs(Job.PanelHits) do
		if IsValid(Panel) then PanelReach[Panel] = math.min(Hits / math.max(CountAimedAt(Panel, Job.Center), 1), 1) end
	end

	Job.WallList   = WallList
	Job.CrateList  = table.GetKeys(Job.Crates)
	Job.PanelReach = PanelReach
	Job.Done       = true

	if Job.Callback then Job.Callback(Job) end
end

local function CreateJob(Entity, Callback)
	local Job = {
		Entity      = Entity,
		Center      = Entity:WorldSpaceCenter(),
		Contraption = Entity:CFW_GetContraption(),
		Ignore      = { Entity },
		Callback    = Callback,
		Aimed       = GetAimed(Entity, Entity:WorldSpaceCenter(), Entity:CFW_GetContraption()),
		Next        = 1,
		Vent        = 0,
		Volume      = 0,
		Walls       = 0, -- Rays that hit a wall, how far altogether, and rays that met nothing at all
		WallSum     = 0,
		Free        = 0,
		Boundary    = {}, -- Boundary[Convex] = { Entity, Convex, LocalExit }
		Crates      = {}, -- Crates[Entity] = true, the vehicle's other ammo crates inside the walls
		PanelHits   = {}, -- PanelHits[Panel] = rays that ended on it
	}

	function Job.VisitHit(Result) return Visit(Job, Result) end

	function Job.VisitLayer(Layer, Convex)
		Job.Armor = Job.Armor + Layer.GeoThick * Layer.ArmorType.KineticMul

		if Job.Boundary[Convex] then return end

		local Exit = Layer.EntryPos + Job.Direction * (Layer.GeoThick * ACF.MmToInch + 1)

		Job.Boundary[Convex] = { Entity = Job.Wall, Convex = Convex, LocalExit = Job.Wall:WorldToLocal(Exit) }
	end

	return Job
end

--- Surveys the walls around an entity: what its gas can escape through, and how much room it has.
--- Only the vehicle's own armor and the edge of its own volume count as walls; thin plates and its other parts don't
--- hold gas, so a crate in a hull has the whole hull around it, and other ammo crates don't even block it, so a crate
--- in a rack has the rack's whole compartment. The vehicle's other crates are found by rays aimed at each of them. Holes shot through the walls aren't counted here: they're breaches,
--- returned with the walls for the cookoff to weigh as they open. The survey is traced over the next few server
--- ticks; Callback is called with the finished survey.
--- @param Entity entity The entity to survey around.
--- @return table # The survey; once Done, it holds Vent (m² of openings to the outside), Volume (m³ around the entity,
--- capped at its vehicle's bounding box), WallList (the armor around it, one { Entity, Convex, LocalExit } per convex,
--- LocalExit just past it), CrateList (the vehicle's other ammo crates sharing the space) and PanelReach
--- ({ [Panel] = share of the panel the gas reaches } for the blow-out panels its rays found).
function Fire.QueueSurvey(Entity, Callback)
	local Job = CreateJob(Entity, Callback)

	Queue[#Queue + 1] = Job

	return Job
end

--- Surveys around an entity at once, see Fire.QueueSurvey.
--- @return number # Vent
--- @return number # Volume
--- @return table # WallList
--- @return table # CrateList
--- @return table # PanelReach
function Fire.SurveyEnclosure(Entity)
	local Job = CreateJob(Entity)

	Step(Job, VENT_RAYS + #Job.Aimed)
	Finish(Job)

	return Job.Vent, Job.Volume, Job.WallList, Job.CrateList, Job.PanelReach
end

hook.Add("Think", "ACF_FireSurveys", function()
	local Budget = RAYS_PER_TICK

	while Budget > 0 and Queue[1] do
		local Job = Queue[1]

		if not IsValid(Job.Entity) then
			table.remove(Queue, 1)
		else
			local Before = Job.Next

			if Step(Job, Budget) then
				table.remove(Queue, 1)

				-- Hooks keep running after an error, but whoever waits on the survey has to hear it's over either way
				if not xpcall(Finish, ErrorNoHaltWithStack, Job) and not Job.Done then
					Job.Vent, Job.Volume, Job.WallList, Job.CrateList, Job.PanelReach = 0, 0, {}, {}, {}
					Job.Done = true

					if Job.Callback then xpcall(Job.Callback, ErrorNoHaltWithStack, Job) end
				end
			end

			Budget = Budget - (Job.Next - Before)
		end
	end
end)
