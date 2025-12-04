local FuelTypes = ACF.Classes.FuelTypes


FuelTypes.Register("Diesel", {
	Name	= "Diesel Fuel",
	Density	= 0.745,
	FuelTankOverlayText = function(Fuel)
		local Text = "Fuel Level: %s L"
		return Text:format(math.Round(Fuel, 2))
	end
})
