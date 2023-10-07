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

do -- Old drum tank compatibility
	FuelTanks.RegisterItem("Fuel_Drum", "FTS_D", {
		Name	= "Fuel Drum",
		Size	= Vector(28, 28, 45),
		Model	= "models/props_c17/oildrum001_explosive.mdl",
		Shape	= "Drum"
	})
end