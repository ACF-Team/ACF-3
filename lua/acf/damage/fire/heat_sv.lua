local ACF     = ACF
local Damage  = ACF.Damage
local Fire    = Damage.Fire
local Classes = ACF.Classes
local Debug   = ACF.Debug
local min     = math.min
local max     = math.max
local pi      = math.pi
local random  = math.random

local SIGMA            = 5.67e-8 -- Stefan-Boltzmann constant, W/m²/K⁴
local AMBIENT          = 293 -- K
local RADIANT_FRACTION = 0.3 -- Share of a fire's heat radiated, as for a sooty fuel fire treated as a point source
local MIN_FLUX         = 1000 -- W/m², heat below this is ignored, which bounds how far a fire reaches
local MAX_FLUX         = 100e3 -- W/m², about what an engulfing fuel fire puts on a surface
local WALL_EMISSIVITY  = 0.8 -- Oxidized steel; how well a heated wall radiates from its far side
local DOSE_HALF_LIFE   = 300 -- Seconds for a component to cool off; caps the dose at flux x 433 s, so it must reach the ignition doses
local JET_HALF_ANGLE   = 45 -- Degrees a jet of flame through a breach spreads out from its axis; wide enough to reach most of a crew space
local JET_COS          = math.cos(math.rad(JET_HALF_ANGLE))
local JET_SOLID_ANGLE  = 2 * pi * (1 - JET_COS) -- Steradians the jet's heat is spread over
local JET_MAX_RANGE    = 240 -- gmu a jet of flame reaches, however hot; its heat would otherwise carry across the map
local PATH_RAYS        = 8 -- Lines kept between a fire and each entity it radiates onto, each solved again only where something on it moved
local PATH_BUDGET      = 12 -- Lines a vehicle may solve each server tick, new or brought up to date, however many of its fires burn in it
local PATH_CHECKS      = 256 -- Lines a vehicle may look over each server tick for something moved on them
local MIN_LAYER_MM     = 1 -- mm, the thinnest crossing of a convex that counts as a wall, as for bullets

local DEBUG_TICK_LIFE  = ACF.FireTickRate * 1.2 -- Just over a fire tick, so drawings refreshed every tick stay up
local DEBUG_JET_LENGTH = 120 -- gmu of a jet's cone drawn, however far its heat reaches
local COLOR_JET        = Color(255, 100, 0)
local COLOR_HOT        = Color(255, 60, 60)
local COLOR_WARM       = Color(255, 200, 120)

Fire.MaxFlux = MAX_FLUX

-- Kept across reloads so hot walls survive a refresh of this file
Fire.HotWalls = Fire.HotWalls or {} -- HotWalls[Convex] = Entity, for convexes warmer than ambient

do -- MARK: Heat dose and damage
	--- Adds heat to an entity's dose, letting whatever it built up before cool off first.
	--- @return number # The entity's accumulated dose in J/m².
	function Fire.AddHeatDose(Entity, Flux, DeltaTime)
		local Now  = CurTime()
		local Dose = (Entity.ACF_HeatDose or 0) * 0.5 ^ ((Now - (Entity.ACF_HeatDoseTime or Now)) / DOSE_HALF_LIFE)

		Dose = Dose + Flux * DeltaTime

		Entity.ACF_HeatDose     = Dose
		Entity.ACF_HeatDoseTime = Now

		return Dose
	end

	--- Slowly wears down a component sitting in more heat than it can take.
	function Fire.DamageComponent(Entity, Flux, DeltaTime)
		local Excess = Flux - ACF.FireContactFlux
		local EntACF = Entity.ACF

		if Excess <= 0 or not EntACF or not EntACF.MaxHealth or EntACF.Health <= 0 then return end

		EntACF.Health = max(EntACF.Health - EntACF.MaxHealth * ACF.FireDamageRate * Excess * 1e-5 * DeltaTime, 0)

		if Entity.ACF_OnHeatDamage then Entity:ACF_OnHeatDamage() end

		ACF.RefreshCondition(Entity)
	end
end

do -- MARK: Hot walls
	local HeatCapacities = {} -- J/m³/K per material

	local function GetHeatCapacity(Material)
		local Capacity = HeatCapacities[Material]

		if Capacity then return Capacity end

		local ArmorType = Classes.GetSubtypeByName("ACF.ArmorTypes.BaseArmorType", "ACF.ArmorTypes." .. tostring(Material))

		Capacity = ArmorType and ArmorType.Density * 1000 * ArmorType.SpecificHeat or 3.9e6

		HeatCapacities[Material] = Capacity

		return Capacity
	end

	--- @return number # W/m² a heated wall radiates from its far side.
	function Fire.GetWallEmission(Convex)
		local Temp = Convex.FireTemp or AMBIENT

		return WALL_EMISSIVITY * SIGMA * (Temp ^ 4 - AMBIENT ^ 4)
	end

	--- Lumped heating of each wall a fire reached, across its thickness, losing heat by radiating it back out.
	function Fire.UpdateWalls(DeltaTime)
		local HotWalls = Fire.HotWalls
		local Draw     = Debug.SetDeveloperLevel(2)

		for Convex, Entity in pairs(HotWalls) do
			if not IsValid(Entity) then
				HotWalls[Convex] = nil
			else
				local Incident = Convex.FireIncident or 0
				local Temp     = Convex.FireTemp or AMBIENT
				local Capacity = GetHeatCapacity(Convex.Material) * max(Convex.MinWidth * ACF.InchToMeter, 0.001) -- J/m²/K
				local Balance  = (Incident / SIGMA + AMBIENT ^ 4) ^ 0.25
				local Absorbed = WALL_EMISSIVITY * (Incident - SIGMA * (Temp ^ 4 - AMBIENT ^ 4))
				local NewTemp  = Temp + Absorbed * DeltaTime / Capacity

				-- Thin walls would overshoot within a tick, never pass the temperature they settle at
				NewTemp = Temp < Balance and min(NewTemp, Balance) or max(NewTemp, Balance)

				Convex.FireIncident = nil
				Convex.FireTemp     = NewTemp

				if Draw then Debug.Text(Entity:LocalToWorld(Convex.Centroid), ("%d K"):format(NewTemp), DEBUG_TICK_LIFE) end

				-- Radiating less than the heat that counts anywhere, a cooling wall can't heat anything and is done
				if Incident <= 0 and Fire.GetWallEmission(Convex) < MIN_FLUX then
					Convex.FireTemp = nil

					HotWalls[Convex] = nil
				end
			end
		end
	end
end

do -- MARK: Structure
	local StructureClasses = { -- ACF entities that are the vehicle's structure rather than components in it
		acf_baseplate      = true,
		acf_turret         = true,
		acf_turret_rotator = true,
	}

	--- @return boolean # Whether the entity is part of the vehicle's structure, armor included, rather than a component.
	--- Structure isn't heated like components are, and is what walls fires and cookoffs in.
	function Fire.IsStructure(Entity)
		return not Entity.IsACFEntity or StructureClasses[Entity:GetClass()] == true
	end
end

do -- MARK: Heat transport
	-- What a line of heat crosses inside a vehicle only changes when the vehicle does, so the lines between a fire and
	-- each entity it heats are kept, and only where something on them moved are they solved again: every tick just walks
	-- the walls on them, reading their holes and temperatures as they are now. Only the vehicle's own parts are walls;
	-- the ground and other vehicles are ignored.

	local function RandomPoint(Entity)
		local Mins, Maxs = Entity:OBBMins(), Entity:OBBMaxs()
		local Center     = (Mins + Maxs) * 0.5
		local Point      = Vector(math.Rand(Mins.x, Maxs.x), math.Rand(Mins.y, Maxs.y), math.Rand(Mins.z, Maxs.z))

		return Entity:LocalToWorld(Center + (Point - Center) * 0.8)
	end

	local function IsHeated(Entity)
		return Entity.ACF_OnHeat ~= nil or not Fire.IsStructure(Entity)
	end

	-- Checked before any line is traced, so a jet costs nothing for what it isn't pointed at.
	-- Any part of the target in the cone counts, not just its middle, as large models reach well into it.
	local function IsInCone(Origin, Axis, Target)
		local ToTarget = Target:WorldSpaceCenter() - Origin
		local Distance = ToTarget:Length()
		local Radius   = Target:BoundingRadius()

		if Distance <= Radius then return true end

		local OffAxis = math.acos(math.Clamp(ToTarget:Dot(Axis) / Distance, -1, 1))

		return OffAxis - math.asin(Radius / Distance) <= math.rad(JET_HALF_ANGLE)
	end

	local function DrawJet(Origin, Axis, HeatRelease)
		local Angles = Axis:Angle()
		local Right  = Angles:Right()
		local Up     = Angles:Up()
		local Tip    = Origin + Axis * DEBUG_JET_LENGTH
		local Radius = DEBUG_JET_LENGTH * math.tan(math.rad(JET_HALF_ANGLE))
		local Last

		Debug.Line(Origin, Tip, DEBUG_TICK_LIFE, COLOR_JET)

		for I = 0, 8 do
			local Turn = I / 8 * 2 * pi
			local Rim  = Tip + (Right * math.cos(Turn) + Up * math.sin(Turn)) * Radius

			if I < 8 then Debug.Line(Origin, Rim, DEBUG_TICK_LIFE, COLOR_JET) end
			if Last then Debug.Line(Last, Rim, DEBUG_TICK_LIFE, COLOR_JET) end

			Last = Rim
		end

		Debug.Text(Origin, ("Jet %d kW"):format(HeatRelease / 1000), DEBUG_TICK_LIFE)
	end

	-- MARK: Moving parts
	-- Turrets turn their rotator about one axis through its origin: a horizontal drive in yaw (local Z), a vertical
	-- drive in pitch (local Y), each within its arc. What a rotator carries can only reach the volume it sweeps that way,
	-- so a line passing nowhere near it can't be changed by it turning. Actuators move in ways nothing describes, so
	-- every line depends on them.

	local SWEEP_STEP = math.rad(15) -- Radians between the positions an arc is followed at; each is padded to cover the gap

	-- Radial and axial coordinates of a point local to a mover, about its axis
	local function Split(Pos, Axis)
		if Axis == 3 then return Pos.x, Pos.y, Pos.z end

		return Pos.x, Pos.z, Pos.y
	end

	local function Turn(Pos, Axis, Angle)
		local C, S = math.cos(Angle), math.sin(Angle)

		if Axis == 3 then return Vector(Pos.x * C - Pos.y * S, Pos.x * S + Pos.y * C, Pos.z) end

		return Vector(Pos.x * C - Pos.z * S, Pos.y, Pos.x * S + Pos.z * C)
	end

	local function IsMover(Entity)
		local Class = Entity:GetClass()

		return Class == "acf_turret_rotator" or Class == "acf_actuator_rod"
	end

	-- The rotation a rotator can still make from where it is, in radians, as Turn counts it. Elevation is the
	-- negative of pitch; which way a traverse arc counts is left open by taking it both ways round.
	local function GetReach(Mover, Axis)
		local Turret = Mover.Turret

		if not (IsValid(Turret) and Turret.HasArc) then return end

		local Angles = Mover:GetLocalAngles()

		if Axis == 2 then return math.rad(Angles.p + Turret.MinDeg), math.rad(Angles.p + Turret.MaxDeg) end

		return math.rad(min(Turret.MinDeg, -Turret.MaxDeg) - Angles.y), math.rad(max(Turret.MaxDeg, -Turret.MinDeg) - Angles.y)
	end

	local Corners = {}

	for I = 0, 7 do Corners[I + 1] = { bit.band(I, 1) > 0, bit.band(I, 2) > 0, bit.band(I, 4) > 0 } end

	-- Turning through half a turn or more, a rotator's arc is taken as the whole turn: following every step of it
	-- costs far more than the little of the sweep it would leave out
	local function GetArc(Mover, Axis)
		local Low, High = GetReach(Mover, Axis)

		if Low and High - Low < pi then return Low, High end
	end

	local function GetAxis(Mover)
		local Turret = Mover.Turret

		return IsValid(Turret) and Turret.ID == "Turret-V" and 2 or 3
	end

	-- The corners of an entity's box, local to Frame
	local function GetCorners(Entity, Frame)
		local Mins, Maxs = Entity:OBBMins(), Entity:OBBMaxs()
		local Points     = {}

		for I, Corner in ipairs(Corners) do
			Points[I] = Frame:WorldToLocal(Entity:LocalToWorld(Vector(Corner[1] and Maxs.x or Mins.x, Corner[2] and Maxs.y or Mins.y, Corner[3] and Maxs.z or Mins.z)))
		end

		return Points
	end

	-- Spheres local to Frame covering an entity's box; long or wide parts get several, so a gun barrel isn't one
	-- sphere as wide as it's long
	local function GetSpheres(Entity, Frame, Spheres)
		local Mins, Maxs = Entity:OBBMins(), Entity:OBBMaxs()
		local Size       = Maxs - Mins
		local Cell       = max(max(Size.x, Size.y, Size.z) / 6, min(Size.x, Size.y, Size.z), 1)
		local NX, NY, NZ = math.Clamp(math.ceil(Size.x / Cell), 1, 6), math.Clamp(math.ceil(Size.y / Cell), 1, 6), math.Clamp(math.ceil(Size.z / Cell), 1, 6)
		local Step       = Vector(Size.x / NX, Size.y / NY, Size.z / NZ)
		local Radius     = Step:Length() * 0.5

		for X = 1, NX do
			for Y = 1, NY do
				for Z = 1, NZ do
					local Local = Mins + Vector(Step.x * (X - 0.5), Step.y * (Y - 0.5), Step.z * (Z - 0.5))

					Spheres[#Spheres + 1] = { Center = Frame:WorldToLocal(Entity:LocalToWorld(Local)), Radius = Radius }
				end
			end
		end
	end

	local GetArcSpheres

	-- A mover turning all the way round keeps everything it carries within one sphere around its pivot, as far out as
	-- its parts reach; few enough of them sit far from their pivot for that to be close
	local function GetPivotRadius(Mover)
		local Origin = Mover:GetPos()
		local Radius = 0

		local function Walk(Entity)
			for Key, Value in pairs(Entity:GetChildren()) do
				local Child = isnumber(Key) and Value or Key

				if IsValid(Child) then
					local Mins, Maxs = Child:OBBMins(), Child:OBBMaxs()

					for _, Corner in ipairs(Corners) do
						local Point = Child:LocalToWorld(Vector(Corner[1] and Maxs.x or Mins.x, Corner[2] and Maxs.y or Mins.y, Corner[3] and Maxs.z or Mins.z))

						Radius = max(Radius, Point:Distance(Origin))
					end

					Walk(Child)
				end
			end
		end

		Walk(Mover)

		return Radius
	end

	-- What a moving part further down can take its parts to: one sphere around it if it turns all the way round,
	-- or the spheres following its parts round its arc. Local to its parent.
	local function GetNestedSpheres(Mover)
		local Parent = Mover:GetMoveParent()

		if Mover:GetClass() ~= "acf_actuator_rod" and IsValid(Parent) and not GetArc(Mover, GetAxis(Mover)) then
			return { { Center = Parent:WorldToLocal(Mover:GetPos()), Radius = GetPivotRadius(Mover) } }, Parent, false
		end

		return GetArcSpheres(Mover)
	end

	-- What a mover carries, local to it: the parts it holds directly as their boxes' corners, and those further down
	-- moving parts as spheres wherever those can take them
	local function GetCarried(Mover)
		local Boxes, Spheres, Anywhere = {}, {}, false

		local function Walk(Entity)
			for Key, Value in pairs(Entity:GetChildren()) do
				local Child = isnumber(Key) and Value or Key -- A list or a set, depending on who built it

				if IsValid(Child) then
					if IsMover(Child) then
						local Arc, Parent, ChildAnywhere = GetNestedSpheres(Child)

						Anywhere = Anywhere or ChildAnywhere

						for _, Sphere in ipairs(Arc) do
							Spheres[#Spheres + 1] = { Center = Mover:WorldToLocal(Parent:LocalToWorld(Sphere.Center)), Radius = Sphere.Radius }
						end
					else
						Boxes[#Boxes + 1] = GetCorners(Child, Mover)

						Walk(Child)
					end
				end
			end
		end

		Walk(Mover)

		return Boxes, Spheres, Anywhere
	end

	-- Spheres local to the mover's parent covering everything it carries at every angle it can reach, for a mover
	-- carrying this one. Each position followed is padded by how far a part strays from it before the next.
	function GetArcSpheres(Mover)
		local Parent = Mover:GetMoveParent()

		if Mover:GetClass() == "acf_actuator_rod" or not IsValid(Parent) then return {}, Parent, true end

		local Axis      = GetAxis(Mover)
		local Low, High = GetArc(Mover, Axis)
		local Carried   = {}
		local Anywhere  = false

		if not Low then Low, High = -pi, pi end

		local function Walk(Entity)
			for Key, Value in pairs(Entity:GetChildren()) do
				local Child = isnumber(Key) and Value or Key

				if IsValid(Child) then
					if IsMover(Child) then
						local Arc, ChildParent, ChildAnywhere = GetNestedSpheres(Child)

						Anywhere = Anywhere or ChildAnywhere

						for _, Sphere in ipairs(Arc) do
							Carried[#Carried + 1] = { Center = Mover:WorldToLocal(ChildParent:LocalToWorld(Sphere.Center)), Radius = Sphere.Radius }
						end
					else
						GetSpheres(Child, Mover, Carried)
						Walk(Child)
					end
				end
			end
		end

		Walk(Mover)

		local Steps   = math.max(math.ceil((High - Low) / SWEEP_STEP), 1)
		local Step    = (High - Low) / Steps
		local Spheres = {}

		for _, Sphere in ipairs(Carried) do
			local U, V = Split(Sphere.Center, Axis)
			local Pad  = 2 * math.sqrt(U * U + V * V) * math.sin(Step / 4) -- Furthest the part gets from the nearest position followed

			for I = 0, Steps do
				Spheres[#Spheres + 1] = { Center = Parent:WorldToLocal(Mover:LocalToWorld(Turn(Sphere.Center, Axis, Low + Step * I))), Radius = Sphere.Radius + Pad }
			end
		end

		return Spheres, Parent, Anywhere
	end

	-- A rotator's sweep. Turning all the way round, it's one band per part about its axis: how far from the axis and
	-- along it the part reaches. Turning through an arc, it's the spheres following its parts round that arc.
	local function GetSweep(Mover)
		if Mover:GetClass() == "acf_actuator_rod" then return { Entity = Mover, Anywhere = true } end

		local Axis  = GetAxis(Mover)
		local Sweep = { Entity = Mover, Axis = Axis }

		if GetArc(Mover, Axis) then
			local Spheres, Parent, Anywhere = GetArcSpheres(Mover)

			Sweep.Spheres, Sweep.Parent, Sweep.Anywhere = Spheres, Parent, Anywhere

			return Sweep
		end

		local Boxes, Spheres, Anywhere = GetCarried(Mover)
		local Bands = {}

		for _, Points in ipairs(Boxes) do
			local MaxR, MinW, MaxW = 0, math.huge, -math.huge
			local MinU, MaxU, MinV, MaxV = math.huge, -math.huge, math.huge, -math.huge

			for _, Point in ipairs(Points) do
				local U, V, W = Split(Point, Axis)

				MaxR = max(MaxR, U * U + V * V)
				MinW, MaxW = min(MinW, W), max(MaxW, W)
				MinU, MaxU = min(MinU, U), max(MaxU, U)
				MinV, MaxV = min(MinV, V), max(MaxV, V)
			end

			-- Nearest the axis no closer than the box seen down the axis allows
			local DU, DV = max(MinU, 0, -MaxU), max(MinV, 0, -MaxV)

			Bands[#Bands + 1] = { MinR = math.sqrt(DU * DU + DV * DV), R = math.sqrt(MaxR), MinW = MinW, MaxW = MaxW }
		end

		for _, Sphere in ipairs(Spheres) do
			local U, V, W = Split(Sphere.Center, Axis)
			local Radial  = math.sqrt(U * U + V * V)

			Bands[#Bands + 1] = { MinR = max(Radial - Sphere.Radius, 0), R = Radial + Sphere.Radius, MinW = W - Sphere.Radius, MaxW = W + Sphere.Radius }
		end

		Sweep.Bands, Sweep.Anywhere = Bands, Anywhere

		return Sweep
	end

	-- Squared distance from a point to a segment, all in plain numbers so following an arc makes no garbage
	local function SegmentNearPoint(X0, Y0, Z0, DX, DY, DZ, Length, CX, CY, CZ)
		local T = Length > 0 and math.Clamp(((CX - X0) * DX + (CY - Y0) * DY + (CZ - Z0) * DZ) / Length, 0, 1) or 0
		local X, Y, Z = X0 + DX * T - CX, Y0 + DY * T - CY, Z0 + DZ * T - CZ

		return X * X + Y * Y + Z * Z
	end

	-- Whether a world segment passes through what the mover's turning can reach
	local function SegmentHitsSweep(Sweep, Start, Finish)
		if Sweep.Anywhere then return true end

		if Sweep.Bands then
			local Mover            = Sweep.Entity
			local U0, V0, W0       = Split(Mover:WorldToLocal(Start), Sweep.Axis)
			local U1, V1, W1       = Split(Mover:WorldToLocal(Finish), Sweep.Axis)
			local DU, DV, DW       = U1 - U0, V1 - V0, W1 - W0
			local Length           = DU * DU + DV * DV

			for _, Band in ipairs(Sweep.Bands) do
				local T0, T1 = 0, 1

				if DW == 0 then
					if W0 < Band.MinW or W0 > Band.MaxW then T0 = 2 end
				else
					local TA, TB = (Band.MinW - W0) / DW, (Band.MaxW - W0) / DW

					if TA > TB then TA, TB = TB, TA end

					T0, T1 = max(T0, TA), min(T1, TB)
				end

				-- Distance from the axis along the part of the segment within the band's height rises away from its
				-- nearest point, so it spans from there to the further end of that part
				if T0 <= T1 then
					local T      = Length > 0 and math.Clamp(-(U0 * DU + V0 * DV) / Length, T0, T1) or T0
					local Near   = (U0 + DU * T) ^ 2 + (V0 + DV * T) ^ 2
					local Far    = max((U0 + DU * T0) ^ 2 + (V0 + DV * T0) ^ 2, (U0 + DU * T1) ^ 2 + (V0 + DV * T1) ^ 2)

					if Near <= Band.R * Band.R and Far >= Band.MinR * Band.MinR then return true end
				end
			end

			return false
		end

		local Parent = Sweep.Parent

		if not IsValid(Parent) then return true end

		local X0, Y0, Z0 = Parent:WorldToLocal(Start):Unpack()
		local X1, Y1, Z1 = Parent:WorldToLocal(Finish):Unpack()
		local DX, DY, DZ = X1 - X0, Y1 - Y0, Z1 - Z0
		local Length     = DX * DX + DY * DY + DZ * DZ

		for _, Sphere in ipairs(Sweep.Spheres) do
			local Center = Sphere.Center

			if SegmentNearPoint(X0, Y0, Z0, DX, DY, DZ, Length, Center.x, Center.y, Center.z) <= Sphere.Radius * Sphere.Radius then return true end
		end

		return false
	end

	local function Carries(Mover, Entity)
		local Ancestor = Entity:GetMoveParent()

		while IsValid(Ancestor) do
			if Ancestor == Mover then return true end

			Ancestor = Ancestor:GetMoveParent()
		end

		return false
	end

	-- A line carried round by a mover sweeps a ring about its axis; it can come to cross any part the mover doesn't
	-- carry within that ring. Those parts' boxes are measured about the axis, which the mover's own turning leaves
	-- alone, so they're only measured again once Key, standing for where everything it doesn't carry sits, changes.
	local function SweepHitsOthers(Cache, Sweep, Start, Finish, Key)
		if Sweep.Anywhere then return true end

		local Mover  = Sweep.Entity
		local Axis   = Sweep.Axis
		local Others = Sweep.Others

		if Sweep.OthersKey ~= Key then
			Others = {}

			-- Each box from its centre and half-axes in the mover's frame: along any of the mover's axes it reaches the
			-- centre plus the half-axes' lengths along it, without transforming its eight corners one by one
			local OX, OY, OZ = Mover:GetPos():Unpack()
			local FX, FY, FZ = Mover:GetForward():Unpack()
			local LX, LY, LZ = (-Mover:GetRight()):Unpack()
			local UX, UY, UZ = Mover:GetUp():Unpack()

			for Entity in pairs(Cache.Contraption.ents) do
				if IsValid(Entity) and Entity ~= Mover and not Carries(Mover, Entity) then
					local Mins, Maxs = Entity:OBBMins(), Entity:OBBMaxs()
					local CX, CY, CZ = Entity:LocalToWorld((Mins + Maxs) * 0.5):Unpack()
					local HX, HY, HZ = (Maxs.x - Mins.x) * 0.5, (Maxs.y - Mins.y) * 0.5, (Maxs.z - Mins.z) * 0.5
					local AX, AY, AZ = Entity:GetForward():Unpack()
					local BX, BY, BZ = Entity:GetRight():Unpack()
					local EX, EY, EZ = Entity:GetUp():Unpack()

					CX, CY, CZ = CX - OX, CY - OY, CZ - OZ

					local function Along(X, Y, Z)
						return CX * X + CY * Y + CZ * Z, HX * math.abs(AX * X + AY * Y + AZ * Z) + HY * math.abs(BX * X + BY * Y + BZ * Z) + HZ * math.abs(EX * X + EY * Y + EZ * Z)
					end

					local PX, RX = Along(FX, FY, FZ)
					local PY, RY = Along(LX, LY, LZ)
					local PZ, RZ = Along(UX, UY, UZ)
					local PU, PV, PW, RU, RV, RW

					if Axis == 3 then
						PU, PV, PW, RU, RV, RW = PX, PY, PZ, RX, RY, RZ
					else
						PU, PV, PW, RU, RV, RW = PX, PZ, PY, RX, RZ, RY
					end

					-- Nearest the axis no closer than the box seen down the axis allows, furthest no further than its corner
					local DU = max(math.abs(PU) - RU, 0)
					local DV = max(math.abs(PV) - RV, 0)
					local FU = math.abs(PU) + RU
					local FV = math.abs(PV) + RV

					Others[#Others + 1] = { MinR = math.sqrt(DU * DU + DV * DV), MaxR = math.sqrt(FU * FU + FV * FV), MinW = PW - RW, MaxW = PW + RW }
				end
			end

			Sweep.Others, Sweep.OthersKey = Others, Key
		end

		local U0, V0, W0 = Split(Mover:WorldToLocal(Start), Axis)
		local U1, V1, W1 = Split(Mover:WorldToLocal(Finish), Axis)
		local DU, DV     = U1 - U0, V1 - V0
		local Length     = DU * DU + DV * DV
		local T          = Length > 0 and math.Clamp(-(U0 * DU + V0 * DV) / Length, 0, 1) or 0
		local MinR       = math.sqrt((U0 + DU * T) ^ 2 + (V0 + DV * T) ^ 2)
		local MaxR       = math.sqrt(max(U0 * U0 + V0 * V0, U1 * U1 + V1 * V1))
		local MinW, MaxW = min(W0, W1), max(W0, W1)

		for _, Other in ipairs(Others) do
			if Other.MaxW >= MinW and Other.MinW <= MaxW and Other.MaxR >= MinR and Other.MinR <= MaxR then return true end
		end

		return false
	end

	-- MARK: Rigid groups
	-- Parts that never move against each other make a group: what a rotator or actuator carries, down to the next one,
	-- and what sits on the vehicle's base. Every part's box and its convexes' faces are kept in its group's frame, so
	-- where a line crosses a group is worked out in plain numbers wherever the group has turned to, without tracing.
	-- A group's version counts its moves against the group it's on, so a line knows when what it crossed has moved.

	local BOX_PAD   = 0.5 -- gmu; boxes only pick what's solved exactly, so they're padded to never drop a crossing to float error
	local NO_LAYERS = {}

	-- The entity a part moves with: its nearest moving ancestor, or the top of its parent chain
	local function GetGroupRoot(Entity)
		if IsMover(Entity) then return Entity end

		local Up = Entity

		while true do
			local Parent = Up:GetMoveParent()

			if not IsValid(Parent) then return Up end
			if IsMover(Parent) then return Parent end

			Up = Parent
		end
	end

	-- Where a group sits on the group it's on
	local function GetGroupPose(Cache, Group)
		local Root = Group.Root

		if IsMover(Root) and IsValid(Root:GetMoveParent()) then return Root:GetLocalPos(), Root:GetLocalAngles() end

		local Main = Cache.MainRoot

		return WorldToLocal(Root:GetPos(), Root:GetAngles(), Main:GetPos(), Main:GetAngles())
	end

	local function GroupFor(Cache, Entity)
		local Root  = GetGroupRoot(Entity)
		local Group = Cache.Groups[Root]

		if Group then return Group end

		Group = {
			Root    = Root,
			Parts   = {},
			Version = 0,
			Chain   = {}, -- Chain[Group] = true for it and every group it's on
			Sweep   = Cache.Sweeps[Root],
			MinX    = math.huge, MinY = math.huge, MinZ = math.huge,
			MaxX    = -math.huge, MaxY = -math.huge, MaxZ = -math.huge,
		}

		Cache.Groups[Root] = Group

		if Root ~= Cache.MainRoot then
			local Parent = IsMover(Root) and Root:GetMoveParent()

			Group.Parent = GroupFor(Cache, IsValid(Parent) and Parent or Cache.MainRoot)
			Group.Pos, Group.Ang = GetGroupPose(Cache, Group)

			for Member in pairs(Group.Parent.Chain) do Group.Chain[Member] = true end
		end

		Group.Chain[Group] = true

		return Group
	end

	-- Each face of a convex as a plane facing out, local to its entity, four numbers a face
	local function GetPlanes(Convex)
		local Planes = {}

		for _, Tri in ipairs(Convex.Tris) do
			local A, B, C    = Tri[1], Tri[2], Tri[3]
			local AX, AY, AZ = A.x, A.y, A.z
			local UX, UY, UZ = C.x - AX, C.y - AY, C.z - AZ
			local VX, VY, VZ = B.x - AX, B.y - AY, B.z - AZ
			local NX, NY, NZ = UY * VZ - UZ * VY, UZ * VX - UX * VZ, UX * VY - UY * VX -- (C - A) x (B - A), outward as GetMeshConvexes winds them
			local Length     = math.sqrt(NX * NX + NY * NY + NZ * NZ)

			if Length > 0 then
				local Count = #Planes

				NX, NY, NZ = NX / Length, NY / Length, NZ / Length

				Planes[Count + 1], Planes[Count + 2], Planes[Count + 3], Planes[Count + 4] = NX, NY, NZ, NX * AX + NY * AY + NZ * AZ
			end
		end

		return Planes
	end

	local function SetBox(Box, Mins, Maxs)
		Box.MinX, Box.MinY, Box.MinZ = Mins.x - BOX_PAD, Mins.y - BOX_PAD, Mins.z - BOX_PAD
		Box.MaxX, Box.MaxY, Box.MaxZ = Maxs.x + BOX_PAD, Maxs.y + BOX_PAD, Maxs.z + BOX_PAD

		return Box
	end

	local function AddPart(Cache, Entity)
		local Group = GroupFor(Cache, Entity)
		local Root  = Group.Root
		local Pos   = Entity:GetPos()
		local O     = Root:WorldToLocal(Pos)
		local F     = Root:WorldToLocal(Pos + Entity:GetForward()) - O
		local L     = Root:WorldToLocal(Pos - Entity:GetRight()) - O
		local U     = Root:WorldToLocal(Pos + Entity:GetUp()) - O
		local Mins, Maxs = Entity:OBBMins(), Entity:OBBMaxs()
		local Mesh  = Entity.ACF_Volumetric_Mesh
		local Part  = SetBox({
			Entity    = Entity,
			Group     = Group,
			Mesh      = Mesh,
			Invisible = ACF.IsInvisibleToTrace(Entity),
			OX = O.x, OY = O.y, OZ = O.z,
			FX = F.x, FY = F.y, FZ = F.z,
			LX = L.x, LY = L.y, LZ = L.z,
			UX = U.x, UY = U.y, UZ = U.z,
		}, Mins, Maxs)

		if Entity ~= Root then Part.Pos, Part.Ang = Entity:GetLocalPos(), Entity:GetLocalAngles() end

		-- The group's box takes in the part's box corners, in the group's frame
		for _, Corner in ipairs(Corners) do
			local X, Y, Z = Corner[1] and Maxs.x or Mins.x, Corner[2] and Maxs.y or Mins.y, Corner[3] and Maxs.z or Mins.z
			local GX = O.x + F.x * X + L.x * Y + U.x * Z
			local GY = O.y + F.y * X + L.y * Y + U.y * Z
			local GZ = O.z + F.z * X + L.z * Y + U.z * Z

			Group.MinX, Group.MinY, Group.MinZ = min(Group.MinX, GX - BOX_PAD), min(Group.MinY, GY - BOX_PAD), min(Group.MinZ, GZ - BOX_PAD)
			Group.MaxX, Group.MaxY, Group.MaxZ = max(Group.MaxX, GX + BOX_PAD), max(Group.MaxY, GY + BOX_PAD), max(Group.MaxZ, GZ + BOX_PAD)
		end

		Group.Parts[#Group.Parts + 1] = Part
		Cache.PartOf[Entity]          = Part
	end

	-- A part's convexes, with their faces, measured the first time a line comes into its box
	local function GetShapes(Part)
		local Shapes = Part.Shapes

		if Shapes then return Shapes end

		local Mins, Maxs = Part.Entity:OBBMins(), Part.Entity:OBBMaxs()

		Shapes = {}

		for _, Convex in ipairs(Part.Mesh.Convexes) do
			Shapes[#Shapes + 1] = SetBox({ Convex = Convex, Planes = GetPlanes(Convex) }, Convex.Mins or Mins, Convex.Maxs or Maxs)
		end

		Part.Shapes = Shapes

		return Shapes
	end

	-- Once a tick lines are worked on, the groups that moved on theirs move on a version.
	-- Parts keep their exact place on their parent until something moves them, so no tolerance is needed.
	local function ScanGroups(Cache)
		local Tick = engine.TickCount()

		if Cache.GroupTick == Tick then return end

		Cache.GroupTick = Tick

		if not IsValid(Cache.MainRoot) then Cache.Broken = true return end

		local Total = 0

		for Root, Group in pairs(Cache.Groups) do
			if not IsValid(Root) then Cache.Broken = true return end

			if Group.Parent then
				local Pos, Ang = GetGroupPose(Cache, Group)

				if Pos ~= Group.Pos or Ang ~= Group.Ang then
					Group.Pos, Group.Ang = Pos, Ang
					Group.Version        = Group.Version + 1
				end
			end

			Total = Total + Group.Version
		end

		Cache.Moves = Total -- Every move in the vehicle so far; while it stands, no line can have gone out of date
	end

	-- Once a tick fires spread, checks nothing moved within a group or was remeshed
	--- @return table|nil # The entities of the parts that did, to be measured again.
	local function ScanParts(Cache)
		local Tick = engine.TickCount()

		if Cache.PartTick == Tick then return end

		Cache.PartTick = Tick
		Cache.Cursor   = Cache.Cursor + 1

		local Changed

		for _, Group in pairs(Cache.Groups) do
			for _, Part in ipairs(Group.Parts) do
				local Entity = Part.Entity

				if not IsValid(Entity) or Entity.ACF_Volumetric_Mesh ~= Part.Mesh or Part.Pos and (Entity:GetLocalPos() ~= Part.Pos or Entity:GetLocalAngles() ~= Part.Ang) then
					Changed = Changed or {}

					Changed[#Changed + 1] = Entity
				else
					Part.Invisible = ACF.IsInvisibleToTrace(Entity)
				end
			end
		end

		return Changed
	end

	-- The group's frame this tick as plain numbers
	local function GetFrame(Group, Tick)
		if Group.FrameTick == Tick then return Group end

		local Root = Group.Root
		local O, F, R, U = Root:GetPos(), Root:GetForward(), Root:GetRight(), Root:GetUp()

		Group.FrameTick              = Tick
		Group.WX, Group.WY, Group.WZ = O.x, O.y, O.z
		Group.AX, Group.AY, Group.AZ = F.x, F.y, F.z
		Group.BX, Group.BY, Group.BZ = -R.x, -R.y, -R.z
		Group.CX, Group.CY, Group.CZ = U.x, U.y, U.z

		return Group
	end

	-- Clips the part of a segment between T0 and T1 to one slab of a box, nil once nothing is left
	local function Clip(From, Step, Low, High, T0, T1)
		if Step == 0 then
			if From < Low or From > High then return end

			return T0, T1
		end

		local TA, TB = (Low - From) / Step, (High - From) / Step

		if TA > TB then TA, TB = TB, TA end
		if TA > T0 then T0 = TA end
		if TB < T1 then T1 = TB end
		if T0 > T1 then return end

		return T0, T1
	end

	local function SegmentInBox(Box, AX, AY, AZ, BX, BY, BZ)
		local T0, T1 = Clip(AX, BX - AX, Box.MinX, Box.MaxX, 0, 1)

		if T0 then T0, T1 = Clip(AY, BY - AY, Box.MinY, Box.MaxY, T0, T1) end
		if T0 then T0 = Clip(AZ, BZ - AZ, Box.MinZ, Box.MaxZ, T0, T1) end

		return T0 ~= nil
	end

	-- Where a segment enters and leaves a convex, from 0 at its start to 1 at its end, by clipping it to each face
	local function ClipPlanes(Planes, AX, AY, AZ, BX, BY, BZ)
		local In, Out = 0, 1

		for I = 1, #Planes, 4 do
			local NX, NY, NZ, D = Planes[I], Planes[I + 1], Planes[I + 2], Planes[I + 3]
			local DA = NX * AX + NY * AY + NZ * AZ - D
			local DB = NX * BX + NY * BY + NZ * BZ - D

			if DA > 0 and DB > 0 then return end

			if DA > 0 then
				In = max(In, DA / (DA - DB))
			elseif DB > 0 then
				Out = min(Out, DA / (DA - DB))
			end

			if In > Out then return end
		end

		return In, Out
	end

	-- Where a world segment crosses one group's parts, unordered; each crossing is { Entity, Part, Convex, T }
	local function SolveGroup(Group, Line, SX, SY, SZ, EX, EY, EZ, Length, Tick)
		if Group.Gone then return NO_LAYERS end

		local G = GetFrame(Group, Tick)

		SX, SY, SZ = SX - G.WX, SY - G.WY, SZ - G.WZ
		EX, EY, EZ = EX - G.WX, EY - G.WY, EZ - G.WZ

		local AX, AY, AZ = SX * G.AX + SY * G.AY + SZ * G.AZ, SX * G.BX + SY * G.BY + SZ * G.BZ, SX * G.CX + SY * G.CY + SZ * G.CZ
		local BX, BY, BZ = EX * G.AX + EY * G.AY + EZ * G.AZ, EX * G.BX + EY * G.BY + EZ * G.BZ, EX * G.CX + EY * G.CY + EZ * G.CZ

		if not SegmentInBox(Group, AX, AY, AZ, BX, BY, BZ) then return NO_LAYERS end

		local Thinnest = MIN_LAYER_MM * ACF.MmToInch / ACF.ArmorCoef / Length -- Share of the line as thin as counts as a wall
		local Anchor, Target = Line.Anchor, Line.Target
		local Layers

		for _, Part in ipairs(Group.Parts) do
			local Entity = Part.Entity

			if Entity ~= Anchor and Entity ~= Target and Entity:IsSolid() then
				local DX, DY, DZ = AX - Part.OX, AY - Part.OY, AZ - Part.OZ
				local PAX = DX * Part.FX + DY * Part.FY + DZ * Part.FZ
				local PAY = DX * Part.LX + DY * Part.LY + DZ * Part.LZ
				local PAZ = DX * Part.UX + DY * Part.UY + DZ * Part.UZ

				DX, DY, DZ = BX - Part.OX, BY - Part.OY, BZ - Part.OZ

				local PBX = DX * Part.FX + DY * Part.FY + DZ * Part.FZ
				local PBY = DX * Part.LX + DY * Part.LY + DZ * Part.LZ
				local PBZ = DX * Part.UX + DY * Part.UY + DZ * Part.UZ

				if SegmentInBox(Part, PAX, PAY, PAZ, PBX, PBY, PBZ) then
					for _, Shape in ipairs(GetShapes(Part)) do
						if SegmentInBox(Shape, PAX, PAY, PAZ, PBX, PBY, PBZ) then
							local In, Out = ClipPlanes(Shape.Planes, PAX, PAY, PAZ, PBX, PBY, PBZ)

							if In and Out - In >= Thinnest then
								Layers = Layers or {}

								Layers[#Layers + 1] = { Entity = Entity, Part = Part, Convex = Shape.Convex, T = In }
							end
						end
					end
				end
			end
		end

		return Layers or NO_LAYERS
	end

	-- MARK: Line cache
	-- Each line runs from a fire to a point of what it heats. For every group it can cross, it keeps the crossings and
	-- the versions of the groups moving it against that group, and solves them again once those move on. A group the
	-- line can never reach, by the sweep of what carries it or of what carries the line, isn't kept at all.

	-- The vehicle's heated parts, its groups and the lines in it, kept on its contraption; parts joining and leaving it
	-- are worked into it one by one (see DropPart, JoinPart)
	local function GetCache(Contraption)
		local Cache = Contraption.ACF_FireCache

		if Cache then return Cache end

		local Heated, Movers, Sweeps = {}, {}, {}

		for Entity in pairs(Contraption.ACF_Entities or {}) do
			if IsValid(Entity) and IsHeated(Entity) then Heated[#Heated + 1] = Entity end
		end

		for Entity in pairs(Contraption.ents) do
			if IsValid(Entity) and IsMover(Entity) then
				local Sweep = GetSweep(Entity)

				Movers[#Movers + 1] = Sweep
				Sweeps[Entity]      = Sweep
			end
		end

		local Base = Contraption.ACF_Baseplate

		if not IsValid(Base) then
			for Entity in pairs(Contraption.ents) do
				if IsValid(Entity) then Base = Entity break end
			end
		end

		Cache = {
			Contraption = Contraption,
			Heated      = Heated,
			Movers      = Movers,
			Sweeps      = Sweeps,
			Groups      = {},
			PartOf      = {}, -- PartOf[Entity] = its part, in its group
			MainRoot    = IsValid(Base) and GetGroupRoot(Base) or nil,
			Paths       = {}, -- Paths[Key][Target] = the lines from a fire or jet to an entity
			Used        = {}, -- Used[Key] = when its fire or jet last read its lines
			Deps        = {}, -- Deps[A][T][G], see GetDeps
			Moves       = 0,
			Lines       = {}, -- Every line, worked through in turn
			Requests    = {},
			Cursor      = 0,
			Next        = 1,
		}

		if Cache.MainRoot then
			for Entity in pairs(Contraption.ents) do
				if IsValid(Entity) and Entity.ACF_Volumetric_Mesh then AddPart(Cache, Entity) end
			end
		else
			Cache.Broken = true
		end

		Contraption.ACF_FireCache = Cache

		return Cache
	end

	-- The groups whose moves change where group G sits against both ends of a line: those on the way between it and
	-- each end in the tree of groups. Lines between the same groups share them.
	local function GetDeps(Cache, A, T, G)
		local ByA = Cache.Deps[A]

		if not ByA then
			ByA = {}

			Cache.Deps[A] = ByA
		end

		local ByT = ByA[T]

		if not ByT then
			ByT = {}

			ByA[T] = ByT
		end

		if ByT[G] then return ByT[G] end

		local Set, List = {}, {}

		for _, End in ipairs({ A, T }) do
			for Member in pairs(End.Chain) do
				if not G.Chain[Member] then Set[Member] = true end
			end

			for Member in pairs(G.Chain) do
				if not End.Chain[Member] then Set[Member] = true end
			end
		end

		for Member in pairs(Set) do List[#List + 1] = Member end

		ByT[G] = List

		return List
	end

	local function GetSignature(Deps)
		local Sum = 0

		for _, Dep in ipairs(Deps) do Sum = Sum + Dep.Version end

		return Sum -- Versions only count up, so any move changes the sum
	end

	-- Whether the line can never reach group G however anything moves. A line fixed on group L can only meet a group
	-- carried below L where the moving part carrying it sweeps; one carried round by L can only meet what L doesn't
	-- carry where its own sweep about L's axis takes it.
	local function NeverMeets(Cache, L, G, Deps, Start, Finish)
		if G.Chain[L] then
			local Below = G

			while Below.Parent ~= L do Below = Below.Parent end

			local Sweep = Below.Sweep

			return Sweep ~= nil and not SegmentHitsSweep(Sweep, Start, Finish)
		end

		local Sweep = L.Sweep

		if #Deps == 1 and Deps[1] == L and Sweep and not Sweep.Anywhere and Sweep.Axis then
			local Key = 0

			for _, Group in pairs(Cache.Groups) do
				if not Group.Chain[L] then Key = Key + Group.Version end
			end

			return not SweepHitsOthers(Cache, Sweep, Start, Finish, Key)
		end

		return false
	end

	local function ByT(A, B) return A.T < B.T end

	-- Solves again what has moved on the line since, or all of it; true if anything was solved
	local function Refresh(Cache, Line, Force)
		local Plan = Line.Plan

		if not Force and not Line.Dirty then
			if Line.Moves == Cache.Moves then return false end

			local Stale = GetSignature(Line.PoseDeps) ~= Line.PoseSig

			if not Stale then
				for _, Entry in ipairs(Plan) do
					if GetSignature(Entry.Deps) ~= Entry.Sig then Stale = true break end
				end
			end

			if not Stale then
				Line.Moves = Cache.Moves

				return false
			end
		end

		local Anchor, Target = Line.Anchor, Line.Target
		local Start  = Anchor:LocalToWorld(Line.StartLocal)
		local Finish = Target:LocalToWorld(Line.FinishLocal)
		local Origin = Anchor:LocalToWorld(Line.OriginLocal)
		local Length = max(Start:Distance(Finish), 0.001)
		local Tick   = engine.TickCount()

		Line.PoseSig  = GetSignature(Line.PoseDeps)
		Line.SolvedAt = CurTime()
		Line.Moves    = Cache.Moves
		Line.Dirty    = nil
		Line.DistSqr = max(Origin:DistToSqr(Finish) * ACF.InchToMeter ^ 2, 0.0625)

		if Line.AxisLocal then
			local Axis = Anchor:LocalToWorld(Line.AxisLocal) - Anchor:GetPos()

			Line.Outside = (Finish - Origin):GetNormalized():Dot(Axis) < JET_COS
		end

		local SX, SY, SZ = Start:Unpack()
		local EX, EY, EZ = Finish:Unpack()
		local Layers

		for _, Entry in ipairs(Plan) do
			local Sig = GetSignature(Entry.Deps)

			-- Nothing on a line outside its jet is used, so it's solved once it comes back in
			if Line.Outside then
				Entry.Sig, Entry.Layers, Entry.Skipped, Entry.Dirty = Sig, NO_LAYERS, true, nil
			elseif Force or Entry.Skipped or Entry.Dirty or Sig ~= Entry.Sig then
				Entry.Sig, Entry.Layers, Entry.Skipped, Entry.Dirty = Sig, SolveGroup(Entry.Group, Line, SX, SY, SZ, EX, EY, EZ, Length, Tick), nil, nil
			end

			for _, Layer in ipairs(Entry.Layers) do
				Layers = Layers or {}

				Layers[#Layers + 1] = Layer
			end
		end

		if Layers then
			local OX, OY, OZ = Origin:Unpack()
			local DX, DY, DZ = EX - SX, EY - SY, EZ - SZ

			table.sort(Layers, ByT)

			for _, Layer in ipairs(Layers) do
				local T = Layer.T
				local X, Y, Z = SX + DX * T - OX, SY + DY * T - OY, SZ + DZ * T - OZ

				Layer.DistSqr = max((X * X + Y * Y + Z * Z) * ACF.InchToMeter ^ 2, 0.0625)
			end
		end

		Line.Layers = Layers or NO_LAYERS

		return true
	end

	-- A new line to a random point of the target, from a random point of the fire, or from the mouth of a jet
	local function NewLine(Cache, Asked)
		local Anchor, Target = Asked.Anchor, Asked.Target
		local Origin = Asked.Origin or Anchor:WorldSpaceCenter()
		local Start  = Asked.Axis and Origin or RandomPoint(Anchor)
		local Finish = RandomPoint(Target)
		local A, T   = GroupFor(Cache, Anchor), GroupFor(Cache, Target)
		local Line   = {
			Anchor      = Anchor,
			Target      = Target,
			StartLocal  = Anchor:WorldToLocal(Start),
			FinishLocal = Target:WorldToLocal(Finish),
			OriginLocal = Anchor:WorldToLocal(Origin),
			AxisLocal   = Asked.Axis and Anchor:WorldToLocal(Anchor:GetPos() + Asked.Axis) or nil,
			PoseDeps    = GetDeps(Cache, A, T, T),
			Plan        = {},
		}

		for _, Group in pairs(Cache.Groups) do
			if Group.Parts[1] then
				local Deps = GetDeps(Cache, A, T, Group)

				if not (A == T and Group ~= A and NeverMeets(Cache, A, Group, Deps, Start, Finish)) then
					Line.Plan[#Line.Plan + 1] = { Group = Group, Deps = Deps }
				end
			end
		end

		Refresh(Cache, Line, true)

		return Line
	end

	-- MARK: Parts joining and leaving
	-- A fight knocks parts off a burning vehicle all the time, so they're taken out of its lines one by one rather than
	-- the lines being solved all over again. Only parts others move with, and moving parts, have it measured anew.

	local function Unlist(List, Value)
		for I = #List, 1, -1 do
			if List[I] == Value then
				List[I]     = List[#List]
				List[#List] = nil

				return
			end
		end
	end

	--- Takes a part out of the cache: it no longer stands in the way of any line, or is heated or heats anything.
	--- @return boolean # false if the groups must be measured again.
	local function DropPart(Cache, Entity)
		if Entity == Cache.MainRoot or Cache.Sweeps[Entity] then return false end

		local Part  = Cache.PartOf[Entity]
		local Group = Cache.Groups[Entity] -- Only if it's what a group moves with

		if Group then
			for _, Member in ipairs(Group.Parts) do
				if Member ~= Part then return false end
			end

			for _, Other in pairs(Cache.Groups) do
				if Other.Parent == Group then return false end
			end

			Group.Gone           = true
			Cache.Groups[Entity] = nil
		end

		if Part then
			Part.Invisible       = true -- Lines that crossed it pass through it from now on, and drop it once solved again
			Cache.PartOf[Entity] = nil

			Unlist(Part.Group.Parts, Part)
		end

		Unlist(Cache.Heated, Entity)

		-- Lines from it, as a fire or the wall a jet comes out of, and lines to it
		for Key, ByKey in pairs(Cache.Paths) do
			if Key == Entity or istable(Key) and Key.Entity == Entity then
				for _, Paths in pairs(ByKey) do Paths.Dead = true end

				Cache.Paths[Key], Cache.Used[Key] = nil, nil
			elseif ByKey[Entity] then
				ByKey[Entity].Dead = true
				ByKey[Entity]      = nil
			end
		end

		for _, Line in ipairs(Cache.Lines) do
			if Line.Anchor == Entity or Line.Target == Entity then Line.Dead = true end
		end

		return true
	end

	--- Adds a part to the cache: it's heated if it takes heat, and every line solves where it crosses its group again.
	--- @return boolean # false if the groups must be measured again.
	local function JoinPart(Cache, Entity)
		if IsMover(Entity) then return false end
		if Cache.PartOf[Entity] then return true end

		if IsHeated(Entity) and not table.HasValue(Cache.Heated, Entity) then Cache.Heated[#Cache.Heated + 1] = Entity end

		if not Entity.ACF_Volumetric_Mesh then return true end

		AddPart(Cache, Entity)

		local Group = Cache.PartOf[Entity].Group

		-- What carries it now reaches further; the sweep is rebuilt in place, as its group holds it
		local Up = Entity:GetMoveParent()

		while IsValid(Up) do
			local Sweep = Cache.Sweeps[Up]

			if Sweep then
				local Fresh = GetSweep(Up)

				table.Empty(Sweep)

				for Field, Value in pairs(Fresh) do Sweep[Field] = Value end
			end

			Up = Up:GetMoveParent()
		end

		-- Every other mover's sweep can now come to meet it
		for _, Sweep in pairs(Cache.Sweeps) do Sweep.OthersKey = nil end

		-- Each line takes its group in, whatever it could reach before, as the part may lie beyond that; only lines
		-- through the part's box now are solved again, the others meet it only once something moves on them
		local Pos, Ang    = Entity:GetPos(), Entity:GetAngles()
		local Pad         = Vector(BOX_PAD, BOX_PAD, BOX_PAD)
		local Mins, Maxs  = Entity:OBBMins() - Pad, Entity:OBBMaxs() + Pad

		for _, Line in ipairs(Cache.Lines) do
			if not Line.Dead and IsValid(Line.Anchor) and IsValid(Line.Target) then
				local Entry

				for _, Have in ipairs(Line.Plan) do
					if Have.Group == Group then Entry = Have break end
				end

				if not Entry then
					Entry = { Group = Group, Deps = GetDeps(Cache, GroupFor(Cache, Line.Anchor), GroupFor(Cache, Line.Target), Group), Layers = NO_LAYERS }
					Entry.Sig = GetSignature(Entry.Deps)

					Line.Plan[#Line.Plan + 1] = Entry
				end

				local Start = Line.Anchor:LocalToWorld(Line.StartLocal)

				if util.IntersectRayWithOBB(Start, Line.Target:LocalToWorld(Line.FinishLocal) - Start, Pos, Ang, Mins, Maxs) then
					Entry.Dirty, Line.Dirty = true, true
				end
			end
		end

		return true
	end

	-- Parts that moved within their group, were remeshed or were removed, measured again one by one
	local function Resettle(Cache, Changed)
		for _, Entity in ipairs(Changed) do
			if not DropPart(Cache, Entity) then return false end

			if IsValid(Entity) and Entity:CFW_GetContraption() == Cache.Contraption and not JoinPart(Cache, Entity) then return false end
		end

		return true
	end

	-- CFW runs these in the middle of changing the contraption, so an error here mustn't escape into it
	local function Update(Contraption, Entity, Change)
		local Cache = Contraption.ACF_FireCache

		if not Cache then return end

		local Ok, Done = xpcall(Change, ErrorNoHaltWithStack, Cache, Entity)

		if not (Ok and Done) then Contraption.ACF_FireCache = nil end
	end

	hook.Add("cfw.contraption.entityAdded", "ACF_FireCache", function(Contraption, Entity)
		if IsValid(Entity) then Update(Contraption, Entity, JoinPart) end
	end)

	hook.Add("cfw.contraption.entityRemoved", "ACF_FireCache", function(Contraption, Entity)
		Update(Contraption, Entity, DropPart)
	end)

	-- Heat reaching the target along a line, through the walls on it as they are now
	local function PathFlux(Path, Intensity)
		if Path.Outside then return 0 end

		local Cap = math.huge

		for _, Layer in ipairs(Path.Layers) do
			local Convex = Layer.Convex

			if Convex.Health > 0 and not Layer.Part.Invisible and random() >= Damage.GetConvexOpening(Convex) then
				local Incident = min(Cap, Intensity / Layer.DistSqr, MAX_FLUX)

				if Incident > (Convex.FireIncident or 0) then Convex.FireIncident = Incident end

				Fire.HotWalls[Convex] = Layer.Entity

				Cap = min(Cap, Fire.GetWallEmission(Convex))

				if Cap <= 0 then return 0 end
			end
		end

		return min(Cap, Intensity / Path.DistSqr, MAX_FLUX)
	end

	local Active = {} -- Active[Cache] = time until which its fires have been spreading

	local function ByNeed(A, B)
		local CA, CB = #A.Paths, #B.Paths

		if CA ~= CB then return CA < CB end

		return A.Axis ~= nil and B.Axis == nil
	end

	--- Works on the lines of every vehicle with fires spreading in it, each server tick: first the new lines targets
	--- still lack, those with the fewest first and jets before radiant heat, then lines something has moved on since,
	--- in turn, each at most once a fire tick. A vehicle gets PATH_BUDGET lines solved a tick, and PATH_CHECKS looked at.
	function Fire.BuildPaths()
		local Now = CurTime()

		for Cache, Until in pairs(Active) do
			local Contraption = Cache.Contraption

			if Until < Now or Contraption.ACF_FireCache ~= Cache then
				Active[Cache] = nil
			else
				ScanGroups(Cache)

				if Cache.Broken then
					Contraption.ACF_FireCache = nil
					Active[Cache]             = nil
				else
					-- A fire that's out, or a jet that stopped, has its lines dropped rather than kept up to date for nothing
					local Unused = Now - ACF.FireTickRate * 3

					for Key, ByKey in pairs(Cache.Paths) do
						if (Cache.Used[Key] or 0) < Unused then
							for _, Paths in pairs(ByKey) do
								Paths.Dead = true

								for _, Line in ipairs(Paths) do Line.Dead = true end
							end

							Cache.Paths[Key], Cache.Used[Key] = nil, nil
						end
					end

					local Budget   = PATH_BUDGET
					local Requests = Cache.Requests
					local Count    = #Requests

					table.sort(Requests, ByNeed)

					-- One line each at a time, so the budget goes round every target in need
					local Progress = true

					while Budget > 0 and Progress do
						Progress = false

						for I = 1, Count do
							local Asked = Requests[I]
							local Paths = Asked.Paths

							if Budget > 0 and #Paths < PATH_RAYS and not Paths.Dead and IsValid(Asked.Anchor) and IsValid(Asked.Target) then
								local Line = NewLine(Cache, Asked)

								Paths[#Paths + 1]           = Line
								Cache.Lines[#Cache.Lines + 1] = Line
								Budget                      = Budget - 1
								Progress                    = true
							end
						end
					end

					local Kept = 0

					for I = 1, Count do
						local Asked = Requests[I]
						local Paths = Asked.Paths

						Requests[I] = nil

						if #Paths < PATH_RAYS and not Paths.Dead and IsValid(Asked.Anchor) and IsValid(Asked.Target) then
							Kept = Kept + 1

							Requests[Kept] = Asked
						else
							Paths.Pending = nil
						end
					end

					local Lines  = Cache.Lines
					local Checks = PATH_CHECKS

					while Budget > 0 and Checks > 0 and Lines[1] do
						local Index = Cache.Next > #Lines and 1 or Cache.Next
						local Line  = Lines[Index]

						Checks = Checks - 1

						if Line.Dead or not (IsValid(Line.Anchor) and IsValid(Line.Target)) then
							Lines[Index]  = Lines[#Lines]
							Lines[#Lines] = nil
							Cache.Next    = Index
						else
							Cache.Next = Index + 1

							-- Fires only read a line once a fire tick, so solving one more often is wasted, unless a part joined it
							if (Line.Dirty or Now - Line.SolvedAt >= ACF.FireTickRate) and Refresh(Cache, Line) then Budget = Budget - 1 end
						end
					end
				end
			end
		end
	end

	hook.Add("Think", "ACF_FireLines", function()
		xpcall(Fire.BuildPaths, ErrorNoHaltWithStack)
	end)

	-- The heat is averaged over the lines a target has, those waiting to be solved again included
	local function CachedFlux(Cache, Key, Anchor, Target, Origin, Intensity, Axis, Draw)
		local ByKey = Cache.Paths[Key]

		if not ByKey then
			ByKey = {}

			Cache.Paths[Key] = ByKey
		end

		local Paths = ByKey[Target]

		if not Paths then
			Paths = {}

			ByKey[Target] = Paths
		end

		if #Paths < PATH_RAYS and not Paths.Pending then
			Paths.Pending = true

			Cache.Requests[#Cache.Requests + 1] = { Paths = Paths, Anchor = Anchor, Target = Target, Origin = Axis and Origin, Axis = Axis }
		end

		local Count = #Paths

		if Count == 0 then return end

		local Flux = 0

		for _, Path in ipairs(Paths) do
			local PathHeat = PathFlux(Path, Intensity)

			Flux = Flux + PathHeat

			if Draw and not Path.Outside then
				local Heat = PathHeat / MAX_FLUX

				Debug.Line(Anchor:LocalToWorld(Path.StartLocal), Target:LocalToWorld(Path.FinishLocal), DEBUG_TICK_LIFE, Color(255, 255 * (1 - Heat), 60 * (1 - Heat), 40 + 215 * Heat))
			end
		end

		return Flux / Count
	end

	--- Adds the heat a fire sends out onto everything of its own vehicle within its reach: radiated all around it or,
	--- given an Axis and the Wall it comes out of, carried whole by a jet of flame into a cone along it. A fire on no
	--- vehicle heats nothing else.
	--- @param Exposure table Exposure[Entity] = W/m², summed over every fire this tick.
	--- @param Origin vector|nil Where the heat comes from if not the burning entity, such as the mouth of a jet.
	--- @param Axis vector|nil Direction of a jet from Origin.
	--- @param Wall table|nil The breached wall a jet comes out of, { Entity, Convex } (see Fire.SurveyEnclosure).
	function Fire.SpreadHeat(Entity, HeatRelease, Exposure, Origin, Axis, Wall)
		local Contraption = Entity:CFW_GetContraption()

		if not Contraption then return end
		if Axis and not (Wall and IsValid(Wall.Entity)) then return end

		local Intensity = Axis and HeatRelease / JET_SOLID_ANGLE or RADIANT_FRACTION * HeatRelease / (4 * pi) -- W/sr
		local Range     = math.sqrt(Intensity / MIN_FLUX) / ACF.InchToMeter
		local Cache     = GetCache(Contraption)
		local Draw      = Debug.SetDeveloperLevel(3)
		local Anchor, Key

		-- Parts that moved within their group or were remeshed are measured again, or all the groups if that can't be done
		local Changed = ScanParts(Cache)

		if Changed and not Resettle(Cache, Changed) then
			Contraption.ACF_FireCache = nil

			Cache = GetCache(Contraption)

			ScanParts(Cache)
		end

		Active[Cache] = CurTime() + ACF.FireTickRate * 2

		if Axis then
			local Convex = Wall.Convex
			local Hole   = Convex.HoleChannelArea or 0

			-- The jet comes out where the holes are, so new holes move it and its lines are traced afresh
			if Convex.FireJetHole ~= Hole then
				for _, Paths in pairs(Cache.Paths[Convex] or {}) do
					Paths.Dead = true

					for _, Line in ipairs(Paths) do Line.Dead = true end
				end

				Convex.FireJetHole  = Hole
				Cache.Paths[Convex] = nil
			end

			Range  = min(Range, JET_MAX_RANGE)
			Anchor = Wall.Entity
			Key    = Convex

			if Debug.SetDeveloperLevel(2) then DrawJet(Origin, Axis, HeatRelease) end
		else
			Origin = Entity:WorldSpaceCenter()
			Anchor = Entity
			Key    = Entity
		end

		Cache.Used[Key] = CurTime()

		local Heated = Cache.Heated
		local Count  = #Heated

		-- Start somewhere else each tick, so a short budget reaches every target in turn
		for I = 1, Count do
			local Target = Heated[(Cache.Cursor + I) % Count + 1]

			if Target ~= Entity and IsValid(Target) and not Fire.Burning[Target] and Origin:Distance(Target:WorldSpaceCenter()) - Target:BoundingRadius() <= Range and (not Axis or IsInCone(Origin, Axis, Target)) then
				local Flux = CachedFlux(Cache, Key, Anchor, Target, Origin, Intensity, Axis, Draw)

				if Flux then Exposure[Target] = (Exposure[Target] or 0) + Flux end
			end
		end
	end

	local function Heat(Target, Flux, DeltaTime)
		if Flux >= ACF.ExtinguisherDetectFlux then Fire.Alert(Target, Flux) end

		if Target.ACF_OnHeat then
			Target:ACF_OnHeat(Flux, DeltaTime)
		else
			Fire.DamageComponent(Target, Flux, DeltaTime)
		end
	end

	-- Fires tick on rhythms of their own, so each entity keeps what every fire last sent it
	local Received = {} -- Received[Target][Fire] = { Flux, Engulf }
	local Sent     = {} -- Sent[Fire][Target] = true

	local function Forget(Source, Target)
		local From = Received[Target]

		if not From then return end

		From[Source] = nil

		if not next(From) then Received[Target] = nil end
	end

	--- Stops counting what a fire was sending, once it's out.
	function Fire.ForgetHeat(Source)
		for Target in pairs(Sent[Source] or {}) do Forget(Source, Target) end

		Sent[Source] = nil
	end

	--- Hands the entities one fire reaches what it sends them this tick.
	--- Together, the fires on an entity can't heat it past an engulfing fire's heat from afar, or past the hottest flames
	--- it's in; each fire applies its part of that, as the share of the fire tick it stands for, so an entity sees
	--- the whole heat on it at once however many fires it comes from.
	--- @param Engulfing table Engulfing[Entity] = W/m² of the flames it's in, which can be hotter than any fire's heat from afar.
	function Fire.ApplyHeat(Source, Exposure, Engulfing, DeltaTime)
		local Draw   = Debug.SetDeveloperLevel(2)
		local MySent = Sent[Source]

		if not MySent then
			MySent = {}

			Sent[Source] = MySent
		end

		for Target in pairs(MySent) do
			if not Exposure[Target] and not Engulfing[Target] then
				Forget(Source, Target)

				MySent[Target] = nil
			end
		end

		for Target in pairs(Engulfing) do
			Exposure[Target] = Exposure[Target] or 0
		end

		for Target, Flux in pairs(Exposure) do
			if not IsValid(Target) then
				Received[Target] = nil
				MySent[Target]   = nil
			else
				local From = Received[Target]

				if not From then
					From = {}

					Received[Target] = From
				end

				local Mine = From[Source]

				if not Mine then
					Mine = {}

					From[Source] = Mine
				end

				Mine.Flux, Mine.Engulf = Flux, Engulfing[Target] or 0
				MySent[Target] = true

				local Total, Hottest, Weight = 0, 0, 0

				for _, Got in pairs(From) do
					Total   = Total + Got.Flux
					Hottest = max(Hottest, Got.Engulf)
					Weight  = Weight + Got.Flux + Got.Engulf
				end

				local Applied = max(min(Total, MAX_FLUX), Hottest)

				if Applied > 0 and Weight > 0 then
					if Draw then
						Debug.EntityText(Target, 1, ("Heat %.1f kW/m²"):format(Applied / 1000), DEBUG_TICK_LIFE, Applied > ACF.CrewTenableFlux and COLOR_HOT or COLOR_WARM)
					end

					-- The whole heat on it, for this fire's share of the time
					xpcall(Heat, ErrorNoHaltWithStack, Target, Applied, DeltaTime * (Mine.Flux + Mine.Engulf) / Weight)
				end
			end
		end
	end
end
