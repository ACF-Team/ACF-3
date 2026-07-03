-- Sets/gets the armor thickness of a live primitive_shape entity, keyed by its PrimTYPE.
-- Hollow shapes (cube_magic, dome_hollow, torus, tube) already have a wall-thickness var (PrimDT).
-- Solid shapes (cube, cube_hole) have no such var, so "thickness" means resizing along whichever
-- local axis faces the given normal, keeping the face under the crosshair fixed in place.
-- Setting PrimSIZE/PrimDT via their generated setters queues the entity's own mesh/physics
-- rebuild automatically (see primitive/entities/base.lua's NetworkVarNotify wiring), so no
-- explicit rebuild call is needed here.
return function()
	local MinSize = Primitive.minSize

	local Registry = {}

	local function RegisterThicknessApply(Shape, Apply)
		Registry[Shape] = Apply
	end

	local function GetThicknessApply(Shape)
		return Registry[Shape]
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
	local function ApplySolidThickness(Primitive, Thickness, Normal)
		if not Normal then return end

		local Axis, AxisDir = GetNormalAxis(Primitive, Normal)
		local OldSize      = Primitive:GetPrimSIZE()
		local NewThickness = math.max(Thickness, MinSize)

		Primitive:SetPos(Primitive:GetPos() + AxisDir * (NewThickness - OldSize[Axis]) * -0.5)

		local NewSize = Vector(OldSize)
		NewSize[Axis] = NewThickness
		Primitive:SetPrimSIZE(NewSize)
	end

	local function ApplyHollowThickness(Primitive, Thickness)
		Primitive:SetPrimDT(math.max(Thickness, MinSize))
	end

	RegisterThicknessApply("cube", ApplySolidThickness)
	RegisterThicknessApply("cube_hole", ApplySolidThickness)
	RegisterThicknessApply("cube_magic", ApplyHollowThickness)
	RegisterThicknessApply("dome_hollow", ApplyHollowThickness)
	RegisterThicknessApply("torus", ApplyHollowThickness)
	RegisterThicknessApply("tube", ApplyHollowThickness)

	-- Reads the thickness back, mirroring how Apply would set it (used by the eyedropper).
	local function GetThickness(Primitive, Normal)
		local Shape = Primitive:GetPrimTYPE()
		if not Registry[Shape] then return nil end

		if Shape == "cube" or Shape == "cube_hole" then
			if not Normal then return nil end
			local Axis = GetNormalAxis(Primitive, Normal)
			return Primitive:GetPrimSIZE()[Axis]
		end

		return Primitive:GetPrimDT()
	end

	return {
		RegisterThicknessApply = RegisterThicknessApply,
		GetThicknessApply      = GetThicknessApply,
		GetThickness           = GetThickness,
	}
end
