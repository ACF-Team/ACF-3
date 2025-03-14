local ACF        = ACF
local Components = ACF.Classes.Components

Components.Register("AL-CMP", {
	Name   = "Autoloader",
	Entity = "acf_autoloader",
	LimitConVar = {
		Name   = "_acf_autoloader",
		Amount = 8,
		Text   = "Maximum amount of ACF Computers a player can create."
	},
	CreateMenu = function(Data, Menu)
		local SizeX     = Menu:AddSlider("Autoloader Length", ACF.AutoloaderMinSize, ACF.AutoloaderMaxSize, 2)
		local SizeY     = Menu:AddSlider("Autoloader Width", ACF.AutoloaderMinSize, ACF.AutoloaderMaxSize, 2)
		local SizeZ     = Menu:AddSlider("Autoloader Height", ACF.AutoloaderMinSize, ACF.AutoloaderMaxSize, 2)

		SizeX:SetClientData("AutoloaderSizeX", "OnValueChanged")
		SizeX:DefineSetter(function(Panel, _, _, Value)
			local X = math.Round(Value, 2)

			Panel:SetValue(X)

			return X
		end)

		SizeY:SetClientData("AutoloaderSizeY", "OnValueChanged")
		SizeY:DefineSetter(function(Panel, _, _, Value)
			local Y = math.Round(Value, 2)

			Panel:SetValue(Y)

			return Y
		end)

		SizeZ:SetClientData("AutoloaderSizeZ", "OnValueChanged")
		SizeZ:DefineSetter(function(Panel, _, _, Value)
			local Z = math.floor(Value)

			Panel:SetValue(Z)

			return Z
		end)

		ACF.SetClientData("PrimaryClass", "acf_autoloader")
	end
})

do
	Components.RegisterItem("CST", "AL-CMP", {
		Name        = "Casette",
		Description = "A casette autoloader",
		Model       = "models/props_phx/construct/metal_tube.mdl",
		Preview = {
			FOV = 90,
		},
	})

	Components.RegisterItem("CRS-H", "AL-CMP", {
		Name        = "Horizontal Carousel",
		Description = "A carousel autoloader. Shells stored horizontally",
		Model       = "models/hunter/tubes/tube2x2x1.mdl",
		Preview = {
			FOV = 90,
		},
	})

	Components.RegisterItem("CRS-V", "AL-CMP", {
		Name        = "Vertical Carousel",
		Description = "A carousel autoloader. Shells stored vertically",
		Model       = "models/hunter/tubes/tube2x2x1.mdl",
		Preview = {
			FOV = 90,
		},
	})

	Components.RegisterItem("RLD-A", "AL-CMP", {
		Name        = "Reload Arm",
		Description = "Loading mechanism all autoloders need. Place behind gun.",
		Model       = "models/hunter/blocks/cube025x05x025.mdl",
		Preview = {
			FOV = 90,
		},
	})
end