-- Code modified from the NADMOD client permissions menu, by Nebual
-- http://www.facepunch.com/showthread.php?t=1221183
ACF.Permissions = ACF.Permissions or {}
local Permissions = ACF.Permissions
local getPanelChecks = function() return {} end

net.Receive("ACF_refreshfriends", function()
	local perms = net.ReadTable()
	local checks = getPanelChecks()

	for _, check in pairs(checks) do
		if perms[check.steamid] then
			check:SetChecked(true)
		else
			check:SetChecked(false)
		end
	end
end)

function Permissions.ApplyPermissions(checks)
	local perms = {}

	for _, check in pairs(checks) do
		if not check.steamid then
			Error("Encountered player checkbox without an attached SteamID!")
		end

		perms[check.steamid] = check:GetChecked()
	end

	net.Start("ACF_dmgfriends")
	net.WriteTable(perms)
	net.SendToServer()
end

function Permissions.ClientPanel(Panel)
	Panel:ClearControls()

	if not Permissions.ClientCPanel then
		Permissions.ClientCPanel = Panel
	end

	Panel:SetName("ACF Damage Permissions")
	local Title = Panel:Help("ACF Damage Permission Panel")
	Title:SetContentAlignment(TEXT_ALIGN_CENTER)
	Title:SetFont("DermaDefaultBold")

	local Desc = Panel:Help("Allow or deny ACF damage to your props using this panel.\n\nThese preferences only work during the Build and Strict Build modes.")
	Desc:SetContentAlignment(TEXT_ALIGN_CENTER)

	Panel.playerChecks = {}
	local checks = Panel.playerChecks
	getPanelChecks = function() return checks end
	local Players = player.GetAll()

	for _, tar in ipairs(Players) do
		if (IsValid(tar)) then
			local check = Panel:CheckBox(tar:Nick())
			check.steamid = tar:SteamID()
			--if tar == LocalPlayer() then check:SetChecked(true) end
			checks[#checks + 1] = check
		end
	end

	local button = Panel:Button("Give Damage Permission")

	button.DoClick = function()
		Permissions.ApplyPermissions(Panel.playerChecks)
	end

	net.Start("ACF_refreshfriends")
	net.SendToServer(ply)
end

function Permissions.SpawnMenuOpen()
	if Permissions.ClientCPanel then
		Permissions.ClientPanel(Permissions.ClientCPanel)
	end
end

hook.Add("SpawnMenuOpen", "ACFPermissionsSpawnMenuOpen", Permissions.SpawnMenuOpen)

function Permissions.PopulateToolMenu()
	spawnmenu.AddToolMenuOption("Utilities", "ACF", "Damage Permission", "Damage Permission", "", "", Permissions.ClientPanel)
end

hook.Add("PopulateToolMenu", "ACFPermissionsPopulateToolMenu", Permissions.PopulateToolMenu)