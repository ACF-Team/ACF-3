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

		Menu:AddTitle("ACF Damage Permissions")
		Menu:AddLabel("Allow or deny ACF damage to your props using this panel.\n\nThese preferences only work during the Build and Strict Build modes.")

		PlayerChecks = {}

		for _, Target in player.Iterator() do
			if (IsValid(Target)) then
				local Check = Menu:AddCheckBox(Target:Nick())
				Check.SteamID = Target:SteamID()
				-- if Target == LocalPlayer() then Check:SetChecked(true) end
				PlayerChecks[#PlayerChecks + 1] = Check
			end
		end

		local SetPerms = Menu:AddButton("Give Damage Permission")

		function SetPerms:DoClickInternal()
			Permissions.ApplyPermissions(PlayerChecks)
		end
	end

	ACF.AddMenuItem(1, "Damage Permissions", "Player Permissions", "group_edit", CreateMenu)
end

do
	local ModePermissions = {}
	local PermissionModes = {}
	local CurrentPermission = "default"
	local DefaultPermission = "none"
	local ModeDescDefault = "Can't find any info for this mode!"
	local CurrentMode
	local CurrentModeTxt = "\nThe current damage permission mode is %s."
	local List

	net.Receive("ACF_refreshpermissions", function()
		PermissionModes = net.ReadTable()
		CurrentPermission = net.ReadString()
		DefaultPermission = net.ReadString()

		ModePermissions:Update()
	end)

	function ModePermissions:Update()
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
			CurrentMode:SetText(string.format(CurrentModeTxt, CurrentPermission))
		end
	end

	function ModePermissions:RequestUpdate()
		net.Start("ACF_refreshpermissions")
		net.SendToServer()
	end

	timer.Simple(0, function()
		ModePermissions:RequestUpdate()
	end)

	local function CreateMenu(Menu)
		Menu:AddTitle("Damage Permission Modes")
		Menu:AddLabel("Damage Permission Modes change the way that ACF damage works.\n\nYou can change the DP mode if you are an admin.")
		CurrentMode = Menu:AddLabel(string.format(CurrentModeTxt, CurrentPermission))

		if not LocalPlayer():IsAdmin() then return end

		List = Menu:AddPanel("DListView")
		List:AddColumn("Mode")
		List:AddColumn("Active")
		List:AddColumn("Map Default")
		List:SetMultiSelect(false)
		List:SetSize(30, 100)

		for Permission in pairs(PermissionModes) do
			List:AddLine(Permission, "", "")
		end

		for id, line in pairs(List:GetLines()) do
			if line:GetValue(1) == CurrentPermission then
				List:GetLine(id):SetValue(2, "Yes")
			end
			if line:GetValue(1) == DefaultPermission then
				List:GetLine(id):SetValue(3, "Yes")
			end
		end

		Menu:AddLabel("What this mode does:")
		local ModeDesc = Menu:AddLabel(PermissionModes[CurrentPermission] or ModeDescDefault)

		List.OnRowSelected = function(Panel, Line)
			ModeDesc:SetText(PermissionModes[Panel:GetLine(Line):GetValue(1)] or ModeDescDefault)
		end

		local SetMode = Menu:AddButton("Set Permission Mode")

		function SetMode:DoClickInternal()
			local Line = List:GetLine(List:GetSelectedLine())
			if not Line then
				ModePermissions:RequestUpdate()
				return
			end

			local Mode = Line and Line:GetValue(1)
			RunConsoleCommand("ACF_setpermissionmode", Mode)
		end

		local SetDefault = Menu:AddButton("Set Default Permission Mode")

		function SetDefault:DoClickInternal()
			local Line = List:GetLine(List:GetSelectedLine())
			if not Line then
				ModePermissions:RequestUpdate()
				return
			end

			local Mode = Line and Line:GetValue(1)
			RunConsoleCommand("ACF_setdefaultpermissionmode", Mode)
		end
	end

	ACF.AddMenuItem(2, "Damage Permissions", "Set Permission Mode", "server_edit", CreateMenu)
end