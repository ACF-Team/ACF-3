DEFINE_BASECLASS("acf_base_scalable")

ENT.PrintName       = "ACF Container"
ENT.WireDebugName   = "ACF Container"
ENT.PluralName      = "ACF Containers"
ENT.IsACFContainer  = true

ENT.RenderGroup = RENDERGROUP_BOTH

-- Shape model definitions
local ShapeModels = {
	Box      = "models/acf/core/s_fuel.mdl",
	Sphere   = "models/acf/core/s_sphere.mdl",
	Cylinder = "models/acf/core/s_fuel_cyl.mdl"
}

-- Shape calculation functions
-- Each returns: InteriorVolume (cu in), SurfaceArea (sq in)
local ShapeCalculations = {
	-- Cuboid/Box shape
	Box = function(Size, Wall)
		local sx, sy, sz = Size.x, Size.y, Size.z
		local InteriorVolume = math.max(0, (sx - 2 * Wall) * (sy - 2 * Wall) * (sz - 2 * Wall))
		local Area = 2 * (sx * sy + sx * sz + sy * sz)

		return InteriorVolume, Area
	end,

	-- Sphere/Spheroid shape
	Sphere = function(Size, Wall)
		local a = Size.x / 2  -- Semi-axis X
		local b = Size.y / 2  -- Semi-axis Y
		local c = Size.z / 2  -- Semi-axis Z

		local ai = math.max(0, a - Wall)
		local bi = math.max(0, b - Wall)
		local ci = math.max(0, c - Wall)

		-- Volume of ellipsoid: (4/3) * π * a * b * c
		local InteriorVolume = (4 / 3) * math.pi * ai * bi * ci

		-- Surface area approximation using Knud Thomsen's formula
		-- More accurate than simple approximations for ellipsoids
		local p = 1.6075
		local Area = 4 * math.pi * math.pow((math.pow(a * b, p) + math.pow(a * c, p) + math.pow(b * c, p)) / 3, 1 / p)

		return InteriorVolume, Area
	end,

	-- Cylinder/Elliptical Cylinder shape
	Cylinder = function(Size, Wall)
		local a = Size.x / 2  -- Semi-axis X (radius in X direction)
		local b = Size.y / 2  -- Semi-axis Y (radius in Y direction)
		local h = Size.z      -- Height

		local ai = math.max(0, a - Wall)
		local bi = math.max(0, b - Wall)
		local hi = math.max(0, h - 2 * Wall)

		-- Volume of elliptical cylinder: π * a * b * h
		local InteriorVolume = math.pi * ai * bi * hi

		-- Surface area approximation using Ramanujan's formula for ellipse perimeter
		local h_ellipse = math.pow((a - b) / (a + b), 2)
		local Perimeter = math.pi * (a + b) * (1 + (3 * h_ellipse) / (10 + math.sqrt(4 - 3 * h_ellipse)))
		local LateralArea = Perimeter * h
		local EndArea = math.pi * a * b
		local Area = LateralArea + 2 * EndArea

		return InteriorVolume, Area
	end,

	-- Alias for backwards compatibility
	Drum = function(Size, Wall)
		return ShapeCalculations.Cylinder(Size, Wall)
	end,
}

ACF.ContainerShapes      = ShapeCalculations
ACF.ContainerShapeModels = ShapeModels
