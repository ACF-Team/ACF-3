local FuelTanks = ACF.Classes.FuelTanks

FuelTanks.Register("FTS_B", {
	Name		= "Fuel Box",
	Description	= "Scalable fuel tank; required for engines to work."
})

do
	FuelTanks.RegisterItem("Box", "FTS_B", {
		Name		= "Fuel Box",
		Description	= "", -- Blank to allow for dynamic descriptions better
		Model		= "models/fueltank/fueltank_4x4x4.mdl",
		Shape		= "Box",
		Preview = {
			FOV = 120,
		},
	})
end