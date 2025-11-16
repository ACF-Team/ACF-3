local ACF        = ACF
local Components = ACF.Classes.Components

Components.Register("WTJ", {
	Name   = "Water Jet",
	Entity = "acf_waterjet"
})

Components.RegisterItem("WTJ-IMP", "WTJ", {
	Name        = "Water Jet",
	Description = "Entity capable of aiding with movement in water.",
	Model       = "models/maxofs2d/hover_propeller.mdl",
	CreateMenu = function(_, Menu)
		local SizeX = Menu:AddSlider("Size", 0.5, 1, 2)
		SizeX:SetClientData("WaterjetSize", "OnValueChanged")
	end
})