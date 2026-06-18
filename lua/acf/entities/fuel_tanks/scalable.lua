ACF.Classes.DefineClass("ACF.FuelTanks.ScalableFuelTank", "ACF.FuelTanks.BaseFuelTank", function()
	CLASS.Name = "Fuel Tank"
	CLASS.ID = "Scalable"
	CLASS.Description = "#acf.descs.fuel.scalable"
	CLASS.IsScalable = true

	CLASS.Material = "models/props_canal/metalcrate001d"
	CLASS.NameType = "Tank"
	CLASS.Unlinkable = false

	CLASS.Preview = {
		FOV = 120,
	}
end)