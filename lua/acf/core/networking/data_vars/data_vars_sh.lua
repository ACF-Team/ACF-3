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
	local Storing

	local function StoreData()
		local Result = {}

		for Key, Default in pairs(Keys) do
			local Value = Persist[Key]

			Result[Key] = {
				Value   = Value,
				Default = Default,
			}
		end

		Storing = nil

		ACF.SaveToJSON(Folder, File, Result, true)
	end

	local function UpdateData(Key)
		if Keys[Key] == nil then return end
		if Values[Key] == nil then return end

		local Value = Values[Key]

		if Persist[Key] ~= Value then
			Persist[Key] = Value

			if not Storing then
				timer.Create("ACF Store Persisted", 1, 1, StoreData)

				Storing = true
			end
		end
	end

	--- Generates the following functions:
	-- ACF.PersistServerData(Key, Default) - Serverside only
	-- ACF.PersistClientData(Key, Default) - Clientside only

	ACF["Persist" .. Realm .. "Data"] = function(Key, Default)
		if not isstring(Key) then return end
		if Default == nil then Default = "nil" end

		Keys[Key] = Default
	end

	hook.Add("ACF_On" .. Realm .. "DataUpdate", "ACF Persisted Data", function(_, Key)
		UpdateData(Key)
	end)

	hook.Add("Initialize", "ACF Load Persisted Data", function()
		local Saved       = ACF.LoadFromFile(Folder, File)
		local SetFunction = ACF["Set" .. Realm .. "Data"]

		if Saved then
			for Key, Stored in pairs(Saved) do
				if Keys[Key] == nil then continue end

				if Stored.Value ~= "nil" then
					SetFunction(Key, Stored.Value)
				end
			end
		end

		-- In case the file doesn't exist or it's missing one of the persisted variables
		for Key, Default in pairs(Keys) do
			if Persist[Key] ~= nil then continue end

			SetFunction(Key, Default)
		end

		hook.Remove("Initialize", "ACF Load Persisted Data")
	end)
end

do -- Data callbacks
	ACF.DataCallbacks = ACF.DataCallbacks or {
		Server = {},
		Client = {},
	}

	local Callbacks = ACF.DataCallbacks

	--- Generates the following functions:
	-- ACF.AddServerDataCallback(Key, Name, Function)
	-- ACF.RemoveServerDataCallback(Key, Name)
	-- ACF.AddClientDataCallback(Key, Name, Function)
	-- ACF.RemoveClientDataCallback(Key, Name)

	for Realm, Callback in pairs(Callbacks) do
		local Queue = {}

		local function ProcessQueue()
			for Key, Data in pairs(Queue) do
				local Store  = Callback[Key]
				local Player = Data.Player
				local Value  = Data.Value

				for _, Function in pairs(Store) do
					Function(Player, Key, Value)
				end

				Queue[Key] = nil
			end
		end

		ACF["Add" .. Realm .. "DataCallback"] = function(Key, Name, Function)
			if not isstring(Key) then return end
			if not isstring(Name) then return end
			if not isfunction(Function) then return end

			local Store = Callback[Key]

			if not Store then
				Callback[Key] = {
					[Name] = Function
				}
			else
				Store[Name] = Function
			end
		end

		ACF["Remove" .. Realm .. "DataCallback"] = function(Key, Name)
			if not isstring(Key) then return end
			if not isstring(Name) then return end

			local Store = Callback[Key]

			if not Store then return end

			Store[Name] = nil
		end

		hook.Add("ACF_On" .. Realm .. "DataUpdate", "ACF Data Callbacks", function(Player, Key, Value)
			if not Callback[Key] then return end

			local Data = Queue[Key]

			if not next(Queue) then
				timer.Create("ACF Data Callback", 0, 1, ProcessQueue)
			end

			if not Data then
				Queue[Key] = {
					Player = Player,
					Value = Value,
				}
			else
				Data.Player = Player
				Data.Value = Value
			end
		end)
	end
end
