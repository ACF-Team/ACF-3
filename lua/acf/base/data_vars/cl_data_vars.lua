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

	-- We'll request the server data vars as soon as the player starts moving
	hook.Add("InitPostEntity", "ACF Request Data Vars", function()
		net.Start("ACF_RequestDataVars")
		net.SendToServer()

		hook.Remove("InitPostEntity", "ACF Request Data Vars")
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
		if not ACF.CheckString(Key) then return end

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
		if not ACF.CheckString(Key) then return end

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

do -- Panel functions
	ACF.DataPanels = ACF.DataPanels or {
		Server = {},
		Client = {},
		Panels = {},
	}

	local PanelMeta  = FindMetaTable("Panel")
	local DataPanels = ACF.DataPanels

	local function GetSubtable(Table, Key)
		local Result = Table[Key]

		if not Result then
			Result     = {}
			Table[Key] = Result
		end

		return Result
	end

	local function StoreData(Destiny, Key, Type, Value, Store)
		local BaseData = GetSubtable(DataPanels[Destiny], Key)
		local TypeData = GetSubtable(BaseData, Type)

		TypeData[Value] = Store or true
	end

	local function ClearFromType(Data, Type, Panel)
		local Saved = Data[Type]

		if not Saved then return end

		for Name, Mode in pairs(Saved) do
			DataPanels[Type][Name][Mode][Panel] = nil -- Weed lmao
		end
	end

	local function ClearData(Panel)
		local Panels = DataPanels.Panels
		local Data   = Panels[Panel]

		-- Apparently this can be called twice
		if Data then
			ClearFromType(Data, "Server", Panel)
			ClearFromType(Data, "Client", Panel)
		end

		Panels[Panel] = nil
	end

	local function HijackThink(Panel)
		local OldThink = Panel.Think
		local Player   = LocalPlayer()

		Panel.Enabled = Panel:IsEnabled()

		function Panel:Think(...)
			if self.ServerVar then
				local Enabled = ACF.CanSetServerData(Player)

				if self.Enabled ~= Enabled then
					self.Enabled = Enabled

					self:SetEnabled(Enabled)
				end
			end

			if OldThink then
				return OldThink(self, ...)
			end
		end
	end

	local function HijackRemove(Panel)
		local OldRemove = Panel.Remove

		function Panel:Remove(...)
			ClearData(self)

			return OldRemove(self, ...)
		end
	end

	local function HijackFunctions(Panel, SetFunction)
		if Panel.Hijacked then return end

		local Setter = Panel[SetFunction] and SetFunction or "SetValue"

		Panel.OldSet   = Panel[Setter]
		Panel.Hijacked = true

		Panel[Setter] = function(This, Value, Forced)
			local ServerVar = This.ServerVar
			local ClientVar = This.ClientVar

			if not (ServerVar or ClientVar) then
				if This.SetCustomValue then
					Value = This:SetCustomValue(nil, nil, Value) or Value
				end

				return This:OldSet(Value)
			end

			if ServerVar then
				ACF.SetServerData(ServerVar, Value, Forced)
			end

			if ClientVar then
				ACF.SetClientData(ClientVar, Value, Forced)
			end
		end

		Panel.Setter = Panel[Setter]

		-- We'll give a basic GetCustomValue function by default
		-- I'll only work with setter panels though
		if not Panel.GetCustomValue then
			function Panel:GetCustomValue(Value)
				if self.ClientVar then
					return ACF.GetClientData(self.ClientVar, Value)
				end

				if self.ServerVar then
					return ACF.GetServerData(self.ServerVar, Value)
				end

				return Value
			end
		end

		HijackThink(Panel)
		HijackRemove(Panel)
	end

	local function UpdatePanels(Panels, Type, Key, Value, IsTracked)
		if not Panels then return end

		for Panel in pairs(Panels) do
			if not IsValid(Panel) then
				ClearData(Panel) -- Somehow Panel:Remove is not being called
				continue
			end

			local Result = Value

			if Panel.SetCustomValue then
				Result = Panel:SetCustomValue(Type, Key, Value, IsTracked)
			end

			if Result ~= nil then
				Panel:OldSet(Result)
			end
		end
	end

	function PanelMeta:DefineSetter(Function)
		if not isfunction(Function) then return end

		self.SetCustomValue = Function

		self:RefreshValue()
	end

	function PanelMeta:DefineGetter(Function)
		if not isfunction(Function) then return end

		self.GetCustomValue = Function

		self:RefreshValue()
	end

	function PanelMeta:RefreshValue(Value)
		if self.GetCustomValue then
			Value = self:GetCustomValue(Value)
		end

		if Value ~= nil then
			self:Setter(Value, true)
		end
	end

	--- Generates the following functions:
	-- Panel:SetClientData(Key, Setter)
	-- Panel:TrackClientData(Key, Setter)
	-- Panel:SetServerData(Key, Setter)
	-- Panel:TrackServerData(Key, Setter)

	for Type in pairs(Queued) do
		PanelMeta["Set" .. Type .. "Data"] = function(Panel, Key, Setter)
			if not ACF.CheckString(Key) then return end

			local Variables   = ACF[Type .. "Data"]
			local SetFunction = ACF["Set" .. Type .. "Data"]

			StoreData("Panels", Panel, Type, Key, "Setter")
			StoreData(Type, Key, "Setter", Panel)

			HijackFunctions(Panel, Setter or "SetValue")

			Panel[Type .. "Var"] = Key

			if Variables[Key] == nil then
				SetFunction(Key, Panel:GetValue())
			end

			Panel:RefreshValue()
		end

		PanelMeta["Track" .. Type .. "Data"] = function(Panel, Key, Setter)
			if not ACF.CheckString(Key) then return end

			StoreData("Panels", Panel, Type, Key, "Tracker")
			StoreData(Type, Key, "Tracker", Panel)

			HijackFunctions(Panel, Setter or "SetValue")

			Panel:RefreshValue()
		end

		hook.Add("ACF_On" .. Type .. "DataUpdate", "ACF Update Panel Values", function(_, Key, Value)
			local Data = DataPanels[Type][Key]

			if not Data then return end -- This variable is not being set or tracked by panels

			UpdatePanels(Data.Setter, Type, Key, Value, IsTracked)
			UpdatePanels(Data.Tracker, Type, Key, Value, IsTracked)
		end)
	end
end
