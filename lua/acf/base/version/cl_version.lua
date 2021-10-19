local ACF = ACF

do -- Server syncronization and status printing
	local Repos = ACF.Repositories

	local function StoreInfo(Name, Data, Destiny)
		local NewData = Data[Destiny]

		if not NewData then return end

		local Repo   = ACF.GetRepository(Name)
		local Source = Repo[Destiny]

		for K, V in pairs(NewData) do
			Source[K] = V
		end
	end

	net.Receive("ACF_VersionSync", function()
		local Values = util.JSONToTable(net.ReadString())

		for Name, Repo in pairs(Values) do
			StoreInfo(Name, Repo, "Branches")
			StoreInfo(Name, Repo, "Server")

			ACF.CheckLocalStatus(Name)

			hook.Run("ACF_UpdatedRepository", Name, Repos[Name])
		end
	end)

	ACF.AddMessageType("Update_Ok", "Updates")
	ACF.AddMessageType("Update_Old", "Updates", Color(255, 160, 0))
	ACF.AddMessageType("Update_Error", "Updates", Color(241, 80, 47))
end
