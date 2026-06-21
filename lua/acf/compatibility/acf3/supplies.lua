ACF.Classes.Entities.RegisterCompatPatch("acf_supply", 2026061601, function(Data)
	if Data.ACF_UserData then return end

	local Old = Data.Data or {}

	Data.ACF_UserData = {
		SupplyShape = Old.SupplyShape or Data.SupplyShape,
		SupplySizeX = Old.SupplySizeX or Data.SupplySizeX,
		SupplySizeY = Old.SupplySizeY or Data.SupplySizeY,
		SupplySizeZ = Old.SupplySizeZ or Data.SupplySizeZ,
	}
end)
