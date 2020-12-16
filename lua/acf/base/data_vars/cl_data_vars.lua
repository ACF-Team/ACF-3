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

do -- Client data retrieval functions
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

do -- Write function
	function ACF.SetClientData(Key, Value)
		if not isstring(Key) then return end

		Value = Value or false

		if Client[Key] ~= Value then
			Client[Key] = Value

			hook.Run("ACF_OnClientDataUpdate", LocalPlayer(), Key, Value)

			NetworkData(Key)
		end
	end
end

do -- Panel functions
	local PANEL = FindMetaTable("Panel")
	local Trackers = {}
	local Setters = {}
	local Variables = {
		Trackers = {},
		Setters = {},
	}

	local function AddVariable(Panel, Key, Target)
		local Data = Target[Key]

		if not Data then
			Target[Key] = {
				[Panel] = true
			}
		else
			Data[Panel] = true
		end
	end

	local function AddTracker(Panel, Key)
		local Data = Trackers[Panel]

		if not Data then
			Trackers[Panel] = {
				[Key] = true
			}
		else
			Data[Key] = true
		end

		AddVariable(Panel, Key, Variables.Trackers)
	end

	local function AddSetter(Panel, Key)
		local Data = Setters[Panel]

		if not Data then
			Setters[Panel] = {
				[Key] = true
			}
		else
			Data[Key] = true
		end

		AddVariable(Panel, Key, Variables.Setters)
	end

	local function ClearVariables(Panel)
		if Trackers[Panel] then
			for K in pairs(Trackers[Panel]) do
				Variables.Trackers[K][Panel] = nil
			end

			Trackers[Panel] = nil
		end

		if Setters[Panel] then
			for K in pairs(Setters[Panel]) do
				Variables.Setters[K][Panel] = nil
			end

			Setters[Panel] = nil
		end
	end

	local function LoadFunctions(Panel)
		if not Panel.LegacyRemove then
			Panel.LegacyRemove = Panel.Remove

			function Panel:Remove()
				ClearVariables(self)

				self:LegacyRemove()
			end
		end

		if Panel.Hijack and Panel.Hijack ~= Panel.PrevHijack then
			if Panel.PrevHijack then
				Panel[Panel.PrevHijack] = Panel.OldSetFunc
			end

			Panel.PrevHijack = Panel.Hijack
			Panel.OldSetFunc = Panel[Panel.Hijack]

			function Panel:NewSetFunc(Value)
				if self.DataVar then
					ACF.SetClientData(self.DataVar, Value)
					return
				end

				self:OldSetFunc(Value)
			end

			Panel[Panel.Hijack] = Panel.NewSetFunc
		end
	end

	function PANEL:SetDataVar(Key, Function)
		if not Key then return end

		self.DataVar = Key
		self.Hijack = Function or self.Hijack or "SetValue"

		AddSetter(self, Key)
		LoadFunctions(self)

		if not Client[Key] then
			ACF.SetClientData(Key, self:GetValue())
		end
	end

	function PANEL:TrackDataVar(Key, Function)
		self.Hijack = Function or self.Hijack or "SetValue"

		AddTracker(self, Key)
		LoadFunctions(self)
	end

	function PANEL:SetValueFunction(Function)
		if not isfunction(Function) then return end

		LoadFunctions(self)

		self.ValueFunction = Function

		if self.Hijack then
			self:NewSetFunc(self:ValueFunction())
		end
	end

	hook.Add("ACF_OnClientDataUpdate", "ACF Update Panel Values", function(_, Key, Value)
		local TrackerPanels = Variables.Trackers[Key]
		local SetterPanels = Variables.Setters[Key]

		-- First we'll process the panels that set the value of this key
		if SetterPanels then
			for Panel in pairs(SetterPanels) do
				if not Panel.OldSetFunc then continue end

				local NewValue = Value

				if Panel.ValueFunction then
					NewValue = Panel:ValueFunction()
				end

				Panel:OldSetFunc(NewValue)
			end
		end

		-- Then we'll process the panels that just keep track of this value
		if TrackerPanels then
			for Panel in pairs(TrackerPanels) do
				if not Panel.ValueFunction then continue end

				Panel:OldSetFunc(Panel:ValueFunction(true))
			end
		end
	end)
end
