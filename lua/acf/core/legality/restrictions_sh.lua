-- Definitions of the legality restrictions applied to ACF entities and seats, shared so the client can read the help text
local ACF = ACF

local function Register(Id, Text, Behaviour)
	return ACF.Legality.RegisterRestriction(Id, Text, Behaviour)
end

local COLOR_DISABLE = Color(255, 50, 50)
local COLOR_CHAIN   = Color(255, 170, 0)
local COLOR_CLEAR   = Color(50, 255, 50)
local COLOR_CONVEX  = Color(255, 220, 0)
local COLOR_PLANE   = Color(255, 50, 50, 60)

-- Draws a trace green up to where it hit and red past it, through walls since these usually run inside a vehicle
local function DrawTrace(Debug, From, HitPos, To, Life)
	Debug.Line(From, HitPos, Life, COLOR_CLEAR, true)
	Debug.Line(HitPos, To, Life, COLOR_DISABLE, true)
	Debug.Sphere(HitPos, 1.5, Life, COLOR_DISABLE, true)
end

-- Boxes and labels the entities the owner has to deal with, such as the seats to sit in
local function DrawTargets(Debug, _, Data, Life)
	for _, Target in ipairs(Data.Targets or {}) do
		Debug.EntityBox(Target, Life, COLOR_CHAIN, true)

		if Data.Label then Debug.EntityText(Target, 0, Data.Label, Life, COLOR_CHAIN) end
	end
end

do -- MARK: Core restrictions
	Register("invalid_physics", {
		Title  = "Invalid Physics",
		Detail = "Custom physics objects are not allowed.",
		Help   = "Remove the custom physics object, such as a spherical one, so the entity uses its normal physics.",
	}, {
		Shame = "having a custom physics object (spherical).",
		Check = function(Entity, EntTbl)
			local Phys = Entity:GetPhysicsObject()

			if IsValid(EntTbl.ACF.PhysObj) and EntTbl.ACF.PhysObj == Phys then return true end
			if not Phys:GetVolume() then return false end

			EntTbl.ACF.PhysObj = Phys -- Updated PhysObj

			return true
		end,
	})

	-- Delayed because the remover tool sets nodraw and removes one second later
	Register("not_solid", {
		Title  = "Not Solid",
		Detail = "Must be solid.",
		Help   = "Undo whatever made the entity non-solid so it is solid again.",
	}, {
		Shame       = "not being solid.",
		NotifyDelay = 1.1,
		Check       = function(Entity)
			return Entity:IsSolid()
		end,
		-- Boxed since the entity itself may be invisible
		Draw        = function(Debug, Entity, _, Life)
			Debug.EntityBox(Entity, Life, COLOR_DISABLE, true)
		end,
	})

	Register("visual_clip", {
		Title  = "Visual Clip",
		Detail = "Visual clips are not allowed.",
		Help   = "Remove the visual clips from this entity.",
	}, {
		Shame = "having visclips.",
		Check = function(Entity, EntTbl)
			local ClipData = EntTbl.ClipData
			if not (ClipData and next(ClipData)) then return true end

			-- Clips store an angle and a distance from the original bounding box center, see ACF.CheckClips
			local Planes = {}
			local Center

			for _, Clip in ipairs(ClipData) do
				local Ang = istable(Clip) and (Clip.n or Clip[1])

				if isangle(Ang) then
					local Normal = Ang:Forward()

					Center = Center or EntTbl.OBBCenterOrg or Entity:OBBCenter()

					Planes[#Planes + 1] = { Normal = Normal, Origin = Center + Normal * (Clip.d or Clip[2] or 0) }
				end
			end

			return false, { Planes = Planes }
		end,
		-- Each clip plane spans the entity, with a short line on the side the clip keeps
		Draw  = function(Debug, Entity, Data, Life)
			local Half = Entity:BoundingRadius()

			for _, Plane in ipairs(Data.Planes) do
				local Origin = Entity:LocalToWorld(Plane.Origin)
				local Normal = Entity:LocalToWorld(Plane.Normal) - Entity:GetPos()
				local Ang    = Normal:Angle()
				local Right  = Ang:Right() * Half
				local Up     = Ang:Up() * Half

				Debug.Triangle(Origin - Right - Up, Origin + Right - Up, Origin + Right + Up, Life, COLOR_PLANE)
				Debug.Triangle(Origin - Right - Up, Origin + Right + Up, Origin - Right + Up, Life, COLOR_PLANE)
				Debug.Line(Origin, Origin + Normal * 6, Life, COLOR_DISABLE, true)
			end
		end,
	})

	Register("cannot_fire", {
		Title  = "Cannot fire",
		Detail = "Disabled by server settings.",
		Help   = "Weapons are disabled by the server settings, so wait or ask an admin to enable them.",
	}, {
		Applies = function(_, EntTbl) return EntTbl.IsACFGun or EntTbl.IsRack end,
		Check   = function(_, EntTbl)
			if EntTbl.IsRack then return ACF.RacksCanFire end

			return ACF.GunsCanFire
		end,
	})
end

do -- MARK: Parenting restrictions
	-- Being parented to a baseplate also makes the engine part of a contraption
	Register("engine_parent", {
		Title  = "Parenting Issue",
		Detail = "Must be parented to a baseplate.",
		Help   = "Parent the engine to the baseplate.",
	}, {
		Applies = function(_, EntTbl) return EntTbl.IsACFEngine and EntTbl.Active and not ACF.AllowArbitraryParents end,
		Check   = function(_, EntTbl) return EntTbl.ACF_EngineParentValid end,
		Draw    = function(Debug, Entity, _, Life)
			local Parent = Entity:GetParent()
			if not IsValid(Parent) then return end

			Debug.EntityLine(Entity, Parent, Life, COLOR_DISABLE, true)
			Debug.EntityText(Parent, 0, "Must be the baseplate", Life, COLOR_DISABLE)
		end,
	})

	local CHAIN_LINKS = { acf_turret = true, acf_turret_rotator = true }

	-- Raised when a lethal tries to fire, see parent_chain_enforcement_sv.lua
	Register("parent_chain", {
		Title  = "Invalid Parent Chain",
		Detail = "Must be parented to a baseplate, optionally through turrets.",
		Help   = "Parent this entity to a baseplate, optionally through turrets and nothing else.",
	}, {
		Timeout = 5,
		-- Green while the chain follows the rule, red from the first broken link
		Draw    = function(Debug, Entity, _, Life)
			local Child, Parent = Entity, Entity:GetParent()
			local Broken        = false

			while IsValid(Parent) do
				local IsRoot = not IsValid(Parent:GetParent())
				local Class  = Parent:GetClass()
				local Valid  = not Broken and (IsRoot and Class == "acf_baseplate" or not IsRoot and CHAIN_LINKS[Class])

				Debug.EntityLine(Child, Parent, Life, Valid and COLOR_CLEAR or COLOR_DISABLE, true)

				if not Valid and not Broken then
					Broken = true

					Debug.EntityText(Parent, 0, IsRoot and "Root must be a baseplate" or "Must be a turret", Life, COLOR_DISABLE)
				end

				Child, Parent = Parent, Parent:GetParent()
			end
		end,
	})

	-- Silent since crew are usually unparented while building
	Register("crew_parent_chain", {
		Title  = "Bad Parent",
		Detail = "Must be parented to a baseplate, optionally through turrets.",
		Help   = "Parent the crew to a baseplate, optionally through turrets.",
	}, {
		Silent  = true,
		Timeout = 0,
		Applies = function(_, EntTbl) return EntTbl.ACF_RequiresParentChain end,
		Check   = function(Entity) return ACF.IsParentChainStateOK(Entity) end,
	})
end

do -- MARK: Weapon restrictions
	Register("breech_clipping", {
		Title  = "Breech Clipping",
		Detail = function(Data)
			return "Blocked by " .. (IsValid(Data.Blocker) and tostring(Data.Blocker) or "another entity") .. "."
		end,
		Help   = "Move the blocking entity away from the breech, or reposition the weapon so its breech is clear.",
	}, {
		Timeout = 30,
		Linger  = true,
		Applies = function(_, EntTbl) return EntTbl.IsACFGun and EntTbl.CheckBreechClipping end,
		Check   = function(Entity) return Entity:CheckBreechClipping() end,
		Draw    = function(Debug, Entity, Data, Life)
			local Reference = Data.Reference
			if not IsValid(Reference) then return end

			local From = Reference:LocalToWorld(Data.From)
			local To   = Entity:LocalToWorld(Data.To)

			if IsValid(Data.Blocker) then Debug.EntityBox(Data.Blocker, Life, COLOR_DISABLE, true) end

			DrawTrace(Debug, From, LerpVector(Data.Fraction or 1, From, To), To, Life)
			Debug.EntityTextAtPosition(From, 0, "Breech at reference", Life, COLOR_CLEAR)
			Debug.EntityTextAtPosition(To, 0, "Breech now", Life, COLOR_DISABLE)
		end,
	})
end

do -- MARK: Overlap restrictions
	-- Raised by the convex sampler in overlap_check_sv.lua, Data positions are local to the entity
	Register("overlap", {
		Title  = "Overlapping",
		Detail = function(Data)
			return "Overlapping with " .. (IsValid(Data.Blocker) and tostring(Data.Blocker) or "another entity") .. "."
		end,
		Help   = "Move the entities apart so their armor meshes no longer overlap.",
	}, {
		Timeout = 30,
		Draw    = function(Debug, Entity, Data, Life)
			-- Drawn at the size points are sampled from, which stays inside the real convex
			local Convex = Data.Convex and Entity.ACF_Volumetric_Mesh and Entity.ACF_Volumetric_Mesh.Convexes[Data.Convex]
			if Convex then Debug.Convex(Entity, Data.Convex, Life, COLOR_CONVEX, true, ACF.ConvexInsetScale(Convex, ACF.OverlapInset)) end
			if Data.BlockerConvex and IsValid(Data.Blocker) then Debug.Convex(Data.Blocker, Data.BlockerConvex, Life, COLOR_DISABLE, true) end
			if not Data.From or not Data.To then return end

			local To = Entity:LocalToWorld(Data.To)

			DrawTrace(Debug, Entity:LocalToWorld(Data.From), Data.HitPos and Entity:LocalToWorld(Data.HitPos) or To, To, Life)
		end,
	})
end

do -- MARK: Lethal restrictions
	-- Raised when a lethal tries to fire, see require_player_in_contraption_sv.lua and block_crewless_lethals.lua
	Register("lethal_no_contraption", {
		Title  = "No Contraption",
		Detail = "Must be part of a contraption.",
		Help   = "Connect the weapon to the rest of the vehicle by welding or parenting it.",
	}, {
		Timeout = 5,
	})

	Register("lethal_no_player", {
		Title  = "No Player Seated",
		Detail = function(Data)
			if not Data.Targets or not Data.Targets[1] then
				return "Add a seat and sit in it."
			end

			return "Sit in a marked seat."
		end,
		Help   = "Add a seat to the contraption and sit in it.",
	}, {
		Timeout = 5,
		Draw    = DrawTargets,
	})

	Register("lethal_crew_killed", {
		Title  = "Crew Killed",
		Detail = "All crew are dead.",
		Help   = "Replace the crew, lethal weapons cannot be used while every crew member is dead.",
	}, {
		Timeout = 5,
		Draw    = DrawTargets,
	})

	Register("lethal_crewless", {
		Title  = "No Crew",
		Detail = "Contraption has no crew.",
		Help   = "Add crew members to the contraption.",
	}, {
		Timeout = 5,
	})
end

do -- MARK: Seat restrictions
	Register("seat_model", {
		Title  = "Bad Seat Model",
		Detail = "Seat model not allowed.",
		Help   = "Replace the seat with one of the allowed seat models.",
	}, {
		Applies = function(Entity, EntTbl)
			if not ACF.VehicleLegalChecks then return false end
			if not Entity:IsVehicle() or not EntTbl.VehicleTable then return false end

			return not (EntTbl.ACF and EntTbl.ACF.LuaGeneratedSeat) -- Crew/Baseplate seat bypass
		end,
		Check   = function(Entity, EntTbl)
			local ModelPath = Entity:GetModel()

			if ACF.ValidSeatModels[ModelPath] or ModelPath == EntTbl.VehicleTable.Model then return true end

			return false, { Model = ModelPath }
		end,
		Label   = function(Data) return Data.Model end,
	})
end

do -- MARK: Chip and tool restrictions
	-- Raised by the detours in legality_detours_sv.lua, Data.Call names the blocked function and Data.Source the caller
	Register("blocked_call", {
		Title  = "Blocked Call",
		Detail = function(Data)
			return (IsValid(Data.Source) and tostring(Data.Source) or "A chip or tool") .. " used " .. (Data.Call or "a blocked function") .. "."
		end,
		Help   = "Remove or change the call, chips and tools cannot use that function on ACF entities.",
	}, {
		Label   = function(Data) return Data.Chip and Data.Chip .. ": " .. tostring(Data.Call) or Data.Call end,
		Timeout = 10,
		-- Points at the chip, gate or entity that made the call
		Draw    = function(Debug, Entity, Data, Life)
			if not IsValid(Data.Source) then return end

			Debug.EntityLine(Entity, Data.Source, Life, COLOR_CHAIN, true)
			Debug.EntityBox(Data.Source, Life, COLOR_DISABLE, true)
		end,
	})
end

do -- MARK: Restrictions raised from outside the registry
	-- Returned by ENT:ACF_IsLegal or the ACF_OnCheckLegal hook, Data carries the reason and message
	Register("external", {
		Title  = "Disabled",
		Detail = "Disabled by a server rule.",
		Help   = "A server rule disabled this entity, so check the rules or ask an admin.",
	}, {
		Check = function(Entity, EntTbl)
			local Legal, Reason, Message, Timeout

			if EntTbl.ACF_IsLegal then
				Legal, Reason, Message, Timeout = Entity:ACF_IsLegal()
			end

			-- The hook may override a passing entity check, but not a failing one
			if Legal ~= false then
				Legal, Reason, Message, Timeout = hook.Run("ACF_OnCheckLegal", Entity, Legal, Reason, Message, Timeout)
			end

			if Legal then return true end

			return false, { Title = Reason, Detail = Message }, Timeout
		end,
	})
end
