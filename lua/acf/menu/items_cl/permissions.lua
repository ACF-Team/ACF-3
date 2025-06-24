local ACF = ACF
local Permissions = ACF.Permissions

do
	-- Code modified from the NADMOD client permissions menu, by Nebual
	-- http://www.facepunch.com/showthread.php?t=1221183

	local PlayerChecks = {}

	net.Receive("ACF_refreshfriends", function()
		local Perms = net.ReadTable()

		for _, Check in pairs(PlayerChecks) do
			if not IsValid(Check) then continue end

			if Perms[Check.SteamID] then
				Check:SetChecked(true)
			else
				Check:SetChecked(false)
			end
		end
	end)

	timer.Simple(0, function()
		net.Start("ACF_refreshfriends")
		net.SendToServer()
	end)

	local function CreateMenu(Menu)
		net.Start("ACF_refreshfriends")
		net.SendToServer()

		Menu:AddTitle("#acf.menu.permissions.player_permissions_title")
		Menu:AddLabel("#acf.menu.permissions.player_permissions_desc")

		PlayerChecks = {}
		local LocalPly = LocalPlayer()

		for _, Target in player.Iterator() do
			if (IsValid(Target)) then
				local Check = Menu:AddCheckBox(Target:Nick())
				Check.SteamID = Target:SteamID()
				if Target == LocalPly then Check:SetDisabled(true) end
				PlayerChecks[#PlayerChecks + 1] = Check
			end
		end

		local SetPerms = Menu:AddButton("#acf.menu.permissions.give_permissions")

		function SetPerms:DoClickInternal()
			Permissions.ApplyPermissions(PlayerChecks)
		end
	end

	ACF.AddMenuItem(1, "#acf.menu.permissions", "#acf.menu.permissions.player_permissions", "group_edit", CreateMenu)
end

do
	local PermissionModes = {}
	local CurrentPermission = "default"
	local DefaultPermission = "none"
	local CurrentMode
	local List

	local function UpdateModeData()
		if List then
			for ID, Line in pairs(List:GetLines()) do
				if Line:GetValue(1) == CurrentPermission then
					List:GetLine(ID):SetValue(2, "Yes")
				else
					List:GetLine(ID):SetValue(2, "")
				end

				if Line:GetValue(1) == DefaultPermission then
					List:GetLine(ID):SetValue(3, "Yes")
				else
					List:GetLine(ID):SetValue(3, "")
				end
			end
		end

		if CurrentMode then
			local CurrentModeTxt = language.GetPhrase("acf.menu.permissions.current_mode")
			CurrentMode:SetText(string.format(CurrentModeTxt, CurrentPermission))
		end
	end

	local function RequestUpdate()
		net.Start("ACF_refreshpermissions")
		net.SendToServer()
	end

	local function RequestSafezones()
		net.Start("ACF_OnUpdateSafezones")
		net.SendToServer()
	end

	net.Receive("ACF_refreshpermissions", function()
		PermissionModes = net.ReadTable()
		CurrentPermission = net.ReadString()
		DefaultPermission = net.ReadString()

		UpdateModeData()
	end)

	timer.Simple(0, function()
		RequestUpdate()
		RequestSafezones()
	end)

	local function CreateMenu(Menu)
		Menu:AddTitle("#acf.menu.permissions.permission_modes_title")
		Menu:AddLabel("#acf.menu.permissions.permission_modes_desc")

		local CurrentModeTxt = language.GetPhrase("acf.menu.permissions.current_mode")
		CurrentMode = Menu:AddLabel(string.format(CurrentModeTxt, CurrentPermission))

		if not LocalPlayer():IsAdmin() then return end

		ACF.SetToolMode("acf_menu", "ZoneModifier", "Update")

		List = Menu:AddListView()
		List:AddColumn("#acf.menu.permissions.mode")
		List:AddColumn("#acf.menu.permissions.active")
		List:AddColumn("#acf.menu.permissions.map_default")

		for Permission in pairs(PermissionModes) do
			List:AddLine(Permission, "", "")
		end

		UpdateModeData()

		Menu:AddLabel("#acf.menu.permissions.mode_desc_header")
		local ModeDescDefault = "#acf.menu.permissions.mode_desc_default"
		local ModeDesc = Menu:AddLabel(PermissionModes[CurrentPermission] or ModeDescDefault)

		List.OnRowSelected = function(Panel, Line)
			ModeDesc:SetText(PermissionModes[Panel:GetLine(Line):GetValue(1)] or ModeDescDefault)
		end

		local SetMode = Menu:AddButton("#acf.menu.permissions.set_mode")

		function SetMode:DoClickInternal()
			local Line = List:GetLine(List:GetSelectedLine())
			if not Line then
				RequestUpdate()
				return
			end

			local Mode = Line and Line:GetValue(1)
			RunConsoleCommand("acf_setpermissionmode", Mode)
		end

		local SetDefault = Menu:AddButton("#acf.menu.permissions.set_default_mode")

		function SetDefault:DoClickInternal()
			local Line = List:GetLine(List:GetSelectedLine())
			if not Line then
				RequestUpdate()
				return
			end

			local Mode = Line and Line:GetValue(1)
			RunConsoleCommand("acf_setdefaultpermissionmode", Mode)
		end

		local SafezonesBase = Menu:AddCollapsible("#acf.menu.permissions.safezones", nil, "icon16/lock_edit.png")
		SafezonesBase:AddCheckBox("#acf.menu.permissions.safezones.enable"):LinkToServerData("EnableSafezones")
		SafezonesBase:AddHelp("#acf.menu.permissions.safezones.enable_desc")
		SafezonesBase:AddCheckBox("#acf.menu.permissions.safezones.noclip"):LinkToServerData("NoclipOutsideZones")
		SafezonesBase:AddButton("#acf.menu.permissions.safezones.save", "acf_savesafezones")
		SafezonesBase:AddButton("#acf.menu.permissions.safezones.reload", "acf_reloadsafezones")
	end

	ACF.AddMenuItem(2, "#acf.menu.permissions", "#acf.menu.permissions.set_mode", "server_edit", CreateMenu)
end