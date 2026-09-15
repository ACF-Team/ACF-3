-- Same hull as Cylinder; ammo crates use it to pack rounds standing on end.
-- Fuel tanks and supply crates list their shapes explicitly, so it stays ammo-only.
ACF.Classes.DefineClass("ACF.ContainerShapes.CylinderVertical", "ACF.ContainerShapes.Cylinder", function(CLASS)
    CLASS.ID     = "CylinderVertical"
    CLASS.Name   = "Drum"
    CLASS.Model  = "models/acf/core/s_fuel_cyl.mdl"
    CLASS.Icon   = "models/acf/core/s_fuel_cyl.mdl"
    CLASS.IsDrum = true
end)
