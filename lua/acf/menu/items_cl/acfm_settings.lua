local ACF = ACF

do -- Clientside settings
	ACF.AddClientSettings(1000, "Missile Behavior", function(Base)
		local MissileLights = Base:AddSlider("Missile Light Intensity", 0, 5, 2)
		MissileLights:SetConVar("acf_missiles_missilelights")
		Base:AddHelp("Should missiles emit light while their motors are burning? Looks nice but may affect framerate.\nSet to 1 to enable, set to 0 to disable, set to another number to set minimum light size.")
	end)
end

do -- Serverside settings
	ACF.AddServerSettings(1000, "Missile Behavior", function(Base)
		Base:AddCheckBox("Allow flares to ignite players and NPCs. Does not affect players in godmode."):LinkToServerData("FlaresIgnite")
		Base:AddCheckBox("Prevent players from being identifiable in radar data."):LinkToServerData("RestrictRadarInfo")

		Base:AddSlider("Missile Ghost Period"):LinkToServerData("GhostPeriod")
		Base:AddHelp("Sets the number of seconds that missiles should ignore impacts for after being launched.")
	end)
end