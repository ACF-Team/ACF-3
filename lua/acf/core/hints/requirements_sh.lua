-- Requirements an entity needs met to work, set with ENT:SetRequirement and drawn for the owner while unmet, see draw_sv.lua
-- Positions in the data are local to the entity unless stated, so the drawings follow moving vehicles
local ACF = ACF

local function Register(Id, Text, Behaviour)
	return ACF.Hints.RegisterRequirement(Id, Text, Behaviour)
end

local function Name(Entity, Fallback)
	return IsValid(Entity) and tostring(Entity) or Fallback
end

local COLOR_BAD  = Color(255, 50, 50)
local COLOR_GOOD = Color(50, 255, 50)
local COLOR_HINT = Color(255, 170, 0)

local CIRCLE_SEGMENTS = 24

-- Draws a trace green up to where it hit and red past it, through walls since these usually run inside a vehicle
local function DrawTrace(Debug, From, HitPos, To, Life)
	Debug.Line(From, HitPos, Life, COLOR_GOOD, true)
	Debug.Line(HitPos, To, Life, COLOR_BAD, true)
	Debug.Sphere(HitPos, 1.5, Life, COLOR_BAD, true)
end

-- Draws a flat circle in an entity's frame, Center is local to it
local function DrawCircle(Debug, Entity, Center, Radius, Life, Color)
	local Prev

	for I = 0, CIRCLE_SEGMENTS do
		local Angle = I / CIRCLE_SEGMENTS * math.pi * 2
		local Point = Entity:LocalToWorld(Center + Vector(math.cos(Angle) * Radius, math.sin(Angle) * Radius, 0))

		if Prev then Debug.Line(Prev, Point, Life, Color, true) end

		Prev = Point
	end
end

-- Points the owner from the entity to another one that holds the cause, a line to it, a box around it and a label on it
local function DrawRelated(Debug, Entity, Target, Label, Life, Color)
	if not IsValid(Target) then return end

	Color = Color or COLOR_HINT

	Debug.EntityLine(Entity, Target, Life, Color, true)
	Debug.EntityBox(Target, Life, Color, true)

	if Label then Debug.EntityText(Target, 0, Label, Life, Color) end
end

local function BreechPos(Weapon)
	return Weapon:LocalToWorld(Weapon.BreechPos)
end

local function HasBreech(Weapon)
	return IsValid(Weapon) and Weapon.BreechPos and Weapon.BreechAng
end

-- Shows a blocked trace from the entity's origin, Data.HitPos is local to the entity
local function DrawBlockedPath(GetTarget)
	return function(Debug, Entity, Data, Life)
		local To = GetTarget(Data.Target)
		if not To then return end

		if IsValid(Data.Blocker) then Debug.EntityBox(Data.Blocker, Life, COLOR_BAD, true) end

		DrawTrace(Debug, Entity:GetPos(), Entity:LocalToWorld(Data.HitPos), To, Life)
	end
end

local function BlockedDetail(Data)
	return "blocked by " .. Name(Data.Blocker, "another entity")
end

do -- MARK: Autoloader requirements
	Register("autoloader_breech_alignment", {
		Title  = "Breech alignment",
		Detail = function(Data)
			return math.Round(Data.Angle or 0) .. " degrees off, needs less than " .. (Data.Limit or "?")
		end,
		Help   = "The autoloader must sit behind the breech, in line with the bore, and point the way the weapon fires. "
			.. "Move it onto the green line and turn it to face along the green arrow.",
	}, {
		-- The green line runs back from the breech along the bore, the arrows compare the autoloader's facing with the weapon's
		Draw = function(Debug, Entity, Data, Life)
			local Weapon = Data.Weapon
			if not HasBreech(Weapon) then return end

			local Breech   = BreechPos(Weapon)
			local Back     = -Weapon:LocalToWorldAngles(Weapon.BreechAng):Forward()
			local Pos      = Entity:GetPos()
			local Length   = math.max(Pos:Distance(Breech), 12)
			local Ideal    = Breech + Back * Length
			local Facing   = Pos + Entity:GetForward() * 12
			local Required = Pos + Weapon:GetForward() * 12

			Debug.Line(Breech, Ideal, Life, COLOR_GOOD, true)
			Debug.EntityTextAtPosition(Ideal, 0, "Place along this line", Life, COLOR_GOOD)
			Debug.Line(Pos, Breech, Life, COLOR_BAD, true)
			Debug.Line(Pos, Facing, Life, COLOR_BAD, true)
			Debug.Line(Pos, Required, Life, COLOR_GOOD, true)
			Debug.EntityTextAtPosition(Required, 0, "Face this way", Life, COLOR_GOOD)
		end,
	})

	-- Data.Target is the weapon
	Register("autoloader_path_breech", {
		Title  = "Path to breech",
		Detail = BlockedDetail,
		Help   = "The autoloader needs a clear straight path to the breech. Move the boxed entity out of the red part of the line, "
			.. "or move the autoloader.",
	}, {
		Draw = DrawBlockedPath(function(Weapon) return HasBreech(Weapon) and BreechPos(Weapon) end),
	})

	-- Data.Target is the ammo crate
	Register("autoloader_path_ammo", {
		Title  = "Path to ammo",
		Detail = BlockedDetail,
		Help   = "The autoloader needs a clear straight path to the center of its ammo crate. Move the boxed entity out of the red "
			.. "part of the line, or move the autoloader or the crate.",
	}, {
		Draw = DrawBlockedPath(function(Crate) return IsValid(Crate) and Crate:GetPos() end),
	})
end

do -- MARK: Weapon loading requirements
	Register("weapon_autoloader_ready", {
		Title  = "Autoloader ready",
		Detail = "the autoloader cannot load, see its overlay",
		Help   = "The linked autoloader has a problem of its own. Look at the marked autoloader to see what it needs.",
	}, {
		Draw = function(Debug, Entity, Data, Life)
			DrawRelated(Debug, Entity, Data.Autoloader, "Check this autoloader", Life)
		end,
	})

	local LOADING_CREW = { "Loader", "Commander", "Gunner" }

	Register("weapon_loader_sight", {
		Title  = "Loader sight",
		Detail = "no loader can see the breech",
		Help   = "Every crew member loading this weapon has its view of the breech blocked. Clear at least one red line "
			.. "by moving the boxed entity, the crew or the weapon.",
	}, {
		-- Each loading crew keeps its own sight line hint, which names what blocks it
		Draw = function(Debug, Entity, _, Life)
			if not Entity.BreechPos then return end

			local Breech = BreechPos(Entity)

			for _, Type in ipairs(LOADING_CREW) do
				for Crew in pairs(Entity.CrewsByType and Entity.CrewsByType[Type] or {}) do
					local Sight = IsValid(Crew) and Crew.ACF_Hints and Crew.ACF_Hints.crew_breech_los

					if Sight and Sight.Gun == Entity then
						local Eye = Crew.CrewModel and Crew:LocalToWorld(Crew.CrewModel.ScanOffsetL) or Crew:WorldSpaceCenter()

						if IsValid(Sight.Blocker) then Debug.EntityBox(Sight.Blocker, Life, COLOR_BAD, true) end

						Debug.Line(Eye, Breech, Life, COLOR_BAD, true)
					end
				end
			end
		end,
	})

	Register("weapon_breech_room", {
		Title  = "Room behind breech",
		Detail = BlockedDetail,
		Help   = "Rounds are loaded from behind the breech, so the space behind it must stay clear for about half a round's length. "
			.. "Move the boxed entity out of the red part of the line.",
	}, {
		Draw = function(Debug, Entity, Data, Life)
			if not (Data.From and Data.To and Data.HitPos) then return end

			if IsValid(Data.Blocker) then Debug.EntityBox(Data.Blocker, Life, COLOR_BAD, true) end

			DrawTrace(Debug, Entity:LocalToWorld(Data.From), Entity:LocalToWorld(Data.HitPos), Entity:LocalToWorld(Data.To), Life)
		end,
	})
end

do -- MARK: Turret requirements
	-- Data.Crews lists each linked crew that could aim the turret but does not, with why
	Register("turret_aim_control", {
		Title  = "Aim control",
		Detail = "needs a gunner, commander, pilot or lightweight controller",
		Help   = "A turret carrying weapons needs someone aiming it. Link a gunner, commander or pilot that rides on the turret "
			.. "or shares its parent, or link a lightweight turret controller. A vertical drive can also be aimed by the crew "
			.. "of the horizontal drive under it. Crew marked in red are linked but cannot aim, for the reason shown.",
	}, {
		Draw = function(Debug, Entity, Data, Life)
			for _, Entry in ipairs(Data.Crews or {}) do
				local Crew = Entry.Crew

				if IsValid(Crew) then
					Debug.EntityLine(Entity, Crew, Life, COLOR_BAD, true)
					Debug.EntityText(Crew, 0, Entry.Reason, Life, COLOR_BAD)
				end
			end
		end,
	})

	Register("turret_motor_parent", {
		Title  = "Parent",
		Detail = "parent to the ring or its parent",
		Help   = "Parent the motor to the turret ring it drives, or to the entity that ring is parented to.",
	}, {
		Draw = function(Debug, Entity, Data, Life)
			local Turret = Data.Turret
			if not IsValid(Turret) then return end

			local Parent     = Entity:GetParent()
			local RingParent = Turret:GetParent()

			if IsValid(Parent) then
				Debug.EntityLine(Entity, Parent, Life, COLOR_BAD, true)
				Debug.EntityText(Parent, 1, "Current parent", Life, COLOR_BAD)
			end

			Debug.EntityLine(Entity, Turret, Life, COLOR_GOOD, true)
			Debug.EntityText(Turret, 0, "Parent to this ring", Life, COLOR_GOOD)

			if IsValid(RingParent) then Debug.EntityText(RingParent, 0, "or to this", Life, COLOR_GOOD) end
		end,
	})

	-- Data.Center is local to the turret, the motor must be within Data.Radius of it on the ring's plane
	Register("turret_motor_near_ring", {
		Title  = "Near ring",
		Detail = function(Data)
			return math.Round(Data.Distance or 0) .. " units from the ring, needs " .. math.Round(Data.Radius or 0) .. " or less"
		end,
		Help   = "The motor must sit close to the turret ring it drives. Move it inside the green circle.",
	}, {
		Draw = function(Debug, Entity, Data, Life)
			local Turret = Data.Turret
			if not IsValid(Turret) then return end

			DrawCircle(Debug, Turret, Data.Center, Data.Radius, Life, COLOR_GOOD)
			Debug.Line(Entity:WorldSpaceCenter(), Turret:LocalToWorld(Data.Center), Life, COLOR_BAD, true)
		end,
	})

	-- Data.Center is local to the turret, the motor must be within Data.Limit of it along the ring's axis
	Register("turret_motor_ring_height", {
		Title  = "Ring height",
		Detail = function(Data)
			return math.Round(Data.Height or 0) .. " units above or below the ring, needs " .. math.Round(Data.Limit or 0) .. " or less"
		end,
		Help   = "The motor must sit level with the turret ring it drives. Move it up or down to between the green circles.",
	}, {
		Draw = function(Debug, Entity, Data, Life)
			local Turret = Data.Turret
			if not IsValid(Turret) then return end

			local Offset = Vector(0, 0, Data.Limit)

			DrawCircle(Debug, Turret, Data.Center + Offset, Data.Radius, Life, COLOR_GOOD)
			DrawCircle(Debug, Turret, Data.Center - Offset, Data.Radius, Life, COLOR_GOOD)
			Debug.Line(Entity:WorldSpaceCenter(), Turret:LocalToWorld(Data.Center), Life, COLOR_BAD, true)
		end,
	})

	Register("turret_controller_mass", {
		Title  = "Turret mass",
		Detail = function(Data)
			return math.Round(Data.Mass or 0) .. " of " .. (Data.Limit or "?") .. " kg"
		end,
		Help   = "A lightweight controller only aims turrets up to the mass shown, counting the ring and everything it carries. "
			.. "Lighten the turret, or have a gunner aim it instead.",
	}, {
		Draw = function(Debug, Entity, Data, Life)
			local Turret = Data.Turret
			if not IsValid(Turret) then return end

			Debug.EntityLine(Entity, Turret, Life, COLOR_BAD, true)
			Debug.EntityText(Turret, 0, "Carries " .. math.Round(Data.Mass or 0) .. " kg", Life, COLOR_BAD)
		end,
	})
end

do -- MARK: Mobility requirements
	-- Data.Reason says why the baseplate's driver modifier is low, Data.Drivers and Data.Misaligned list its drivers
	Register("gearbox_driver", {
		Title  = "Driver",
		Detail = function(Data)
			return "wheels get " .. (Data.Percent or "?") .. "% torque, " .. (Data.Reason or "no driver")
		end,
		Help   = "Gearboxes only pass their full torque to wheels when the vehicle's baseplate has a driver or pilot with "
			.. "enough efficiency. A driver must face the baseplate's forward to count. Add a driver, turn the marked driver "
			.. "to face forward, or raise its efficiency with more room, a better pose or a commander.",
	}, {
		Draw = function(Debug, Entity, Data, Life)
			for _, Crew in ipairs(Data.Misaligned or {}) do
				DrawRelated(Debug, Entity, Crew, "Face the baseplate's forward", Life, COLOR_BAD)
			end

			for _, Crew in ipairs(Data.Drivers or {}) do
				local Eff = IsValid(Crew) and Crew.TotalEff

				if Eff then DrawRelated(Debug, Entity, Crew, math.floor(Eff * 100) .. "% efficiency", Life) end
			end

			if not (Data.Drivers and Data.Drivers[1]) and not (Data.Misaligned and Data.Misaligned[1]) then
				DrawRelated(Debug, Entity, Data.Baseplate, "Add a driver to this vehicle", Life)
			end
		end,
	})

	-- Data.Wheels lists each linked wheel that cannot be driven, with the Reason
	Register("gearbox_wheels_free", {
		Title  = "Free wheels",
		Detail = function(Data)
			local Wheels = Data.Wheels or {}
			local First  = Wheels[1]
			if not First then return "" end

			if Wheels[2] then return #Wheels .. " linked wheels cannot turn" end

			return Name(First.Wheel, "a linked wheel") .. " is " .. First.Reason:lower()
		end,
		Help   = "Gearboxes can only turn and brake wheels that move on their own. Unparent the marked wheels and attach them "
			.. "with axis or ballsocket constraints, and unfreeze any frozen ones.",
	}, {
		Draw = function(Debug, Entity, Data, Life)
			for _, Entry in ipairs(Data.Wheels or {}) do
				DrawRelated(Debug, Entity, Entry.Wheel, Entry.Reason, Life, COLOR_BAD)
			end
		end,
	})
end

do -- MARK: Link requirements
	local DASH = 6 -- Length of each dash of a broken link, in units

	-- Dashed so it reads as a link that no longer exists
	local function DrawDashed(Debug, From, To, Life, Color)
		local Length = From:Distance(To)
		local Dir    = (To - From):GetNormalized()

		for Start = 0, Length, DASH * 2 do
			Debug.Line(From + Dir * Start, From + Dir * math.min(Start + DASH, Length), Life, Color, true)
		end
	end

	-- Data.Links lists each lost link with its Target, Reason, From (local to the entity) and To (local to the target)
	Register("link_broken", {
		Title  = "Link broken",
		Detail = function(Data)
			local Links = Data.Links or {}
			local First = Links[1]
			if not First then return "" end

			local Text = "to " .. Name(First.Target, "an entity") .. ", " .. First.Reason:lower()

			if Links[2] then Text = Text .. ", and " .. (#Links - 1) .. " more" end

			return Text
		end,
		Help   = "Links are removed when the entities move so far apart that the shaft stretches past one and a half times its "
			.. "length, or bend it past the driveshaft angle limit. Move the marked entities back into line and link them again. "
			.. "This goes away by itself after a minute.",
	}, {
		Draw = function(Debug, Entity, Data, Life)
			for _, Entry in ipairs(Data.Links or {}) do
				local Target = Entry.Target

				if IsValid(Target) then
					DrawDashed(Debug, Entity:LocalToWorld(Entry.From), Target:LocalToWorld(Entry.To), Life, COLOR_BAD)
					Debug.EntityBox(Target, Life, COLOR_BAD, true)
					Debug.EntityText(Target, 0, Entry.Reason, Life, COLOR_BAD)
				end
			end
		end,
	})
end

do -- MARK: Component requirements
	-- Shared by turret motors, gyros and controllers
	Register("component_health", {
		Title  = "Health",
		Detail = function(Data)
			return math.Round(Data.Percent or 0) .. "%, needs more than 25%"
		end,
		Help   = "This component stops working below 25% health. Repair it to bring it back into service.",
	})
end
