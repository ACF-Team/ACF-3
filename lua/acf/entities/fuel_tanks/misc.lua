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

FuelTanks.Register("FTS_M", {
	Name		= "Miscellaneous",
	Description	= "Random fuel tank models, some of them can only be used for refueling.",
})

do
	FuelTanks.RegisterItem("Jerry_Can","FTS_M", {
		Name		= "Jerry Can",
		Description	= "Handy portable fuel container.",
		Model		= "models/props_junk/gascan001a.mdl",
		SurfaceArea	= 1839.7,
		Volume		= 4384.1,
		Shape       = "Can",
		Preview = {
			FOV = 124,
		},
	})

	FuelTanks.RegisterItem("Transport_Tank","FTS_M", {
		Name		= "Transport Tank",
		Description	= "Disappointingly non-explosive.",
		Model		= "models/props_wasteland/horizontalcoolingtank04.mdl",
		SurfaceArea	= 127505.5,
		Volume		= 2102493.3,
		Shape       = "Drum",
		IsExplosive	= false,
		Unlinkable	= true,
	})

	FuelTanks.RegisterItem("Storage_Tank","FTS_M", {
		Name		= "Storage Tank",
		Description	= "Disappointingly non-explosive.",
		Model		= "models/props_wasteland/coolingtank02.mdl",
		SurfaceArea	= 144736.3,
		Volume		= 2609960,
		Shape       = "Drum",
		IsExplosive	= false,
		Unlinkable	= true,
		Preview = {
			FOV = 125,
		},
	})
end