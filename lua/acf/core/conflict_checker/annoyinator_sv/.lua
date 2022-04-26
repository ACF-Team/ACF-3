-- Older versions of ACF will conflict due to the new file loading system we implemented.
-- If the server has an older version installed simultaneously, we'll let the players know.
if ACF.Version then
	util.AddNetworkString("ACF_VersionConflict")

	hook.Add("PlayerSpawn", "ACF Version Conflict", function(Player)
		net.Start("ACF_VersionConflict")
		net.Send(Player)
	end)
end
