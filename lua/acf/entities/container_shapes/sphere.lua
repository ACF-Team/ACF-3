ACF.Classes.DefineClass("ACF.ContainerShapes.Sphere", "ACF.ContainerShapes.BaseContainerShape", function(CLASS)
    CLASS.ID    = "Sphere"
    CLASS.Name  = "Sphere"
    CLASS.Model = "models/acf/core/s_sphere.mdl"
    CLASS.Icon  = "models/acf/core/s_sphere.mdl"

    function CLASS.ShapeCalculation(Size)
        local a = Size.x / 2  -- Semi-axis X
        local b = Size.y / 2  -- Semi-axis Y
        local c = Size.z / 2  -- Semi-axis Z

        -- Volume of ellipsoid: (4/3) * pi * a * b * c
        return (4 / 3) * math.pi * a * b * c
    end
end)
