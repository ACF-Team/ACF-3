-- Code modified from the NADMOD client permissions menu, by Nebual
-- http://www.facepunch.com/showthread.php?t=1221183

ACF.Permissions = ACF.Permissions or {}
local Permissions = ACF.Permissions

function Permissions.ApplyPermissions(Checks)
	local Perms = {}

	for _, Check in pairs(Checks) do
		if not Check.SteamID then
			Error("Encountered player checkbox without an attached SteamID!")
		end

		Perms[Check.SteamID] = Check:GetChecked()
	end

	net.Start("ACF_dmgfriends")
	net.WriteTable(Perms)
	net.SendToServer()
end