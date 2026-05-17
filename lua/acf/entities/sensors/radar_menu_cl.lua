local ACF  = ACF
local Text = "View Cone : %s degrees\nView Range : %s\nMass : %s kg\n"

function ACF.CreateRadarMenu(Data, Menu)
	local ViewCone = (Data.ViewCone or 180) * 2
	local ViewRange = Data.Range and (math.Round(Data.Range * ACF.InchToMeter, 2) .. " m") or "Unlimited"

	Menu:AddLabel(Text:format(ViewCone, ViewRange, Data.Mass))

	ACF.SetClientData("PrimaryClass", "acf_radar")
end
