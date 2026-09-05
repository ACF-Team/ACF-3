local ACF        = ACF
local Components = ACF.Classes.Components

Components.Register("RadarSync", {
	Name   = "Radar Synchronizer",
	Entity = "acf_radarsync",
	LimitConVar = {
		Name = "_acf_radarsync",
		Amount = 2,
		Text = "Maximum amount of ACF Radar Synchronizers a player can create."
	}
})

Components.RegisterItem("RadarSync-Item", "RadarSync", {
	Name        = "Radar Synchronizer",
	Description = "Links to multiple radars, handling them as reference points, while performing one consolidated detection pass in their place. Combines the detection zones of all linked radars into a single output source.",
	Model       = "models/props_lab/reciever01d.mdl",
	Mass        = 25,
	Preview = {
		FOV = 90,
	},
	CreateMenu = function(Data, Menu)
		Menu:AddLabel("Mass : " .. Data.Mass .. " kg\nCost : " .. ACF.GetProperCost(ACF.RadarSyncCost) .. "\n\nLink this entity to radar entities to combine their detection zones into this entity's outputs.")

		ACF.SetClientData("PrimaryClass", "acf_radarsync")
	end,
})
