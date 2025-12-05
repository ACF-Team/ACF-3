local ACF      = ACF
local Client   = ACF.ClientData 				-- Client's record of its own data
local Server   = ACF.ServerData 				-- Client's record of the server's data
local Queued   = { Client = {}, Server = {} } 	-- For each realm, a LUT mapping variables to true if they need to be sent
local LastSent = { Client = {}, Server = {} } 	-- For each realm, LUT mapping variables to their last sent value

--- Determines what needs to be sent based on what was last sent (delta)
--- @param Type string		# The type (realm) of data to check (Client or Server)
--- @param Values table		# A LUT mapping the variable names to their current values
--- @param Result table		# The result table to populate
local function PrepareQueue(Type, Values, Result)
	local Queue = Queued[Type]

	if not next(Queue) then return end

	local Sent = LastSent[Type] -- For the given realm, LUT mapping variables to their last sent value
	local Data = {}	-- Stores what needs to be sent

	for K in pairs(Queue) do
		local Value = Values[K]

		if Value ~= Sent[K] then Data[K] = Value end -- Send an update if the value has changed since last sent

		Queue[K] = nil -- Clear out the queue of this item
	end

	Result[Type] = Data -- Result for this realm now stores what we need to send.
end

--- When called, determines what changes need to be sent and networks them from client to server.
local function SendQueued()
	local Result = {}

	-- Note that Result looks like { Client = {}, Server = {}}
	PrepareQueue("Client", Client, Result)
	PrepareQueue("Server", Server, Result)

	-- If there are new changes, send them to the server.
	if next(Result) then
		local JSON = util.TableToJSON(Result)

		net.Start("ACF_DataVarNetwork")
			net.WriteString(JSON)
		net.SendToServer()
	end
end

--- Marks a given variable (by key) to be queued for sending.
--- This is rate limitted to avoid net spam.
--- @param Key string The key of the variable to key
--- @param IsServer boolean Whether the key is a server key (or client key)
local function NetworkData(Key, IsServer)
	local Type    = IsServer and "Server" or "Client"
	local Destiny = Queued[Type]

	if Destiny[Key] then return end -- Already queued

	Destiny[Key] = true -- Mark this to be queued

	-- When NetworkData is first called, a timer is created and left untouched, which will periodically call SendQueued.
	-- This avoids spamming the server with net messages every time a data var is changed.
	if timer.Exists("ACF Network Data Vars") then return end
	timer.Create("ACF Network Data Vars", 0, 1, SendQueued)
end

-- Deals with syncing the client's record of the server's data
do
	local function ProcessData(Values, Received)
		if not Received then return end

		for K, V in pairs(Received) do
			if Values[K] ~= V then
				Values[K] = V

				hook.Run("ACF_OnUpdateServerData", nil, K, V)
			end

			Received[K] = nil
		end
	end

	-- NOTE: This only seems to run to send the ACF globals to a client when they first join?
	net.Receive("ACF_DataVarNetwork", function(_, Player)
		local Received = util.JSONToTable(net.ReadString())

		if IsValid(Player) then return end -- NOTE: Can this even happen? Craftian says no <3

		ProcessData(Server, Received)
	end)
end

-- Various getters to get client's record of its own data
do
	--- Gets the value of a client data var, or the default value if it doesn't exist.
	local function GetData(Key, Default)
		if Key == nil then return Default end

		local Value = Client[Key]

		if Value ~= nil then return Value end

		return Default
	end

	--- Returns a LUT of each client data var to its value.
	function ACF.GetAllClientData(NoCopy)
		if NoCopy then return Client end

		local Result = {}

		for K, V in pairs(Client) do
			Result[K] = V
		end

		return Result
	end

	--- Casts and returns a client data var as a boolean, or the default value.
	function ACF.GetClientBool(Key, Default)
		return tobool(GetData(Key, Default))
	end

	--- Casts and returns a client data var as a number, or the default value.
	function ACF.GetClientNumber(Key, Default)
		local Value = GetData(Key, Default)

		return ACF.CheckNumber(Value, 0)
	end

	--- Casts and returns a client data var as a string, or the default value.
	function ACF.GetClientString(Key, Default)
		local Value = GetData(Key, Default)

		return ACF.CheckString(Value, "")
	end

	ACF.GetClientData = GetData
	ACF.GetClientRaw = GetData
end

--- Dealing with setting client setting its own data vars
do
	--- Sets a client data var and networks it to the server.
	--- Internally calls the ACF_OnUpdateClientData hook
	--- @param Key string The key of the datavar
	--- @param Value any The value the datavar
	--- @param Forced boolean Whether to send regardless of if the value has changed
	function ACF.SetClientData(Key, Value, Forced)
		if ACF.DisableClientData then return end
		if not isstring(Key) then return end

		Value = Value or false

		if Forced or Client[Key] ~= Value then
			Client[Key] = Value

			hook.Run("ACF_OnUpdateClientData", LocalPlayer(), Key, Value)

			NetworkData(Key)
		end
	end
end

--- Dealing with client setting its own record of server data vars
do
	--- Proposes changes to server datavars and networks them to server.
	--- Internally calls the ACF_OnUpdateServerData hook.
	--- @param Key string The key of the datavar
	--- @param Value any The value of the datavar
	--- @param Forced boolean Whether to send regardless of if the value has changed
	function ACF.SetServerData(Key, Value, Forced)
		if not isstring(Key) then return end

		local Player = LocalPlayer()

		-- Check if the client is allowed to set things on the server
		-- (Usually restricted to super admins and server owners)
		if not ACF.CanSetServerData(Player) then return end

		Value = Value or false

		if Forced or Server[Key] ~= Value then
			Server[Key] = Value

			hook.Run("ACF_OnUpdateServerData", Player, Key, Value)

			NetworkData(Key, true)
		end
	end
end
