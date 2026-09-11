local ACF     = ACF
local Classes = ACF.Classes

Classes.DefineClass("ACF.Components.RadarSync", "ACF.Components.BaseComponent", function(CLASS)
	CLASS.Name        = "Radar Synchronizer"
	CLASS.ID          = "RadarSync"
	CLASS.Description = "Links to multiple radars, handling them as reference points, while performing one consolidated detection pass in their place. Combines the detection zones of all linked radars into a single output source."
	CLASS.Model       = "models/props_lab/reciever01d.mdl"
	CLASS.Entity      = "acf_radarsync"
	CLASS.Mass        = 25
	CLASS.Preview     = { FOV = 90 }
	CLASS.LimitConVar = {
		Name   = "_acf_radarsync",
		Amount = 2,
		Text   = "Maximum amount of ACF Radar Synchronizers a player can create."
	}

	function CLASS.CreateMenu(Data, Menu)
		Menu:AddLabel("Mass : " .. Data.Mass .. " kg\nCost : " .. ACF.FormatCost(ACF.RadarSyncCost) .. "\n\nLink this entity to radar entities to combine their detection zones into this entity's outputs.")
	end
end)
