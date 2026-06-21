local FuelTanks = ACF.Classes.FuelTanks

-- Unified scalable fuel tank class
-- Shape is determined by FuelShape client data
FuelTanks.Register("FTS_S", {
	Name		= "Fuel Tank",
	Description	= "#acf.descs.fuel.scalable",
	IsScalable	= true,
	Material	= "models/props_canal/metalcrate001d",
	NameType	= "Tank",
	IsExplosive	= true,
	Unlinkable	= false,
	Preview = {
		FOV = 120,
	},
})

do
	FuelTanks.RegisterItem("Scalable", "FTS_S", {
		Name		= "Fuel Tank",
		Description	= "#acf.descs.fuel.scalable_item",
	})
end