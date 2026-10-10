ACF.Classes.DefineClass("ACF.ContainerShapes.BaseContainerShape", function(CLASS)
    CLASS.ID    = "BaseContainerShape"
    CLASS.Name  = "Container Shape"
    CLASS.Model = ""
    CLASS.Icon  = ""

    -- True for shapes that pack rounds in concentric rings (ammo drums).
    CLASS.IsDrum = false

    -- Subtypes must implement ShapeCalculation(Size) -> Volume (cu in).
    -- Wall thickness is no longer a fixed figure, so this is the full exterior volume;
    -- armor comes from the volumetric mesh instead.
end)
