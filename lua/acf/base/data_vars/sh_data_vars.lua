local ACF    = ACF
local Server = ACF.ServerData

function ACF.CanSetServerData(Player)
	if not IsValid(Player) then return true end -- No player, probably the server
	if Player:IsSuperAdmin() then return true end

	local AllowAdmin = ACF.GetServerBool("ServerDataAllowAdmin")

	return AllowAdmin and Player:IsAdmin()
end

do -- Server data getter functions
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