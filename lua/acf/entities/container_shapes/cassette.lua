-- Same hull as Box; ammo crates use it to wrap rounds around a conveyor.
ACF.Classes.DefineClass("ACF.ContainerShapes.Cassette", "ACF.ContainerShapes.Box", function(CLASS)
    CLASS.ID           = "Cassette"
    CLASS.Name         = "Cassette"
    CLASS.IsCassette   = true
    CLASS.IsMechanized = true
    CLASS.CanHexPack   = false
    CLASS.AutoloaderMinLengthFrac = 0.1
end)
