local RackFQN = {
	["40mm7xPOD"] = "ACF.Racks.40mm7xPOD",
	["40mm7xPOD"] = "ACF.Racks.40mm7xPOD",
	["57mm16xPOD"] = "ACF.Racks.57mm16xPOD",
	["57mm16xPOD"] = "ACF.Racks.57mm16xPOD",
	["57mm32xPOD"] = "ACF.Racks.57mm32xPOD",
	["57mm32xPOD"] = "ACF.Racks.57mm32xPOD",
	["70mm7xPOD"] = "ACF.Racks.70mm7xPOD",
	["70mm7xPOD"] = "ACF.Racks.70mm7xPOD",
	["70mm19xPOD"] = "ACF.Racks.70mm19xPOD",
	["70mm19xPOD"] = "ACF.Racks.70mm19xPOD",
	["80mm20xPOD"] = "ACF.Racks.80mm20xPOD",
	["80mm20xPOD"] = "ACF.Racks.80mm20xPOD",
	["1x BGM-71E"] = "ACF.Racks.1xBGM-71E",
	["2x BGM-71E"] = "ACF.Racks.2xBGM-71E",
	["4x BGM-71E"] = "ACF.Racks.4xBGM-71E",
	["380mmRW61"] = "ACF.Racks.380mmRW61",
	["3xUARRK"] = "ACF.Racks.3xUARRK",
	["6xUARRK"] = "ACF.Racks.6xUARRK",
	["6xUARRK"] = "ACF.Racks.6xUARRK",
	["1x FIM-92"] = "ACF.Racks.1xFIM-92",
	["2x FIM-92"] = "ACF.Racks.2xFIM-92",
	["4x FIM-92"] = "ACF.Racks.4xFIM-92",
	["1x Strela-1"] = "ACF.Racks.1xStrela-1",
	["2x Strela-1"] = "ACF.Racks.2xStrela-1",
	["4x Strela-1"] = "ACF.Racks.4xStrela-1",
	["1x Ataka"] = "ACF.Racks.1xAtaka",
	["1x SPG9"] = "ACF.Racks.1xSPG9",
	["1x Kornet"] = "ACF.Racks.1xKornet",
	["127mm4xPOD"] = "ACF.Racks.127mm4xPOD",
	["1xRK"] = "ACF.Racks.1xRK",
	["1xRK_small"] = "ACF.Racks.1xRK_small",
	["2xRK"] = "ACF.Racks.2xRK",
	["3xRK"] = "ACF.Racks.3xRK",
	["4xRK"] = "ACF.Racks.4xRK",
	["2x AGM-114"] = "ACF.Racks.2xAGM-114",
	["4x AGM-114"] = "ACF.Racks.4xAGM-114",
	["1xAT3RK"] = "ACF.Racks.1xAT3RK",
	["1xAT3RKS"] = "ACF.Racks.1xAT3RKS",
}

ACF.Entities.RegisterCompatPatch("acf_rack", 2026062801, function(Data)
	if Data.ACF_UserData then return end

	Data.ACF_UserData = {
		Rack        = {Type = RackFQN[Data.Rack or "1xRK"], Data = {}},
		BreechIndex = Data.BreechIndex,
	}
end)
