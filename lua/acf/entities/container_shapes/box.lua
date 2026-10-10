ACF.Classes.DefineClass("ACF.ContainerShapes.Box", "ACF.ContainerShapes.BaseContainerShape", function(CLASS)
    CLASS.ID    = "Box"
    CLASS.Name  = "Box"
    CLASS.Model = "models/acf/core/s_fuel.mdl"
    CLASS.Icon  = "models/acf/core/s_fuel.mdl"

    function CLASS.ShapeCalculation(Size)
        return Size.x * Size.y * Size.z
    end
end)
