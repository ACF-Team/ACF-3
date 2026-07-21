local GetType = ACF.Classes.GetTypeByName

-- Translates a legacy shape short ID ("Box"/"Sphere"/"Cylinder") into a ContainerShapes class FQN.
local function ShapeFQN(ID)
	local FQN = "ACF.ContainerShapes." .. tostring(ID)

	return GetType(FQN) and FQN or "ACF.ContainerShapes.Box"
end

-- Migrates legacy ACF-3 supply crates (flat SupplyShape / SupplySizeX/Y/Z dupe keys) onto the
-- AutoRegisterV2 serialized field set. The size keys are unchanged; only the shape needs to be
-- promoted from a string ID to the new Shape class field.
ACF.Entities.RegisterCompatPatch("acf_supply", 2026061601, function(Data)
	if Data.ACF_UserData then return end

	Data.ACF_UserData = {
		Shape       = ShapeFQN(Data.SupplyShape or "Box"),
		SupplySizeX = Data.SupplySizeX or 6,
		SupplySizeY = Data.SupplySizeY or 6,
		SupplySizeZ = Data.SupplySizeZ or 6,
	}
end)
