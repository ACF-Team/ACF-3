local FuelTanks = ACF.Classes.FuelTanks

FuelTanks.Register("FTS_D", {
	Name		= "Fuel Drum",
	Description	= "Scalable fuel drum; required for engines to work."
})

do
	FuelTanks.RegisterItem("Drum", "FTS_D", {
		Name		= "Fuel Drum",
		Description	= "Tends to explode when shot.",
		Model		= "models/props_c17/oildrum001_explosive.mdl",
		Shape		= "Drum",
		Preview = {
			FOV = 120,
		},
	})
end