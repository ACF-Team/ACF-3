local ACF     = ACF
local Classes = ACF.Classes

Classes.DefineClass("ACF.Sensors.Sensor", function() end)

Classes.DefineClass("ACF.Sensors.Radar", "ACF.Sensors.Sensor", function()
	-- Shared info panel for every radar group (Item is the selected item class).
	function CLASS.CreateMenu(Menu, Item)
		local ViewCone  = (Item.ViewCone or 180) * 2
		local ViewRange = Item.Range and (math.Round(Item.Range * ACF.InchToMeter, 2) .. " m") or "Unlimited"

		Menu:AddLabel(string.format("View Cone : %s degrees\nView Range : %s\nMass : %s kg\n", ViewCone, ViewRange, Item.Mass))
	end
end)

Classes.DefineClass("ACF.Sensors.Receiver", "ACF.Sensors.Sensor", function()
	function CLASS.CreateMenu(Menu, Item)
		Menu:AddLabel(string.format("Mass : %s kg\n", Item.Mass))
	end
end)
