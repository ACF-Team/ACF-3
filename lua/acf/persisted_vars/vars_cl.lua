-- Variables that should be persisted between servers

-- Settings
ACF.PersistClientData("Volume", 0.5)
ACF.PersistClientData("AmmoSupplyColor", Color(255, 255, 0, 10))
ACF.PersistClientData("FuelSupplyColor", Color(76, 201, 250, 10))
ACF.PersistClientData("DualClutch", false)

-- Crate projectile counts
ACF.PersistClientData("CrateProjectilesX", 3)
ACF.PersistClientData("CrateProjectilesY", 3)
ACF.PersistClientData("CrateProjectilesZ", 3)

-- Plate size
ACF.PersistClientData("PlateSizeX", 24)
ACF.PersistClientData("PlateSizeY", 24)
ACF.PersistClientData("PlateSizeZ", 5)

-- Fuel tank size and shape
ACF.PersistClientData("FuelSizeX", 24)
ACF.PersistClientData("FuelSizeY", 24)
ACF.PersistClientData("FuelSizeZ", 24)
ACF.PersistClientData("FuelShape", "Box")

-- Supply crate size and shape
ACF.PersistClientData("SupplySizeX", 24)
ACF.PersistClientData("SupplySizeY", 24)
ACF.PersistClientData("SupplySizeZ", 24)
ACF.PersistClientData("SupplyShape", "Box")

-- Gearbox
ACF.PersistClientData("GearboxLegacyRatio", false)