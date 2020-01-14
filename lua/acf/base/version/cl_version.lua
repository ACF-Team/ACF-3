
local PrintToChat = ACF.PrintToChat

if not ACF.GitVersion then
	ACF.GitVersion = {
		Code = false,
		Date = false,
		Commits = {},
	}
end

if not ACF.ServerVersion then
	ACF.ServerVersion = {
		Code = false,
		Date = false,
	}
end

local function CheckClientVersion(Git)
	local Local = ACF.GetVersion()

	if Local.Code == "Not Installed" then
		Local.Status = "Not Installed"
	elseif not Git.Code then
		Local.Status = "Unknown"
	elseif Local.Code == Git.Code or Local.Date >= Git.Date then
		Local.Status = "Up to Date"
	else
		Local.Status = "Outdated"
	end
end

local function CheckServerVersion()
	local Git 	 = ACF.GitVersion
	local Server = ACF.ServerVersion

	CheckClientVersion(Git)

	if not Git.Code then
		PrintToChat("Update", "Unable to retrieve server version.")

		Server.Status = "Unknown"
	elseif Server.Code == Git.Code or Server.Date >= Git.Date then
		PrintToChat("Version", "Server is running the latest version: ", Server.Code)

		Server.Status = "Up to Date"
	else
		PrintToChat("Update", "Server is outdated. Running on version: ", Server.Code)

		Server.Status = "Outdated"
	end
end

ACF.AddMessageType("Version", "Version")
ACF.AddMessageType("Update", "Version", Color(241, 80, 47))

net.Receive("ACF_GithubVersion", function()
	local Git = ACF.GitVersion

	Git.Code = net.ReadString()
	Git.Date = net.ReadUInt(32)
	Git.Commits = net.ReadTable()
end)

net.Receive("ACF_ServerVersion", function()
	local Server = ACF.ServerVersion

	Server.Code = net.ReadString()
	Server.Date = net.ReadUInt(32)

	timer.Simple(10, CheckServerVersion)
end)
