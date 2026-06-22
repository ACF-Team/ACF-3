local GetType = ACF.Classes.GetTypeByName

-- Translates a legacy shape short ID ("Box"/"Cylinder") into a ContainerShapes class FQN.
local function ShapeFQN(ID)
	local FQN = "ACF.ContainerShapes." .. tostring(ID)

	return GetType(FQN) and FQN or "ACF.ContainerShapes.Box"
end

-- Migrates legacy ACF-3 ammo crates onto the AutoRegisterV2 serialized field set. The crate size is
-- derived from the projectile counts at spawn time, so the old Size key is dropped; only the shape
-- needs promoting from a string ID to the Shape class field. Weapon/Caliber/AmmoType/AmmoStage are
-- validated by the entity's ACF_OnVerifyClientData.
ACF.Classes.Entities.RegisterCompatPatch("acf_ammo", 2026062101, function(Data)
	if Data.ACF_UserData then return end

	local Old = Data.Data or {}

	Data.ACF_UserData = {
		Weapon            = Old.Weapon            or Data.Weapon,
		Caliber           = Old.Caliber           or Data.Caliber,
		AmmoType          = Old.AmmoType          or Data.AmmoType,
		AmmoStage         = Old.AmmoStage         or Data.AmmoStage,
		Shape             = ShapeFQN(Old.AmmoShape or Data.AmmoShape or "Box"),
		CrateProjectilesX = Old.CrateProjectilesX or Data.CrateProjectilesX,
		CrateProjectilesY = Old.CrateProjectilesY or Data.CrateProjectilesY,
		CrateProjectilesZ = Old.CrateProjectilesZ or Data.CrateProjectilesZ,
	}
end)
