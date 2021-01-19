local ACF = ACF

do -- Server syncronization and status printing
	local Repos = ACF.Repositories
	local Queue = {}
	local Standby

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

	local function StoreInfo(Name, Data, Destiny)
		local NewData = Data[Destiny]

		if not NewData then return end

		local Repo   = ACF.GetRepository(Name)
		local Source = Repo[Destiny]

		for K, V in pairs(NewData) do
			Source[K] = V
		end
	end

	local function PrintStatus(Server)
		local Branch  = ACF.GetBranch(Server.Name, Server.Head)
		local Lapse   = Branch and ACF.GetTimeLapse(Branch.Date)
		local Data    = Messages[Server.Status or "Unable to check"]

		ACF.PrintToChat(Data.Type, Data.Message:format(Server.Name, Server.Code, Lapse))
	end

	local function PrepareStatus()
		if Standby then return end

		hook.Add("CreateMove", "ACF Print Version", function(Move)
			if Move:GetButtons() ~= 0 then
				for Name, Repo in pairs(Queue) do
					PrintStatus(Repo.Server)

					Queue[Name] = nil
				end

				Standby = nil

				hook.Remove("CreateMove", "ACF Print Version")
			end
		end)

		Standby = true
	end

	local function QueueStatusMessage(Name)
		if Queue[Name] then return end

		Queue[Name] = ACF.GetRepository(Name)

		PrepareStatus()
	end

	net.Receive("ACF_VersionSync", function()
		local Values = util.JSONToTable(net.ReadString())

		for Name, Repo in pairs(Values) do
			StoreInfo(Name, Repo, "Branches")
			StoreInfo(Name, Repo, "Server")

			ACF.CheckLocalStatus(Name)

			QueueStatusMessage(Name)

			hook.Run("ACF_UpdatedRepository", Name, Repos[Name])
		end
	end)

	ACF.AddMessageType("Update_Ok", "Updates")
	ACF.AddMessageType("Update_Old", "Updates", Color(255, 160, 0))
	ACF.AddMessageType("Update_Error", "Updates", Color(241, 80, 47))
end
