local ACF     = ACF
local Classes = ACF.Classes

Classes.DefineClass("ACF.Components.SensorSync", "ACF.Components.BaseComponent", function(CLASS)
	CLASS.Name        = "Sensor Synchronizer"
	CLASS.ID          = "SensorSync"
	CLASS.Description = "Links to multiple sensors and performs one combined detection pass in their place, merging their detection zones into a single set of outputs."
	CLASS.Model       = "models/props_lab/reciever01d.mdl"
	CLASS.Entity      = "acf_sensorsync"
	CLASS.Mass        = 25
	CLASS.Preview     = { FOV = 90 }
	CLASS.LimitConVar = {
		Name   = "_acf_sensorsync",
		Amount = 2,
		Text   = "Maximum amount of ACF Sensor Synchronizers a player can create."
	}

	function CLASS.CreateMenu(Data, Menu)
		Menu:AddLabel("Mass : " .. Data.Mass .. " kg\nCost : " .. ACF.FormatCost(ACF.SensorSyncCost) .. "\n\nLink sensors to this entity to combine their detection zones into its outputs.")
	end
end)
