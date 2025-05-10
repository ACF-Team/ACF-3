-- Code modified from the NADMOD client permissions menu, by Nebual
-- http://www.facepunch.com/showthread.php?t=1221183

ACF.Permissions = ACF.Permissions or {}
local Permissions = ACF.Permissions
Permissions.Safezones = Permissions.Safezones or {}

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

do -- Safezones logic
	local ZonesColor = Color(255, 251, 0, 166)
	local ZoneOutlinesColor = Color(189, 186, 7, 255)

	--- Draws the 3D boxes for all active safezones.
	function Permissions.RenderSafezones()
		render.SetColorMaterial()

		for _, Coords in pairs(Permissions.Safezones) do
			local ZoneCenter = (Coords[1] + Coords[2]) / 2
			local ZoneMins = ZoneCenter - Coords[1]
			local ZoneMaxs = ZoneCenter - Coords[2]

			render.DrawBox(ZoneCenter, angle_zero, ZoneMins, ZoneMaxs, ZonesColor)
			render.DrawWireframeBox(ZoneCenter, angle_zero, ZoneMins, ZoneMaxs, ZoneOutlinesColor)
		end
	end

	--- Draws the 2D text for all active safezones.
	function Permissions.RenderSafezoneText()
		for Name, Coords in pairs(Permissions.Safezones) do
			local ZoneCenter = ((Coords[1] + Coords[2]) / 2):ToScreen()
			local ZoneMins = "Start: (" .. Coords[1].x .. ", " .. Coords[1].y .. ", " .. Coords[1].z .. ")"
			local ZoneMaxs = "End: (" .. Coords[2].x .. ", " .. Coords[2].y .. ", " .. Coords[2].z .. ")"

			draw.SimpleTextOutlined(Name, "ACF_Title", ZoneCenter.x, ZoneCenter.y, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
			draw.SimpleTextOutlined(ZoneMins, "ACF_Title", ZoneCenter.x, ZoneCenter.y + 35, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
			draw.SimpleTextOutlined(ZoneMaxs, "ACF_Title", ZoneCenter.x, ZoneCenter.y + 55, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
		end
	end

	net.Receive("ACF_OnUpdateSafezones", function()
		local ZonesCount = net.ReadUInt(5)
		Permissions.Safezones = {}

		if ZonesCount == 0 then return end

		for _ = 1, ZonesCount do
			local ZoneName = net.ReadString()
			local ZoneMins = net.ReadVector()
			local ZoneMaxs = net.ReadVector()

			Permissions.Safezones[ZoneName] = {ZoneMins, ZoneMaxs}
		end
	end)
end