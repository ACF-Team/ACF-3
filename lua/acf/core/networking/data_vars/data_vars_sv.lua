local ACF    = ACF
local Client = ACF.ClientData	-- Server's record of each client's data
local Server = ACF.ServerData	-- Server's record of its own data
local Queued = {}				-- For each player (or "Broadcast"), a LUT mapping variables to true if they need to be sent

-- NOTE: Queued's structure isn't fixed; a subtable is created for each player

--- Determines what needs to be sent based on what was last sent (delta)
--- @param Type string		# The type (realm) of data to check (Client or Server)
--- @param Values table		# A LUT mapping the variable names to their current values
--- @return string|nil		# The JSON string to send, or nil if nothing to send
local function PrepareQueue(Type, Values)
	local Queue = Queued[Type]

	if not next(Queue) then return end

	local Data = {} -- Stores what needs to be sent

	-- TODO: Why not just have Data = Queue and Queue = {} ?
	for K in pairs(Queue) do
		Data[K]  = Values[K]	-- Need to send this value
		Queue[K] = nil			-- Clear out the queue of this item
	end

	return util.TableToJSON(Data)
end

--- When called, determines what changes need to be sent and networks them from server to clients.
local function SendQueued()
	local Broadcast = Queued.Broadcast -- The specific subtable in the queue for broadcasting to all players

	--If there are changes to be broadcast, send them to all players.
	if Broadcast then
		if #player.GetAll() > 0 then
			net.Start("ACF_DataVarNetwork")
				net.WriteString(PrepareQueue("Broadcast", Server))
			net.Broadcast()
		end

		Queued.Broadcast = nil
	end

	-- For each player, if they have changes, send them to that player.
	for Player in pairs(Queued) do
		net.Start("ACF_DataVarNetwork")
			net.WriteString(PrepareQueue(Player, Server))
		net.Send(Player)

		Queued[Player] = nil
	end
end

--- Marks a given variable (by key) to be queued for sending.
--- This is rate limitted to avoid net spam.
--- @param Key string The key of the variable to key
--- @param Player table|nil The player to send to, or nil to broadcast to all
local function NetworkData(Key, Player)
	local Type    = IsValid(Player) and Player or "Broadcast"
	local Destiny = Queued[Type] -- The specific subtable in the queue for this player (or broadcast)

	if Destiny and Destiny[Key] then return end -- Already queued

	if not Destiny then
		-- Since Type can represent a player, we need to initialize it if they don't have an entry yet
		Queued[Type] = {[Key] = true}
	else
		-- Mark this to be queued
		Destiny[Key] = true
	end

	-- When NetworkData is first called, a timer is created and left untouched, which will periodically call SendQueued.
	-- This avoids spamming clients with net messages every time a data var is changed.
	if timer.Exists("ACF Network Data Vars") then return end
	timer.Create("ACF Network Data Vars", 0, 1, SendQueued)
end

-- Deals with syncing the server's record of the client's data and the client's proposed changes to server data
do
	util.AddNetworkString("ACF_DataVarNetwork")

	--- Processes received data for a given player and realm, updating their stored values and calling hooks as needed
	--- @param Player table The player the data is received from
	--- @param Type string The realm of data being processed ("Client"/"Server")
	--- @param Values table A LUT mapping variable names to their current values
	--- @param Received table The table of received data from the network message
	local function ProcessData(Player, Type, Values, Received)
		local Data = Received[Type] -- The received data for this realm

		if not Data then return end -- Nothing to process

		local Hook = "ACF_OnUpdate" .. Type .. "Data"

		for K, V in pairs(Data) do
			if Values[K] ~= V then
				Values[K] = V

				hook.Run(Hook, Player, K, V)
			end

			Data[K] = nil
		end
	end

	net.Receive("ACF_DataVarNetwork", function(_, Player)
		local Received = util.JSONToTable(net.ReadString())

		if not IsValid(Player) then return end -- NOTE: Can this even happen? Probably not.
		if not Client[Player] then return end -- Player no longer exists, discarding.

		-- Process the server's record of this client's data
		ProcessData(Player, "Client", Client[Player], Received)

		-- There's a check on the clientside for this, but we won't trust it
		if ACF.CanSetServerData(Player) then
			-- Process the client's proposed changes to server data
			ProcessData(Player, "Server", Server, Received)
		else
			-- The player isn't allowed to set server data, so we'll just re-send the correct values to them
			local Data = Received.Server

			if not Data then return end

			for Key in pairs(Data) do
				NetworkData(Key, Player)
			end
		end
	end)

	-- If a player does not exist, we'll add an entry for them.
	setmetatable(Client, {
		__index = function(Table, Key)
			if not IsValid(Key) then return end
			if not Key:IsPlayer() then return end

			local Tab = {}

			Table[Key] = Tab

			return Tab
		end
	})

	-- When a player first joins, we send them all the server's data vars
	hook.Add("ACF_OnLoadPlayer", "ACF Data Var Syncronization", function(Player)
		for Key in pairs(Server) do
			NetworkData(Key, Player)
		end
	end)

	-- When a player disconnects, we remove their entries
	hook.Add("PlayerDisconnected", "ACF Data Var Syncronization", function(Player)
		Client[Player] = nil
		Queued[Player] = nil
	end)
end

-- Various getters to get the server's record of a client's data
do
	--- Gets the value of a client's data var, or the default value if it doesn't exist.
	local function GetData(Player, Key, Default)
		if not IsValid(Player) then return Default end
		if Key == nil then return Default end

		local Data  = Client[Player]
		local Value = Data and Data[Key]

		if Value ~= nil then return Value end

		return Default
	end

	--- Returns a LUT of each client data var to its value for the given player.
	function ACF.GetAllClientData(Player, NoCopy)
		if not IsValid(Player) then return {} end

		local Data = Client[Player]

		if not Data then return {} end
		if NoCopy then return Data end

		local Result = {}

		for K, V in pairs(Data) do
			Result[K] = V
		end

		return Result
	end

	-- Casts and returns a client data var as a boolean, or the default value.
	function ACF.GetClientBool(Player, Key, Default)
		return tobool(GetData(Player, Key, Default))
	end

	-- Casts and returns a client data var as a number, or the default value.
	function ACF.GetClientNumber(Player, Key, Default)
		local Value = GetData(Player, Key, Default)

		return ACF.CheckNumber(Value, 0)
	end

	-- Casts and returns a client data var as a string, or the default value.
	function ACF.GetClientString(Player, Key, Default)
		local Value = GetData(Player, Key, Default)

		return ACF.CheckString(Value, "")
	end

	--- When called, returns all the table storing all of the client's datavars
	ACF.GetClientData = GetData
	ACF.GetClientRaw = GetData
end

-- Dealing with setting server setting its own data vars
do
	--- Sets a server datavar and networks it to the client
	--- The server cannot modify the client because we don't want ACF to natively support servers modifying the client
	--- Internally calls the ACF_OnUpdateServerData hook
	--- @param Key string The key of the datavar
	--- @param Value any The value the datavar
	--- @param Forced boolean Whether to send regardless of difference checks
	function ACF.SetServerData(Key, Value, Forced)
		if not isstring(Key) then return end

		Value = Value or false

		if Forced or Server[Key] ~= Value then
			Server[Key] = Value

			hook.Run("ACF_OnUpdateServerData", nil, Key, Value)

			NetworkData(Key)
		end
	end

	-- TODO: If we want to support copying settings from an entity, we need the server to be able to set client data vars too...
end
