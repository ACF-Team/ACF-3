ACF.Classes.DefineClass("ACF.ContainerShapes.Box", "ACF.ContainerShapes.BaseContainerShape", function()
    CLASS.ID    = "Box"
    CLASS.Name  = "Box"
    CLASS.Model = "models/acf/core/s_fuel.mdl"
    CLASS.Icon  = "models/acf/core/s_fuel.mdl"

    function CLASS.ShapeCalculation(Size, Wall)
        local sx, sy, sz     = Size.x, Size.y, Size.z
        local InteriorVolume = math.max(0, (sx - 2 * Wall) * (sy - 2 * Wall) * (sz - 2 * Wall))

        local Area = 2 * (sx * sy + sx * sz + sy * sz)

        return InteriorVolume, Area
    end
end)
