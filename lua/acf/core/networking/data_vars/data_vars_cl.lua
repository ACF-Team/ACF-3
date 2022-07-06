local ACF      = ACF
local Client   = ACF.ClientData
local Server   = ACF.ServerData
local Queued   = { Client = {}, Server = {} }
local LastSent = { Client = {}, Server = {} }

local function PrepareQueue(Type, Values, Result)
	local Queue = Queued[Type]

	if not next(Queue) then return end

	local Sent = LastSent[Type]
	local Data = {}

	for K in pairs(Queue) do
		local Value = Values[K]

		if Value ~= Sent[K] then
			Data[K] = Value
		end

		Queue[K] = nil
	end

	Result[Type] = Data
end

local function SendQueued()
	local Result = {}

	PrepareQueue("Client", Client, Result)
	PrepareQueue("Server", Server, Result)

	if next(Result) then
		local JSON = util.TableToJSON(Result)

		net.Start("ACF_DataVarNetwork")
			net.WriteString(JSON)
		net.SendToServer()
	end
end

local function NetworkData(Key, IsServer)
	local Type    = IsServer and "Server" or "Client"
	local Destiny = Queued[Type]

	if Destiny[Key] then return end -- Already queued

	Destiny[Key] = true

	-- Avoiding net message spam by sending all the events of a tick at once
	if timer.Exists("ACF Network Data Vars") then return end

	timer.Create("ACF Network Data Vars", 0, 1, SendQueued)
end

do -- Server data var syncronization
	local function ProcessData(Values, Received)
		if not Received then return end

		for K, V in pairs(Received) do
			if Values[K] ~= V then
				Values[K] = V

				hook.Run("ACF_OnServerDataUpdate", nil, K, V)
			end

			Received[K] = nil
		end
	end

	net.Receive("ACF_DataVarNetwork", function(_, Player)
		local Received = util.JSONToTable(net.ReadString())

		if IsValid(Player) then return end -- NOTE: Can this even happen?

		ProcessData(Server, Received)
	end)
end

do -- Client data getter functions
	local function GetData(Key, Default)
		if Key == nil then return Default end

		local Value = Client[Key]

		if Value ~= nil then return Value end

		return Default
	end

	function ACF.GetAllClientData(NoCopy)
		if NoCopy then return Client end

		local Result = {}

		for K, V in pairs(Client) do
			Result[K] = V
		end

		return Result
	end

	function ACF.GetClientBool(Key, Default)
		return tobool(GetData(Key, Default))
	end

	function ACF.GetClientNumber(Key, Default)
		local Value = GetData(Key, Default)

		return ACF.CheckNumber(Value, 0)
	end

	function ACF.GetClientString(Key, Default)
		local Value = GetData(Key, Default)

		return ACF.CheckString(Value, "")
	end

	ACF.GetClientData = GetData
	ACF.GetClientRaw = GetData
end

do -- Client data setter function
	function ACF.SetClientData(Key, Value, Forced)
		if not isstring(Key) then return end

		Value = Value or false

		if Forced or Client[Key] ~= Value then
			Client[Key] = Value

			hook.Run("ACF_OnClientDataUpdate", LocalPlayer(), Key, Value)

			NetworkData(Key)
		end
	end
end

do -- Server data setter function
	function ACF.SetServerData(Key, Value, Forced)
		if not isstring(Key) then return end

		local Player = LocalPlayer()

		if not ACF.CanSetServerData(Player) then return end

		Value = Value or false

		if Forced or Server[Key] ~= Value then
			Server[Key] = Value

			hook.Run("ACF_OnServerDataUpdate", Player, Key, Value)

			NetworkData(Key, true)
		end
	end
end
