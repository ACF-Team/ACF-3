local ACF = ACF

ACF.LaserSources   = ACF.LaserSources or {}
ACF.ActiveLasers   = ACF.ActiveLasers or {}
ACF.ActiveMissiles = ACF.ActiveMissiles or {}
ACF.ActiveRadars   = ACF.ActiveRadars or {}

ACF.FlareBurnMultiplier     = 0.025
ACF.FlareDistractMultiplier = 1 / 35
ACF.MaxDamageInaccuracy     = 1000
ACF.DefaultRadarSound       = "buttons/button16.wav"

game.AddParticles("particles/flares_fx.pcf")
PrecacheParticleSystem("ACFM_Flare")

do -- Update checker
	hook.Add("ACF_OnLoadAddon", "ACF Missiles Update Checker", function()
		ACF.AddRepository("ACF-Team", "ACF-3-Missiles")

		hook.Remove("ACF_OnLoadAddon", "ACF Missiles Update Checker")
	end)
end

ACF.DefineSetting("FlaresIgnite", true, "Flare ignition of players and NPCs has been %s.", ACF.BooleanDataCallback())
ACF.DefineSetting("RestrictRadarInfo", false, "Player radar info restrictions have been %s.", ACF.BooleanDataCallback())
ACF.DefineSetting("GhostPeriod", 0.05, "Missile ghost period has been set to %.2f seconds.", ACF.FloatDataCallback(0, 5, 2))

if CLIENT then
	local LightsDesc = "Should missiles emit light while their motors are burning? Looks nice but may affect framerate.\nSet to 1 to enable, set to 0 to disable, set to another number to set minimum light size."

	CreateClientConVar("acf_missiles_missilelights", 0, true, false, LightsDesc, 0, 5)
else
	hook.Add("ACF_OnLoadPersistedData", "ACF Missiles Workshop Content", function()
		if ACF.ServerData.WorkshopContent then
			resource.AddWorkshop("3248769787") -- ACF-3 Missiles
		end
	end)
end