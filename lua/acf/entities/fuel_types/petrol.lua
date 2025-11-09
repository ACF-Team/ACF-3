local FuelTypes = ACF.Classes.FuelTypes


FuelTypes.Register("Petrol", {
	Name	= "Petrol Fuel",
	Density	= 0.832,
	FuelTankOverlayText = function(Fuel)
		local Text = "Fuel Level: %s L"
		return Text:format(math.Round(Fuel, 2))
	end
})
