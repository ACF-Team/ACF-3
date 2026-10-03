local ACF     = ACF
local Classes = ACF.Classes

Classes.DefineClass("ACF.Sensors.Sensor", function() end)

Classes.DefineClass("ACF.Sensors.Radar", "ACF.Sensors.Sensor", function(CLASS)
	-- Shared info panel for every radar group (Item is the selected item class).
	function CLASS.CreateMenu(Item, Menu)
		local ViewCone  = (Item.ViewCone or 180) * 2
		local ViewRange = Item.Range and (math.Round(Item.Range * ACF.InchToMeter, 2) .. " m") or "Unlimited"

		Menu:AddLabel(string.format("View Cone : %s degrees\nView Range : %s\nMass : %s kg\n", ViewCone, ViewRange, Item.Mass))
	end
end)

Classes.DefineClass("ACF.Sensors.Receiver", "ACF.Sensors.Sensor", function(CLASS)
	function CLASS.CreateMenu(Item, Menu)
		Menu:AddLabel(string.format("Mass : %s kg\nCost : %s\n", Item.Mass, ACF.FormatCost(Item.Cost or 0)))
	end
end)

Classes.DefineClass("ACF.Sensors.IRST", "ACF.Sensors.Sensor", function(CLASS)
	local Text = "View Cone : %s degrees\nGimbal Range : %s degrees\nGimbal Speed : %s degrees/s\nView Range : Unlimited\nDetects : Contraptions, Players\nMass : %s kg\nCost : %s\n"
	local Help = "Aim it with the Pitch and Yaw inputs. It needs line of sight to a target's center: terrain, smoke clouds and any part of its own contraption will block its view, so it can't be armored from the front."

	function CLASS.CreateMenu(Item, Menu)
		Menu:AddLabel(Text:format(Item.ViewCone * 2, Item.GimbalCone * 2, Item.SlewRate, Item.Mass, ACF.FormatCost(Item.Cost or 0)))
		Menu:AddHelp(Help)
	end
end)
