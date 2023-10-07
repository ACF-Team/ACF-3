local FuelTanks = ACF.Classes.FuelTanks

FuelTanks.Register("FTS_M", {
	Name		= "Miscellaneous",
	Description	= "Random fuel tank models; some of them can only be used for refueling.",
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
		Shape       = "Elliptical",
		IsExplosive	= false,
		Unlinkable	= true,
	})

	FuelTanks.RegisterItem("Storage_Tank","FTS_M", {
		Name		= "Storage Tank",
		Description	= "Disappointingly non-explosive.",
		Model		= "models/props_wasteland/coolingtank02.mdl",
		SurfaceArea	= 144736.3,
		Volume		= 2609960,
		Shape       = "Elliptical",
		IsExplosive	= false,
		Unlinkable	= true,
		Preview = {
			FOV = 125,
		},
	})
end