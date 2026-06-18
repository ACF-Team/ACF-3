ACF.Classes.Entities.RegisterCompatPatch("acf_supply", 2026061601, function(Data)
	if Data.ACF_UserData then return end

	local ShapeMap = {
		Box      = "ACF.ContainerShapes.Box",
		Sphere   = "ACF.ContainerShapes.Sphere",
		Cylinder = "ACF.ContainerShapes.Cylinder",
	}

	Data.ACF_UserData = {
		Shape = ShapeMap[Data.SupplyShape] or "ACF.ContainerShapes.Box",
		Size  = Data.Size,
	}
end)
