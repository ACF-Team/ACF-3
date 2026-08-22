DEFINE_BASECLASS("acf_base_scalable")

ENT.PrintName       = "ACF Container"
ENT.WireDebugName   = "ACF Container"
ENT.PluralName      = "ACF Containers"
ENT.IsACFContainer  = true

-- Shape model definitions
local ShapeModels = {
	Box      = "models/acf/core/s_fuel.mdl",
	Sphere   = "models/acf/core/s_sphere.mdl",
	Cylinder = "models/acf/core/s_fuel_cyl.mdl"
}

-- Shape calculation functions
-- Each returns: Volume (cu in)
local ShapeCalculations = {
	-- Cuboid/Box shape
	Box = function(Size)
		return Size.x * Size.y * Size.z
	end,

	-- Sphere/Spheroid shape
	Sphere = function(Size)
		local a = Size.x / 2  -- Semi-axis X
		local b = Size.y / 2  -- Semi-axis Y
		local c = Size.z / 2  -- Semi-axis Z

		-- Volume of ellipsoid: (4/3) * pi * a * b * c
		return (4 / 3) * math.pi * a * b * c
	end,

	-- Cylinder/Elliptical Cylinder shape
	Cylinder = function(Size)
		local a = Size.x / 2  -- Semi-axis X (radius in X direction)
		local b = Size.y / 2  -- Semi-axis Y (radius in Y direction)
		local h = Size.z      -- Height

		-- Volume of elliptical cylinder: pi * a * b * h
		return math.pi * a * b * h
	end,

	-- Alias for backwards compatibility
	Drum = function(Size)
		return ShapeCalculations.Cylinder(Size)
	end,
}

ACF.ContainerShapes      = ShapeCalculations
ACF.ContainerShapeModels = ShapeModels
