ACF.Classes.DefineClass("ACF.ContainerShapes.Sphere", "ACF.ContainerShapes.BaseContainerShape", function()
    CLASS.ID    = "Sphere"
    CLASS.Name  = "Sphere"
    CLASS.Model = "models/acf/core/s_sphere.mdl"
    CLASS.Icon  = "models/acf/core/s_sphere.mdl"

    function CLASS.ShapeCalculation(Size, Wall)
        local a = Size.x / 2  -- Semi-axis X
        local b = Size.y / 2  -- Semi-axis Y
        local c = Size.z / 2  -- Semi-axis Z

        local ai = math.max(0, a - Wall)
        local bi = math.max(0, b - Wall)
        local ci = math.max(0, c - Wall)

        -- Volume of ellipsoid: (4/3) * pi * a * b * c
        local InteriorVolume = (4 / 3) * math.pi * ai * bi * ci

        -- Surface area approximation using Knud Thomsen's formula
        -- More accurate than simple approximations for ellipsoids
        local p = 1.6075
        local Area = 4 * math.pi * math.pow((math.pow(a * b, p) + math.pow(a * c, p) + math.pow(b * c, p)) / 3, 1 / p)

        return InteriorVolume, Area
    end
end)
