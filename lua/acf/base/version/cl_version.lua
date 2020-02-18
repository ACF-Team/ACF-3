local Repos = ACF.Repositories

do -- Server syncronization and status printing
	local PrintToChat = ACF.PrintToChat

	local Unique = {
		Branches = true,
	}

	local Messages = {
		["Unable to check"] = {
			Type = "Update_Error",
			Message = "%s: Server is running on version %s. Unable to check for updates.",
		},
		["Out of date"] = {
			Type = "Update_Old",
			Message = "%s: Server is running on version %s. There's an update available, pushed %s.",
		},
		["Up to date"] = {
			Type = "Update_Ok",
			Message = "%s: Server is running on version %s. No updates available, running on the latest version."
		},
	}

	local function GenerateCopy(Name, Data)
		local Version = ACF.GetVersion(Name)

		if not Version.Server then
			Version.Server = {}
		end

		for K, V in pairs(Data) do
			if not Unique[K] then
				Version.Server[K] = V
			else
				Version[K] = V
			end
		end

		ACF.GetVersionStatus(Name)
	end

	local function PrintStatus(Server)
		local Branch = ACF.GetBranch(Server.Name, Server.Head)
		local Lapse = ACF.GetTimeLapse(Branch.Date)

		local Data = Messages[Server.Status]
		local Message = Data.Message

		PrintToChat(Data.Type, Message:format(Server.Name, Server.Code, Lapse))
	end

	net.Receive("ACF_VersionSync", function()
		local Table = net.ReadTable()

		for Name, Data in pairs(Table) do
			GenerateCopy(Name, Data)
		end

		hook.Add("CreateMove", "ACF Print Version", function(Move)
			if Move:GetButtons() ~= 0 then
				for _, Data in pairs(Repos) do
					PrintStatus(Data.Server)
				end

				hook.Remove("CreateMove", "ACF Print Version")
			end
		end)
	end)

	ACF.AddMessageType("Update_Ok", "Updates")
	ACF.AddMessageType("Update_Old", "Updates", Color(255, 160, 0))
	ACF.AddMessageType("Update_Error", "Updates", Color(241, 80, 47))
end
