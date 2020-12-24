local ACF = ACF

function ACF.CanSetServerData(Player)
	if not IsValid(Player) then return true end -- No player, probably the server
	if Player:IsSuperAdmin() then return true end

	local AllowAdmin = ACF.GetServerBool("ServerDataAllowAdmin")

	return AllowAdmin and Player:IsAdmin()
end

do -- Server data getter functions
	local Server = ACF.ServerData

	local function GetData(Key, Default)
		if Key == nil then return Default end

		local Value = Server[Key]

		if Value ~= nil then return Value end

		return Default
	end

	function ACF.GetAllServerData(NoCopy)
		if NoCopy then return Server end

		local Result = {}

		for K, V in pairs(Server) do
			Result[K] = V
		end

		return Result
	end

	function ACF.GetServerBool(Key, Default)
		return tobool(GetData(Key, Default))
	end

	function ACF.GetServerNumber(Key, Default)
		local Value = GetData(Key, Default)

		return ACF.CheckNumber(Value, 0)
	end

	function ACF.GetServerString(Key, Default)
		local Value = GetData(Key, Default)

		return ACF.CheckString(Value, "")
	end

	ACF.GetServerData = GetData
	ACF.GetServerRaw = GetData
end

do -- Data persisting
	ACF.PersistedKeys = ACF.PersistedKeys or {}
	ACF.PersistedData = ACF.PersistedData or {}

	local Persist = ACF.PersistedData
	local Keys    = ACF.PersistedKeys
	local Realm   = SERVER and "Server" or "Client"
	local Values  = ACF[Realm .. "Data"]
	local Folder  = "acf/data_vars"
	local File    = "stored.json"

	local function StoreData()
		local Result = {}

		for Key, Default in pairs(Keys) do
			local Value = Persist[Key]

			Result[Key] = {
				Value   = Value,
				Default = Default,
			}
		end

		ACF.SaveToJSON(Folder, File, Result, true)
	end

	local function UpdateData(Key)
		if Keys[Key] == nil then return end

		local Default = Keys[Key]
		local Value   = Either(Values[Key] ~= nil, Values[Key], Default)

		if Persist[Key] ~= Value then
			Persist[Key] = Value

			if timer.Exists("ACF Store Persisted") then return end

			timer.Create("ACF Store Persisted", 1, 1, StoreData)
		end
	end

	--- Generates the following functions:
	-- ACF.PersistServerData(Key, Default) - Serverside only
	-- ACF.PersistClientData(Key, Default) - Clientside only

	ACF["Persist" .. Realm .. "Data"] = function(Key, Default)
		if not ACF.CheckString(Key) then return end
		if Default == nil then Default = "nil" end

		Keys[Key] = Default

		UpdateData(Key)
	end

	hook.Add("ACF_On" .. Realm .. "DataUpdate", "ACF Persisted Data", function(_, Key)
		UpdateData(Key)
	end)

	hook.Add("Initialize", "ACF Load Persisted Data", function()
		local Saved       = ACF.LoadFromFile(Folder, File)
		local SetFunction = ACF["Set" .. Realm .. "Data"]

		if Saved then
			for Key, Stored in pairs(Saved) do
				if Keys[Key] == nil then
					Keys[Key] = Stored.Default
				end

				if Stored.Value ~= "nil" then
					SetFunction(Key, Stored.Value)
				end
			end
		else
			for Key, Default in pairs(Keys) do
				local Value = Either(Persist[Key] ~= nil, Persist[Key], Default)

				SetFunction(Key, Value)
			end
		end

		hook.Remove("Initialize", "ACF Load Persisted Data")
	end)
end
