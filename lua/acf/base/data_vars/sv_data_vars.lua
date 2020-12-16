local ACF    = ACF
local Client = ACF.ClientData

do -- Data syncronization
	util.AddNetworkString("ACF_DataVarNetwork")

	local function ProcessData(Player, Type, Values, Received)
		local Data = Received[Type]

		if not Data then return end

		local Hook = "ACF_On" .. Type .. "DataUpdate"

		for K, V in pairs(Data) do
			Values[K] = V
			Data[K] = nil

			hook.Run(Hook, Player, K, V)
		end
	end

	net.Receive("ACF_DataVarNetwork", function(_, Player)
		local Received = util.JSONToTable(net.ReadString())

		if IsValid(Player) then
			ProcessData(Player, "Client", Client[Player], Received)
		end
	end)

	hook.Add("PlayerInitialSpawn", "ACF Client Data", function(Player)
		Client[Player] = {}
	end)

	hook.Add("PlayerDisconnected", "ACF Client Data", function(Player)
		Client[Player] = nil
	end)
end

do -- Read functions
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

		if NoCopy then return Data or {} end

		local Result = {}

		if Data then
			for K, V in pairs(Data) do
				Result[K] = V
			end
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
