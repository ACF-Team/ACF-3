local GetType = ACF.Classes.GetTypeByName

-- Translates a legacy shape short ID ("Box"/"Cylinder") into a ContainerShapes class FQN.
local function ShapeFQN(ID)
	local FQN = "ACF.ContainerShapes." .. tostring(ID)

	return GetType(FQN) and FQN or "ACF.ContainerShapes.Box"
end


-- This was for the autoregisterv2 conversion
ACF.Classes.Entities.RegisterCompatPatch("acf_ammo", 2026062101, function(Data)
	if Data.ACF_UserData then return end

	local WeaponTypeInstance = {Type = Data.Weapon,   Data = {}}
	local AmmoTypeInstance   = {Type = Data.AmmoType, Data = {}}

	Data.ACF_UserData = {
		Weapon            = WeaponTypeInstance,
		Caliber           = Data.Caliber,
		AmmoType          = AmmoTypeInstance,
		AmmoStage         = Data.AmmoStage,
		Shape             = ShapeFQN(Data.AmmoShape or "Box"),
		CrateProjectilesX = Data.CrateProjectilesX,
		CrateProjectilesY = Data.CrateProjectilesY,
		CrateProjectilesZ = Data.CrateProjectilesZ,
	}
end)
