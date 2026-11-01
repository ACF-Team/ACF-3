ACF.Classes.DefineClass("ACF.ContainerShapes.Cylinder", "ACF.ContainerShapes.BaseContainerShape", function(CLASS)
    CLASS.ID     = "Cylinder"
    CLASS.Name   = "Cylinder"
    CLASS.Model  = "models/acf/core/s_ammo_cyl.mdl"
    CLASS.Icon   = "models/acf/core/s_ammo_cyl.mdl"
    CLASS.IsDrum = true
    CLASS.IsMechanized = true
    CLASS.CanHexPack = false

    -- Shells lie in a ring around the drum's axis, so any direction across the axis meets one at some spin
    function CLASS.GetShellAngleDiff(Crate, Direction)
        return math.abs(90 - math.deg(math.acos(math.Clamp(Direction:Dot(Crate:GetUp()), -1, 1))))
    end

    function CLASS.ShapeCalculation(Size)
        local a = Size.x / 2  -- Semi-axis X (radius in X direction)
        local b = Size.y / 2  -- Semi-axis Y (radius in Y direction)
        local h = Size.z      -- Height

        -- Volume of elliptical cylinder: pi * a * b * h
        return math.pi * a * b * h
    end
end)
