ACF.RegisterFuelTankClass("FTS_M", {
	Name		= "Miscellaneous",
	Description	= "Random fuel tank models, some of them can only be used for refueling.",
})

do
	ACF.RegisterFuelTank("Fuel_Drum","FTS_M", {
		Name		= "Fuel Drum",
		Description	= "Tends to explode when shot.",
		Model		= "models/props_c17/oildrum001_explosive.mdl",
		SurfaceArea	= 5128.9,
		Volume		= 26794.4,
		Shape       = "Drum",
		Preview = {
			FOV = 120,
		},
	})

	ACF.RegisterFuelTank("Jerry_Can","FTS_M", {
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

	ACF.RegisterFuelTank("Transport_Tank","FTS_M", {
		Name		= "Transport Tank",
		Description	= "Disappointingly non-explosive.",
		Model		= "models/props_wasteland/horizontalcoolingtank04.mdl",
		SurfaceArea	= 127505.5,
		Volume		= 2102493.3,
		Shape       = "Drum",
		IsExplosive	= false,
		Unlinkable	= true,
	})

	ACF.RegisterFuelTank("Storage_Tank","FTS_M", {
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
