ACF.Classes.DefineClass("ACF.ContainerShapes.Cylinder", "ACF.ContainerShapes.BaseContainerShape", function(CLASS)
    CLASS.ID     = "Cylinder"
    CLASS.Name   = "Cylinder"
    CLASS.Model  = "models/acf/core/s_fuel_cyl.mdl"
    CLASS.Icon   = "models/acf/core/s_fuel_cyl.mdl"
    CLASS.IsDrum = true

    function CLASS.ShapeCalculation(Size)
        local a = Size.x / 2  -- Semi-axis X (radius in X direction)
        local b = Size.y / 2  -- Semi-axis Y (radius in Y direction)
        local h = Size.z      -- Height

        -- Volume of elliptical cylinder: pi * a * b * h
        return math.pi * a * b * h
    end
end)
