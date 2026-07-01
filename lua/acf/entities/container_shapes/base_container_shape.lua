ACF.Classes.DefineClass("ACF.ContainerShapes.BaseContainerShape", function()
    CLASS.ID    = "BaseContainerShape"
    CLASS.Name  = "Container Shape"
    CLASS.Model = ""
    CLASS.Icon  = ""

    -- True for shapes that pack rounds in concentric rings (ammo drums).
    CLASS.IsDrum = false

    -- Subtypes must implement ShapeCalculation(Size, Wall) -> InteriorVolume (cu in), SurfaceArea (sq in)
end)
