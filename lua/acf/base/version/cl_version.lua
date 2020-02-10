local Repos = ACF.Repositories

do -- Server syncronization and status printing
	local PrintToChat = ACF.PrintToChat

	local Relevant = {
		Owner = true,
		Name = true,
		Path = true,
		Link = true,
		Branches = true,
	}

	local Unique = {
		Link = true,
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
		Repos[Name] = {
			Server = {}
		}

		local Version = Repos[Name]

		for K, V in pairs(Data) do
			if Relevant[K] then
				Version[K] = V
			end

			if not Unique[K] then
				Version.Server[K] = V
			end
		end
	end

	local function PrintStatus(Server)
		local Branch = ACF.GetBranch(Server.Owner, Server.Name, Server.Head)
		local Lapse = ACF.GetTimeLapse(Branch.Date)

		local Data = Messages[Server.Status]
		local Message = Data.Message

		PrintToChat(Data.Type, Message:format(Server.Name, Server.Code, Lapse))
	end

	net.Receive("ACF_VersionSync", function()
		local Table = net.ReadTable()

		for Name, Data in pairs(Table) do
			GenerateCopy(Name, Data)

			ACF.GetVersion(Data.Owner, Data.Name)
			ACF.GetVersionStatus(Data.Owner, Data.Name)
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
