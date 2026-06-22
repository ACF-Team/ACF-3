ACF.Classes.DefineClass("ACF.ContainerShapes.Cylinder", "ACF.ContainerShapes.BaseContainerShape", function()
    CLASS.ID     = "Cylinder"
    CLASS.Name   = "Cylinder"
    CLASS.Model  = "models/acf/core/s_fuel_cyl.mdl"
    CLASS.Icon   = "models/acf/core/s_fuel_cyl.mdl"
    CLASS.IsDrum = true

    function CLASS.ShapeCalculation(Size, Wall)
        local a = Size.x / 2  -- Semi-axis X (radius in X direction)
        local b = Size.y / 2  -- Semi-axis Y (radius in Y direction)
        local h = Size.z      -- Height

        local ai = math.max(0, a - Wall)
        local bi = math.max(0, b - Wall)
        local hi = math.max(0, h - 2 * Wall)

        -- Volume of elliptical cylinder: pi * a * b * h
        local InteriorVolume = math.pi * ai * bi * hi

        -- Surface area approximation using Ramanujan's formula for ellipse perimeter
        local h_ellipse   = math.pow((a - b) / (a + b), 2)
        local Perimeter   = math.pi * (a + b) * (1 + (3 * h_ellipse) / (10 + math.sqrt(4 - 3 * h_ellipse)))
        local LateralArea = Perimeter * h
        local EndArea     = math.pi * a * b
        local Area        = LateralArea + 2 * EndArea

        return InteriorVolume, Area
    end
end)
