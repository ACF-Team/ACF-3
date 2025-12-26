local ACF        = ACF
local Components = ACF.Classes.Components

Components.Register("AL", {
	Name   = "Autoloader",
	Entity = "acf_autoloader"
})

Components.RegisterItem("AL-IMP", "AL", {
	Name        = "Autoloader",
	Description = "Automatic ammunition loading system",
	Model       = "models/hunter/blocks/cube025x025x025.mdl",
	CreateMenu = function(_, Menu)
		local Caliber = Menu:AddSlider("Size", ACF.MinAutoloaderCaliber, ACF.MaxAutoloaderCaliber, 2)
		Caliber:SetClientData("AutoloaderCaliber", "OnValueChanged")

		local Length = Menu:AddSlider("Length", ACF.MinAutoloaderLength, ACF.MaxAutoloaderLength, 2)
		Length:SetClientData("AutoloaderLength", "OnValueChanged")
	end
})