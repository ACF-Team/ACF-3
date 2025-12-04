local ACF = ACF

--- Returns whether a client is allowed to set a server datavars
--- @param Player table The player entity to check
--- @return boolean # Whether the player can set server datavars
function ACF.CanSetServerData(Player)
	if not IsValid(Player) then return true end -- No player, probably the server
	if Player:IsSuperAdmin() then return true end

	local AllowAdmin = ACF.GetServerBool("ServerDataAllowAdmin")

	return AllowAdmin and Player:IsAdmin()
end

--- Dealing with client or server accessing its record of the server's data vars
do
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

do -- Data persisting on either realm
	ACF.PersistedKeys = ACF.PersistedKeys or {}
	ACF.PersistedData = ACF.PersistedData or {}

	local Persist = ACF.PersistedData									-- A LUT mapping each persisted variable to its value
	local Keys    = ACF.PersistedKeys									-- A LUT mapping each persisted variable to its default value
	local Realm   = SERVER and "Server" or "Client"						-- "Server"/"Client"
	local Values  = ACF[Realm .. "Data"]								-- ACF.ServerData/ACF.ClientData; The given realm's record of the server/client's data
	local Folder  = "acf/data_vars"
	local File    = SERVER and "stored_sv.json" or "stored_cl.json"
	local Storing	-- Whether a store operation is currently queued

	--- Stores the current persisted data to file
	local function StoreData()
		local Result = {} -- Stores a mapping from each persisted variable to its current value and default value

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

	--- Stores a variable's current value if it has changed from the last stored value
	--- @param Key string The key of the variable to update
	local function UpdateData(Key)
		if Keys[Key] == nil then return end		-- Ignore non-persisted variables
		if Values[Key] == nil then return end	-- Ignore variables that don't exist

		local Value = Values[Key]

		if Persist[Key] ~= Value then
			Persist[Key] = Value

			-- Queue a store operation and call StoreData (after 1 second with an extra retry)
			if not Storing then
				timer.Create("ACF Store Persisted", 1, 1, StoreData)
				Storing = true
			end
		end
	end

	--- Generates the following functions:
	-- ACF.PersistServerData(Key, Default) - Serverside only
	-- ACF.PersistClientData(Key, Default) - Clientside only

	--- Marks a variable as persisted, meaning its value will be saved to file and kept between sessions.
	--- @param Key string The key of the variable to persist
	--- @param Default any The default value of the variable
	ACF["Persist" .. Realm .. "Data"] = function(Key, Default)
		if not isstring(Key) then return end
		if Default == nil then Default = "nil" end

		Keys[Key] = Default
	end

	-- For each realm, store new changes to persisted variables if applicable
	hook.Add("ACF_OnUpdate" .. Realm .. "Data", "ACF Persisted Data", function(_, Key)
		UpdateData(Key)
	end)

	-- For each realm, On initialization, load the persisted data from file and set each variable to its stored value (or default if not found)
	hook.Add("Initialize", "ACF Load Persisted Data", function()
		local Saved       = ACF.LoadFromFile(Folder, File)
		local SetFunction = ACF["Set" .. Realm .. "Data"]	-- ACF.SetServerData/ACF.SetClientData

		if Saved then
			for Key, Stored in pairs(Saved) do
				if Keys[Key] == nil then continue end

				if Stored.Value ~= "nil" then
					SetFunction(Key, Stored.Value)
				end
			end
		end

		-- In case the file doesn't exist or it's missing one of the persisted variables, use the default value.
		for Key, Default in pairs(Keys) do
			if Persist[Key] ~= nil then continue end

			SetFunction(Key, Default)
		end

		hook.Run("ACF_OnLoadPersistedData")
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

	-- Misleading IMO, Callback is actually a LUT mapping each variable to its attached callbacks
	for Realm, Callback in pairs(Callbacks) do
		local Queue = {}	-- A LUT mapping each variable to the player and value to pass to the callbacks

		--- Actually runs the callbacks for each variable in the queue with the latest information
		local function ProcessQueue()
			for Key, Data in pairs(Queue) do
				local Store  = Callback[Key] -- The callbacks for this variable
				local Player = Data.Player
				local Value  = Data.Value

				-- Run each callback for this variable with the latest information
				for _, Function in pairs(Store) do
					Function(Player, Key, Value)
				end

				Queue[Key] = nil
			end
		end

		--- Registers a callback to be ran when a variable is updated. Similar to hooks.
		--- The name is just a UUID so you can have multiple callbacks for the same variable and be able to remove them individually.
		--- @param Key string The key of the variable to register the callback for
		--- @param Name string A unique identifier for this callback
		--- @param Function function The callback function to run when the variable is updated. It will be passed (Player, Key, Value)
		ACF["Add" .. Realm .. "DataCallback"] = function(Key, Name, Function)
			if not isstring(Key) then return end
			if not isstring(Name) then return end
			if not isfunction(Function) then return end

			local Store = Callback[Key] -- The callbacks for this variable

			if not Store then
				-- No callbacks for this variable yet, Initialize a new LUT
				Callback[Key] = {[Name] = Function}
			else
				-- Already have a callback LUT for this variable, just add a new entry/update an existing one
				Store[Name] = Function
			end
		end

		--- Removes a previously registered callback.
		--- @param Key string The key of the variable the callback was registered for
		--- @param Name string The unique identifier used when registering the callback
		ACF["Remove" .. Realm .. "DataCallback"] = function(Key, Name)
			if not isstring(Key) then return end
			if not isstring(Name) then return end

			local Store = Callback[Key]

			if not Store then return end

			Store[Name] = nil
		end

		-- Handle running the callbacks when a variable is updated
		hook.Add("ACF_OnUpdate" .. Realm .. "Data", "ACF Data Callbacks", function(Player, Key, Value)
			if not Callback[Key] then return end

			local Data = Queue[Key]

			-- Schedule the callbacks to be processed if one isn't already queued
			if not next(Queue) then
				timer.Create("ACF Data Callback", 0, 1, ProcessQueue)
			end

			if not Data then
				-- Not already queued, Initialize a new entry
				Queue[Key] = {
					Player = Player,
					Value = Value,
				}
			else
				-- Already queued, just update the information
				Data.Player = Player
				Data.Value = Value
			end
		end)
	end
end
