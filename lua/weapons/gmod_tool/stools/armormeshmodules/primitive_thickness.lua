-- Sets/gets the armor thickness of a live primitive_shape entity, keyed by its PrimTYPE.
-- Hollow shapes (cube_magic, dome_hollow, torus, tube) already have a wall-thickness var (PrimDT).
-- Solid shapes (cube, cube_hole) have no such var, so "thickness" means resizing along whichever
-- local axis faces the given normal, keeping the face under the crosshair fixed in place.
-- Setting PrimSIZE/PrimDT via their generated setters queues the entity's own mesh/physics
-- rebuild automatically (see primitive/entities/base.lua's NetworkVarNotify wiring), so no
-- explicit rebuild call is needed here.
return function()
	local Notify  = ACF.Utilities.Notify
	local MinSize = Primitive.minSize

	local Registry = {}

	-- Multiplier compensates for shapes where PrimDT doesn't map 1:1 to the actually measured
	-- wall thickness (e.g. faceting/diagonal-offset quirks) -- see the per-shape comments below.
	local function RegisterThicknessApply(Shape, Apply, Multiplier)
		Registry[Shape] = { Apply = Apply, Multiplier = Multiplier or 1 }
	end

	local function GetThicknessApply(Shape)
		local Entry = Registry[Shape]
		if not Entry then return nil end

		return function(Primitive, Thickness, Normal, Player)
			return Entry.Apply(Primitive, Thickness * Entry.Multiplier, Normal, Player)
		end
	end

	-- Finds which local axis is most aligned with Normal (the face under the crosshair), and
	-- returns that axis' world-space direction flipped to point the same way as Normal.
	local function GetNormalAxis(Primitive, Normal)
		local Forward, Right, Up = Primitive:GetForward(), Primitive:GetRight(), Primitive:GetUp()
		local Axis, AxisDir = 1, Forward

		if math.abs(Normal:Dot(Right)) > math.abs(Normal:Dot(AxisDir)) then Axis, AxisDir = 2, Right end
		if math.abs(Normal:Dot(Up)) > math.abs(Normal:Dot(AxisDir)) then Axis, AxisDir = 3, Up end

		if Normal:Dot(AxisDir) < 0 then AxisDir = -AxisDir end

		return Axis, AxisDir
	end

	-- Resizes Primitive along the axis facing Normal, shifting its position so the face under
	-- the crosshair stays put and only the opposite face moves.
	local function ResizeAlongNormal(Primitive, Thickness, Normal, Player)
		if not Normal then return end

		local NewThickness = math.max(Thickness, MinSize)
		if NewThickness ~= Thickness then
			Notify.WarningToPlayer(Player, "Thickness clamped", string.format("Thickness cannot go below %.1f mm, set to that instead.", MinSize * 25.4, NewThickness * 25.4))
		end

		local Axis, AxisDir = GetNormalAxis(Primitive, Normal)
		local OldSize = Primitive:GetPrimSIZE()

		local NewPos = Primitive:GetPos() + AxisDir * (NewThickness - OldSize[Axis]) * -0.5
		Primitive:SetPos(IsValid(Primitive:GetParent()) and Primitive:GetParent():WorldToLocal(NewPos) or NewPos)

		local NewSize = Vector(OldSize)
		NewSize[Axis] = NewThickness
		Primitive:SetPrimSIZE(NewSize)
	end

	RegisterThicknessApply("cone", ResizeAlongNormal)
	RegisterThicknessApply("cube", ResizeAlongNormal)
	RegisterThicknessApply("cube_hole", ResizeAlongNormal)
	RegisterThicknessApply("dome", ResizeAlongNormal)
	RegisterThicknessApply("parallelogram", ResizeAlongNormal)
	RegisterThicknessApply("pyramid", ResizeAlongNormal)
	RegisterThicknessApply("sphere", ResizeAlongNormal)
	RegisterThicknessApply("torus", ResizeAlongNormal)
	RegisterThicknessApply("wedge", ResizeAlongNormal)
	RegisterThicknessApply("wedge_corner", ResizeAlongNormal)

	-- cube_magic hollows each corner inward along its own center-to-corner diagonal instead of
	-- the face normal (see construct.lua's cube_magic builder), so a straight PrimDT undershoots
	-- the wall thickness actually measured perpendicular to the face under the crosshair by a
	-- factor of axis_half_extent/diagonal_half_extent. Scale PrimDT up to compensate.
	RegisterThicknessApply("cube_magic", function(Primitive, Thickness, Normal)
		if not Normal then return end

		local HalfExtents = Primitive:GetPrimSIZE() * 0.5
		local Axis        = GetNormalAxis(Primitive, Normal)

		Primitive:SetPrimDT(Thickness * HalfExtents:Length() / HalfExtents[Axis])
	end)

	local function SetHollowThickness(Primitive, Thickness)
		Primitive:SetPrimDT(Thickness)
	end

	-- 2.79520 measured empirically -- dome_hollow's polar-cap faceting means the correction
	-- isn't a clean closed form (see chat), so this is fit rather than derived.
	RegisterThicknessApply("dome_hollow", SetHollowThickness, 2.79520)
	RegisterThicknessApply("tube", SetHollowThickness)

	-- Reads the thickness back, mirroring how Apply would set it (used by the eyedropper).
	local function GetThickness(Primitive, Normal)
		local Shape = Primitive:GetPrimTYPE()
		local Entry = Registry[Shape]
		if not Entry then return nil end

		if Shape == "cube" or Shape == "cube_hole" then
			if not Normal then return nil end
			local Axis = GetNormalAxis(Primitive, Normal)
			return Primitive:GetPrimSIZE()[Axis]
		end

		return Primitive:GetPrimDT() / Entry.Multiplier
	end

	return {
		RegisterThicknessApply = RegisterThicknessApply,
		GetThicknessApply      = GetThicknessApply,
		GetThickness           = GetThickness,
	}
end
