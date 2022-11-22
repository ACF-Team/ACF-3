local ACF    = ACF
local Client = ACF.ClientData
local Server = ACF.ServerData
local Queued = {}

local function PrepareQueue(Type, Values)
	local Queue = Queued[Type]

	if not next(Queue) then return end

	local Data = {}

	for K in pairs(Queue) do
		Data[K]  = Values[K]
		Queue[K] = nil
	end

	return util.TableToJSON(Data)
end

local function SendQueued()
	local Broadcast = Queued.Broadcast

	if Broadcast then
		if #player.GetAll() > 0 then
			net.Start("ACF_DataVarNetwork")
				net.WriteString(PrepareQueue("Broadcast", Server))
			net.Broadcast()
		end

		Queued.Broadcast = nil
	end

	for Player in pairs(Queued) do
		net.Start("ACF_DataVarNetwork")
			net.WriteString(PrepareQueue(Player, Server))
		net.Send(Player)

		Queued[Player] = nil
	end
end

local function NetworkData(Key, Player)
	local Type    = IsValid(Player) and Player or "Broadcast"
	local Destiny = Queued[Type]

	if Destiny and Destiny[Key] then return end -- Already queued

	if not Destiny then
		Queued[Type] = {
			[Key] = true
		}
	else
		Destiny[Key] = true
	end

	-- Avoiding net message spam by sending all the events of a tick at once
	if timer.Exists("ACF Network Data Vars") then return end

	timer.Create("ACF Network Data Vars", 0, 1, SendQueued)
end

do -- Data syncronization
	util.AddNetworkString("ACF_DataVarNetwork")

	local function ProcessData(Player, Type, Values, Received)
		local Data = Received[Type]

		if not Data then return end

		local Hook = "ACF_On" .. Type .. "DataUpdate"

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

		if not IsValid(Player) then return end -- NOTE: Can this even happen?
		if not Client[Player] then return end -- Player no longer exists, discarding.

		ProcessData(Player, "Client", Client[Player], Received)

		-- There's a check on the clientside for this, but we won't trust it
		if ACF.CanSetServerData(Player) then
			ProcessData(Player, "Server", Server, Received)
		else
			local Data = Received.Server

			if not Data then return end

			-- This player shouldn't be updating these values
			-- So we'll just force him to update with the correct stuff
			for Key in pairs(Data) do
				NetworkData(Key, Player)
			end
		end
	end)

	-- If a player does not exist, we'll add it
	setmetatable(Client, {
		__index = function(Table, Key)
			if not IsValid(Key) then return end
			if not Key:IsPlayer() then return end

			local Tab = {}

			Table[Key] = Tab

			return Tab
		end
	})

	hook.Add("ACF_OnPlayerLoaded", "ACF Data Var Syncronization", function(Player)
		-- Server data var syncronization
		for Key in pairs(Server) do
			NetworkData(Key, Player)
		end
	end)

	hook.Add("PlayerDisconnected", "ACF Data Var Syncronization", function(Player)
		Client[Player] = nil
		Queued[Player] = nil
	end)
end

do -- Client data getter functions
	local function GetData(Player, Key, Default)
		if not IsValid(Player) then return Default end
		if Key == nil then return Default end

		local Data  = Client[Player]
		local Value = Data and Data[Key]

		if Value ~= nil then return Value end

		return Default
	end

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

	function ACF.GetClientBool(Player, Key, Default)
		return tobool(GetData(Player, Key, Default))
	end

	function ACF.GetClientNumber(Player, Key, Default)
		local Value = GetData(Player, Key, Default)

		return ACF.CheckNumber(Value, 0)
	end

	function ACF.GetClientString(Player, Key, Default)
		local Value = GetData(Player, Key, Default)

		return ACF.CheckString(Value, "")
	end

	ACF.GetClientData = GetData
	ACF.GetClientRaw = GetData
end

do -- Server data setter function
	function ACF.SetServerData(Key, Value, Forced)
		if not isstring(Key) then return end

		Value = Value or false

		if Forced or Server[Key] ~= Value then
			Server[Key] = Value

			hook.Run("ACF_OnServerDataUpdate", nil, Key, Value)

			NetworkData(Key)
		end
	end
end
