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

	local SpropPrimitiveConversions = {}

	local function RegisterConversion(pattern, convert)
		table.insert(SpropPrimitiveConversions, { pattern = pattern, convert = convert })
	end

	local function GetSpropConversion(Model)
		for _, v in ipairs(SpropPrimitiveConversions) do
			if string.find(Model, v.pattern) then return v.convert end
		end
	end

	local function GetLocalSize(Entity)
		local AMi, AMa = Entity:GetPhysicsObject():GetAABB()
		return AMa - AMi
	end

	-- Resizes Size along its thinnest local axis to Thickness (if given), returning the
	-- world Pos adjusted so the face furthest from BasePos stays put.
	local function ApplyThinAxisThickness(Entity, Size, Thickness, BasePos)
		local Pos = Entity:GetPos()

		local ThinAxis = 1
		if Size[2] < Size[ThinAxis] then ThinAxis = 2 end
		if Size[3] < Size[ThinAxis] then ThinAxis = 3 end

		local AxisDir
		if ThinAxis == 1 then AxisDir = Entity:GetForward()
		elseif ThinAxis == 2 then AxisDir = Entity:GetRight()
		else AxisDir = Entity:GetUp() end

		if (Pos - BasePos):Dot(AxisDir) < 0 then AxisDir = -AxisDir end

		if Thickness then
			local OriginalThickness = Size[ThinAxis]
			Pos            = Pos + AxisDir * (Thickness - OriginalThickness) * -0.5
			Size[ThinAxis] = Thickness
		end

		return Pos
	end

	local function ConvertCube(Entity, Thickness, BasePos)
		local Size  = GetLocalSize(Entity)
		local Angle = Entity:GetAngles()
		local Pos   = ApplyThinAxisThickness(Entity, Size, Thickness, BasePos)

		return {
			Type = "cube", Pos = Pos, Angle = Angle, Size = Size,
			DT = { PrimMESHSMOOTH = 0, PrimTX = 0, PrimTY = 0 }
		}
	end

	RegisterConversion("^models/sprops/rectangles", ConvertCube)
	RegisterConversion("^models/sprops/cuboids", ConvertCube)

	RegisterConversion("^models/sprops/cylinders", function(Entity)
		local Pos, Angle = Entity:GetPos(), Entity:GetAngles()
		return {
			Type = "cylinder", Pos = Pos, Angle = Angle, Size = GetLocalSize(Entity),
			DT = { PrimMAXSEG = 16, PrimMESHSMOOTH = 65, PrimNUMSEG = 16, PrimTX = 0, PrimTY = 0 }
		}
	end)

	RegisterConversion("^models/sprops/misc/sq_holes", function(Entity, Thickness, BasePos)
		local Size  = GetLocalSize(Entity)
		local Angle = Entity:GetAngles()
		local Pos   = ApplyThinAxisThickness(Entity, Size, Thickness, BasePos)

		return {
			Type = "cube_hole", Pos = Pos, Angle = Angle, Size = Size,
			DT = { PrimDT = 4, PrimMESHSMOOTH = 65, PrimNUMSEG = 4, PrimSUBDIV = 16 }
		}
	end)

	RegisterConversion("^models/sprops/misc/cones", function(Entity)
		local Pos, Angle = Entity:GetPos(), Entity:GetAngles()
		return {
			Type = "cone", Pos = Pos, Angle = Angle, Size = GetLocalSize(Entity),
			DT = { PrimMAXSEG = 16, PrimMESHSMOOTH = 45, PrimNUMSEG = 16, PrimTX = 0, PrimTY = 0 }
		}
	end)

	RegisterConversion("^models/sprops/misc/domes", function(Entity)
		local Pos, Angle = Entity:GetPos(), Entity:GetAngles()
		return {
			Type = "dome", Pos = Pos, Angle = Angle, Size = GetLocalSize(Entity),
			DT = { PrimMESHSMOOTH = 65, PrimSUBDIV = 8 }
		}
	end)

	RegisterConversion("sprops/misc/tubes/.-/tube_", function(Entity, Thickness)
		local RawSize = GetLocalSize(Entity)
		local Size = Vector(RawSize.x, RawSize.z, RawSize.y)
		local Pos, Angle = Entity:GetPos(), Entity:LocalToWorldAngles(Angle(0, 0, 90))
		return {
			Type = "tube", Pos = Pos, Angle = Angle, Size = Size,
			DT = { PrimDT = Thickness or 4, PrimMAXSEG = 16, PrimMESHSMOOTH = 65, PrimNUMSEG = 16, PrimTX = 0, PrimTY = 0 }
		}
	end)

	RegisterConversion("sprops/misc/tubes/.-/h_tube_", function(Entity, Thickness)
		local RawSize = GetLocalSize(Entity)
		local Size = Vector(RawSize.x * 2, RawSize.x * 2, RawSize.y)
		local LocalOffset = Vector(0, 0, -0.5 * RawSize.z)
		local Pos, Angle = Entity:LocalToWorld(LocalOffset), Entity:LocalToWorldAngles(Angle(0, 0, 90))
		return {
			Type = "tube", Pos = Pos, Angle = Angle, Size = Size,
			DT = { PrimDT = Thickness or 4, PrimMAXSEG = 16, PrimMESHSMOOTH = 65, PrimNUMSEG = 8, PrimTX = 0, PrimTY = 0}
		}
	end)

	RegisterConversion("sprops/misc/tubes/.-/q_tube_", function(Entity, Thickness)
		local RawSize = GetLocalSize(Entity)
		local Size = Vector(RawSize.x * 2, RawSize.x * 2, RawSize.y)
		local LocalOffset = Vector(0.5 * RawSize.x, 0, -0.5 * RawSize.x)
		print(Entity)
		local Pos, Angle = Entity:LocalToWorld(LocalOffset), Entity:LocalToWorldAngles(Angle(0, 0, 90))
		return {
			Type = "tube", Pos = Pos, Angle = Angle, Size = Size,
			DT = { PrimDT = Thickness or 4, PrimMAXSEG = 16, PrimMESHSMOOTH = 65, PrimNUMSEG = 4, PrimTX = 0, PrimTY = 0 }
		}
	end)

	RegisterConversion("sprops/geometry/t?_?[fhq]disc_", function(Entity)
		local RawSize = GetLocalSize(Entity)
		local Size = Vector(RawSize.x, RawSize.x, RawSize.y)
		local Pos, Angle = Entity:GetPos(), Entity:LocalToWorldAngles(Angle(0, 0, 90))
		return {
			Type = "cylinder", Pos = Pos, Angle = Angle, Size = Size,
			DT = { PrimMAXSEG = 16, PrimMESHSMOOTH = 65, PrimNUMSEG = 16, PrimTX = 0, PrimTY = 0 }
		}
	end)

	local PrimitiveModel = "models/combine_helicopter/helicopter_bomb01.mdl"

	-- Classes that are already volumetric in nature, so they should never be reconsidered for legacy
	-- sprop-to-primitive conversion (e.g. a primitive that retained a stale ACF_Armor entity modifier).
	local LegacyArmorClassBlacklist = {
		["primitive_shape"] = true,
		["primitive_airfoil"] = true,
		["primitive_rail_slider"] = true,
		["primitive_ladder"] = true,
		["primitive_staircase"] = true,
		["sent_prop2mesh"] = true,
	}

	-- Builds the DT (networked var) table Primitive entities restore themselves from on paste, starting
	-- from the conversion function's own Overrides (its per-type Prim* vars, mirroring the defaults
	-- Primitive's own tool applies on spawn -- see lua/primitive/entities/shapes.lua) since pasted
	-- primitives skip that setup and rely entirely on this DT table to restore their networked vars.
	local function BuildPrimitiveDT(Type, Size, Overrides)
		local DT = Overrides and table.Copy(Overrides) or {}

		DT.PrimTYPE      = Type
		DT.PrimSIZE      = Size
		DT.PrimMESHPHYS  = true
		DT.PrimMESHUV    = 48
		DT.PrimMESHENUMS = 1
		DT.PrimMESHPOS   = vector_origin
		DT.PrimMESHROT   = angle_zero

		return DT
	end

	function ACF.SpropToPrimitive(Entity, Thickness, BasePos)
		if not IsValid(Entity:GetPhysicsObject()) then return nil end

		local Convert = GetSpropConversion(Entity:GetModel())
		if not Convert then return nil end

		return Convert(Entity, Thickness, BasePos)
	end

	-- Swaps a captured AdvDupe2 entity entry into a primitive_shape, matching how ConvertBaseplate swaps
	-- a captured entry's Class between acf_baseplate/prop_physics. PhysicsObjects[0] carries the actual
	-- restore position/angle (Pos/Angle are recomputed from it on paste), and DT carries the primitive's
	-- networked vars, restored via Entity:RestoreNetworkVars on creation.
	local function ApplyPrimitiveToDupeEntry(Data, Entity, Primitive)
		Data.Class = "primitive_shape"
		Data.Model = PrimitiveModel
		Data.Pos   = Primitive.Pos
		Data.Angle = Primitive.Angle
		Data.DT    = BuildPrimitiveDT(Primitive.Type, Primitive.Size, Primitive.DT)

		Data.PhysicsObjects[0].Pos   = Primitive.Pos
		Data.PhysicsObjects[0].Angle = Primitive.Angle

		-- Re-express each proper_clipping plane against the primitive's new pose, replacing the stale
		-- modifiers AreaCopy captured. proper_clipping cross-checks its two duplicator formats on paste,
		-- so both must be written and agree; compat `d` equals the distance since the OBB center is the origin.
		if Entity.ClipData and next(Entity.ClipData) then
			Data.EntityMods = Data.EntityMods or {}

			local OldPos, OldAngle = Entity:GetPos(), Entity:GetAngles()

			local Native, Compat = {}, {}
			for i, clip in ipairs(Entity.ClipData) do
				local WorldNorm = Vector(clip.norm)
				WorldNorm:Rotate(OldAngle)
				local WorldPoint = OldPos + WorldNorm * clip.dist

				local _, LocalAng = WorldToLocal(vector_origin, WorldNorm:Angle(), vector_origin, Primitive.Angle)
				local Norm = LocalAng:Forward()
				local Dist = WorldNorm:Dot(WorldPoint - Primitive.Pos)

				Native[i] = { Norm, Dist, clip.inside, clip.physics }
				Compat[i] = { n = Norm:Angle(), d = Dist, inside = clip.inside, new = true }
			end

			Data.EntityMods["proper_clipping"] = Native
			Data.EntityMods["clips"] = Compat
		end
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
			if ent.ACF_Armor_Legacy_Thickness and not LegacyArmorClassBlacklist[ent:GetClass()] and not ent._IsSpherical and not ent.IsWire then
				-- ACF_Armor_Legacy_Thickness is in millimeters; geometry here is all in inches
				local Thickness = ent.ACF_Armor_Legacy_Thickness ~= 0 and (ent.ACF_Armor_Legacy_Thickness / 25.4)
				local Primitive = ACF.SpropToPrimitive(ent, Thickness, BasePos)
				if Primitive then
					ApplyPrimitiveToDupeEntry(Entities[index], ent, Primitive)
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
