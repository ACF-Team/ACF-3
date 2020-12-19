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

	local Data   = ACF.PersistedData
	local Keys   = ACF.PersistedKeys
	local Realm  = SERVER and "Server" or "Client"
	local Values = ACF[Realm .. "Data"]
	local Folder = "acf/data_vars"
	local File   = "persisted.json"

	local function LoadData()
		local Saved = ACF.LoadFromFile(Folder, File)

		if Saved then
			local SetFunction = ACF["Set" .. Realm .. "Data"]

			for Key, Value in pairs(Saved) do
				Keys[Key] = true

				if Value ~= "nil" then
					SetFunction(Key, Value)
				end
			end
		end

		hook.Remove("Initialize", "ACF Load Persisted Data")
	end

	local function StoreData()
		local Result = {}

		for Key in pairs(Keys) do
			local Value = Data[Key]

			Result[Key] = Either(Value ~= nil, Value, "nil")
		end

		ACF.SaveToJSON(Folder, File, Result, true)
	end

	local function UpdateData(Key)
		if not Keys[Key] then return end
		if Values[Key] == nil then return end

		local Value = Values[Key]

		if Data[Key] ~= Value then
			Data[Key] = Value

			if timer.Exists("ACF Store Persisted") then return end

			timer.Create("ACF Store Persisted", 1, 1, StoreData)
		end
	end

	ACF["Persist" .. Realm .. "Data"] = function(Key)
		if not ACF.CheckString(Key) then return end
		if Keys[Key] then return end -- Already stored

		Keys[Key] = true

		UpdateData(Key)
	end

	hook.Add("ACF_On" .. Realm .. "DataUpdate", "ACF Persisted Data", function(_, Key)
		UpdateData(Key)
	end)

	hook.Add("Initialize", "ACF Load Persisted Data", LoadData)
end
