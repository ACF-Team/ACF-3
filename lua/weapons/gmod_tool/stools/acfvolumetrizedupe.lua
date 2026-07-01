local ACF = ACF
local IsValid = IsValid

TOOL.Category   = (ACF and ACF.CustomToolCategory and ACF.CustomToolCategory:GetBool()) and "ACF" or "Construction"
TOOL.Name       = "#tool.acfvolumetrizedupe.name"
TOOL.Command    = nil
TOOL.ConfigName = ""
TOOL.Information = {
	{ name = "left0", stage = 0 },
}

if CLIENT then
	language.Add("tool.acfvolumetrizedupe.name", "ACF Volumetrize Dupe")
	language.Add("tool.acfvolumetrizedupe.desc", "Area copies and pastes the targeted ACF baseplate's contraption through Advanced Duplicator 2")
	language.Add("tool.acfvolumetrizedupe.left0", "Area copy and paste the targeted ACF baseplate's contraption")
elseif SERVER then
	local Notify = ACF.Utilities.Notify

	-- Maps legacy sprop model paths to the primitive shape type they should become. Entries match either
	-- a literal path prefix (startWith) or a Lua pattern found anywhere in the path (find), for cases like
	-- geometry/ which mixes discs (cylinders) in with hexes/rings/spheres under one folder.
	local SpropPrimitiveModelPaths = {
		{ startWith = "models/sprops/rectangles", type = "cube" },
		{ startWith = "models/sprops/cylinders", type = "cylinder" },
		{ startWith = "models/sprops/misc/sq_holes", type = "cube_hole" },
		{ startWith = "models/sprops/misc/cones", type = "cone" },
		{ startWith = "models/sprops/misc/domes", type = "dome" },
		{ startWith = "models/sprops/misc/tubes", type = "tube" },
		{ find = "sprops/geometry/t?_?[fhq]disc_", type = "cylinder" },
	}

	local function GetSpropPrimitiveType(Model)
		for _, v in ipairs(SpropPrimitiveModelPaths) do
			if v.startWith and string.StartsWith(Model, v.startWith) then return v.type end
			if v.find and string.find(Model, v.find) then return v.type end
		end
	end

	-- Extra Prim* vars per type, mirroring the defaults Primitive's own tool applies on spawn
	-- (lua/primitive/entities/shapes.lua), since pasted primitives skip that setup and rely
	-- entirely on the DT table below to restore their networked vars.
	local PrimitiveTypeDefaults = {
		cube = {
			PrimMESHSMOOTH = 0,
			PrimTX = 0,
			PrimTY = 0,
		},
		cylinder = {
			PrimMAXSEG     = 16,
			PrimMESHSMOOTH = 65,
			PrimNUMSEG     = 16,
			PrimTX         = 0,
			PrimTY         = 0,
		},
		cube_hole = {
			PrimDT         = 4,
			PrimMESHSMOOTH = 65,
			PrimNUMSEG     = 4,
			PrimSUBDIV     = 16,
		},
		cone = {
			PrimMAXSEG     = 16,
			PrimMESHSMOOTH = 45,
			PrimNUMSEG     = 16,
			PrimTX         = 0,
			PrimTY         = 0,
		},
		dome = {
			PrimMESHSMOOTH = 65,
			PrimSUBDIV     = 8,
		},
		tube = {
			PrimDT         = 4,
			PrimMAXSEG     = 16,
			PrimMESHSMOOTH = 65,
			PrimNUMSEG     = 16,
			PrimTX         = 0,
			PrimTY         = 0,
		},
	}

	local PrimitiveModel = "models/combine_helicopter/helicopter_bomb01.mdl"

	-- Builds the DT (networked var) table Primitive entities restore themselves from on paste.
	local function BuildPrimitiveDT(Type, Size)
		local DT = table.Copy(PrimitiveTypeDefaults[Type] or {})

		DT.PrimTYPE      = Type
		DT.PrimSIZE      = Size
		DT.PrimMESHPHYS  = true
		DT.PrimMESHUV    = 48
		DT.PrimMESHENUMS = 1
		DT.PrimMESHPOS   = vector_origin
		DT.PrimMESHROT   = angle_zero

		return DT
	end

	-- Describes the primitive that should replace Entity. Only cubes are pushed outward and stretched
	-- (everything else is mapped over as-is); the thickness axis is whichever local axis is thinnest
	-- (the plate's actual armor direction) -- the vector from BasePos to Entity is only used to pick
	-- which of the two signs along that axis points outward, since for plates far from the baseplate
	-- (e.g. long hull plates) that vector is dominated by length, not thickness, and picking the axis
	-- from it directly can grab an in-plane axis instead.
	function ACF.SpropToPrimitive(Entity, BasePos, Thickness)
		local Type = GetSpropPrimitiveType(Entity:GetModel())
		if not Type then return end

		local PhysObj = Entity:GetPhysicsObject()
		if not IsValid(PhysObj) then return end

		-- OBBMins/OBBMaxs pad sprops models by ~0.5 units per axis over their actual collision size,
		-- so use the physics object's local AABB instead, same as ACF.ConvertBaseplate does.
		local AMi, AMa = PhysObj:GetAABB()
		local Size = AMa - AMi

		local Pos   = Entity:GetPos()
		local Angle = Entity:GetAngles()

		if Type == "cube" then
			local ThinAxis = 1
			if Size[2] < Size[ThinAxis] then ThinAxis = 2 end
			if Size[3] < Size[ThinAxis] then ThinAxis = 3 end

			local AxisDir
			if ThinAxis == 1 then AxisDir = Entity:GetForward()
			elseif ThinAxis == 2 then AxisDir = Entity:GetRight()
			else AxisDir = Entity:GetUp() end

			-- Flip the axis direction so it points away from the baseplate
			if (Pos - BasePos):Dot(AxisDir) < 0 then AxisDir = -AxisDir end

			-- Push the cube outward and stretch it along the thickness axis
			Pos            = Pos - AxisDir * (Thickness * 0.5)
			Size[ThinAxis] = Size[ThinAxis] + Thickness
		end

		return { Type = Type, Pos = Pos, Angle = Angle, Size = Size }
	end

	-- Swaps a captured AdvDupe2 entity entry into a primitive_shape, matching how ConvertBaseplate swaps
	-- a captured entry's Class between acf_baseplate/prop_physics. PhysicsObjects[0] carries the actual
	-- restore position/angle (Pos/Angle are recomputed from it on paste), and DT carries the primitive's
	-- networked vars, restored via Entity:RestoreNetworkVars on creation.
	local function ApplyPrimitiveToDupeEntry(Data, Primitive)
		Data.Class = "primitive_shape"
		Data.Model = PrimitiveModel
		Data.Pos   = Primitive.Pos
		Data.Angle = Primitive.Angle
		Data.DT    = BuildPrimitiveDT(Primitive.Type, Primitive.Size)

		Data.PhysicsObjects[0].Pos   = Primitive.Pos
		Data.PhysicsObjects[0].Angle = Primitive.Angle
	end

	-- TODO: What can we merge between this and ACF.ConvertBaseplate?

	-- Round-trips the targeted baseplate's contraption through an AdvDupe2 area copy/paste, converting any
	-- legacy sprop armor entities into primitives along the way.
	function ACF.ConvertVolumetric(Player, Target)
		if not AdvDupe2 then return false, "Advanced Duplicator 2 is not installed" end

		if not IsValid(Target) then return false, "Invalid target" end

		local Owner = Target:CPPIGetOwner()
		if not IsValid(Owner) or Owner ~= Player then return false, "You do not own this entity" end

		local PhysObj = Target:GetPhysicsObject()
		if not IsValid(PhysObj) then return false, "Entity is not physical" end

		if Target:GetClass() ~= "acf_baseplate" then
			return false, "Incompatible entity class '" .. Target:GetClass() .. "'"
		end

		-- Determine which entities to area copy
		local EntsByIndex = {}
		local Contraption = Target:CFW_GetContraption()
		if Contraption then
			-- Save everything including turrets through contraption data
			for ent, _ in pairs(Contraption.ents) do EntsByIndex[ent:EntIndex()] = ent end
		else
			-- Otherwise, just the baseplate entity
			EntsByIndex[Target:EntIndex()] = Target
		end

		-- Perform the area copy and retrieve the dupe table
		local Entities, Constraints = AdvDupe2.duplicator.AreaCopy(Player, EntsByIndex, vector_origin, false)

		-- Convert legacy sprop armor entities into primitives within the captured dupe table
		local BasePos = Target:GetPos() + Vector(0, 0, 24)
		for index, ent in pairs(EntsByIndex) do
			if ent.ACF_Armor_Legacy_Thickness then
				-- ACF_Armor_Legacy_Thickness is in millimeters; geometry here is all in inches
				local Thickness = ent.ACF_Armor_Legacy_Thickness / 25.4
				local Primitive = ACF.SpropToPrimitive(ent, BasePos, Thickness)
				if Primitive then
					ApplyPrimitiveToDupeEntry(Entities[index], Primitive)
				else
					Notify.WarningToPlayer(Player, string.format("[ACF Volumetrize] No primitive mapping for model '%s' (entity %d)", ent:GetModel(), index))
				end
			end
		end

		-- Delete everything now
		for k, _ in pairs(Entities) do
			local e = Entity(k)
			if IsValid(e) then e:Remove() end
		end

		-- Paste the dupe back, with any swapped-in primitives included
		AdvDupe2.duplicator.Paste(Owner, Entities, Constraints, vector_origin, angle_zero, vector_origin, true)

		return true
	end

	function TOOL:LeftClick(Trace)
		local Entity = Trace.Entity
		if not IsValid(Entity) then return false end

		local Player = self:GetOwner()
		local Success, Message = ACF.ConvertVolumetric(Player, Entity)

		if not Success then
			Notify.WarningToPlayer(Player, "Could not volumetrize", Message)
			return false
		end

		Notify.NoticeToPlayer(Player, "Successfully volumetrized the dupe.")

		return true
	end

	function TOOL:RightClick(_) return false end
end
