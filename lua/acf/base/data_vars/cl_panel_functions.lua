local ACF       = ACF
local PanelMeta = FindMetaTable("Panel")

function PanelMeta:DefineSetter(Function)
	if not isfunction(Function) then return end

	self.SetCustomValue = Function
end

do -- Tracker and Setter panel functions
	ACF.DataPanels = ACF.DataPanels or {
		Server = {},
		Client = {},
		Panels = {},
	}

	---------------------------------------------------------------------------

	local DataPanels = ACF.DataPanels
	local Queued     = { Client = {}, Server = {} }
	local IsQueued

	local function RefreshValues()
		for Realm, Data in pairs(Queued) do
			local SetFunction = ACF["Set" .. Realm .. "Data"]
			local Variables   = ACF[Realm .. "Data"]

			for Key in pairs(Data) do
				SetFunction(Key, Variables[Key], true)

				Data[Key] = nil
			end
		end

		IsQueued = nil
	end

	local function QueueRefresh(Realm, Key)
		local Data = Queued[Realm]

		if Data[Key] then return end

		Data[Key] = true

		if not IsQueued then
			timer.Create("ACF Refresh Data Vars", 0, 1, RefreshValues)

			IsQueued = true
		end
	end

	---------------------------------------------------------------------------

	local function GetSubtable(Table, Key)
		local Result = Table[Key]

		if not Result then
			Result     = {}
			Table[Key] = Result
		end

		return Result
	end

	local function StoreData(Destiny, Key, Realm, Value, Store)
		local BaseData = GetSubtable(DataPanels[Destiny], Key)
		local TypeData = GetSubtable(BaseData, Realm)

		TypeData[Value] = Store or true
	end

	local function ClearFromType(Data, Realm, Panel)
		local Saved = Data[Realm]

		if not Saved then return end

		for Name, Mode in pairs(Saved) do
			DataPanels[Realm][Name][Mode][Panel] = nil -- Weed lmao
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

	local function DefaultSetter(Panel, Value, Forced)
		local ServerVar = Panel.ServerVar
		local ClientVar = Panel.ClientVar

		if not (ServerVar or ClientVar) then
			if Panel.SetCustomValue then
				Value = Panel:SetCustomValue(nil, nil, Value) or Value
			end

			return Panel:OldSet(Value)
		end

		if ServerVar then
			ACF.SetServerData(ServerVar, Value, Forced)
		end

		if ClientVar then
			ACF.SetClientData(ClientVar, Value, Forced)
		end
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
		Panel[Setter]  = DefaultSetter
		Panel.Setter   = DefaultSetter
		Panel.Hijacked = true

		HijackThink(Panel)
		HijackRemove(Panel)
	end

	local function UpdatePanels(Panels, Realm, Key, Value, IsTracked)
		if not Panels then return end

		for Panel in pairs(Panels) do
			if not IsValid(Panel) then
				ClearData(Panel) -- Somehow Panel:Remove is not being called
				continue
			end

			local Result = Value

			if Panel.SetCustomValue then
				Result = Panel:SetCustomValue(Realm, Key, Value, IsTracked)
			end

			if Result ~= nil then
				Panel:OldSet(Result)
			end
		end
	end

	---------------------------------------------------------------------------

	--- Generates the following functions:
	-- Panel:SetClientData(Key, Setter)
	-- Panel:TrackClientData(Key, Setter)
	-- Panel:SetServerData(Key, Setter)
	-- Panel:TrackServerData(Key, Setter)

	for Realm in pairs(Queued) do
		PanelMeta["Set" .. Realm .. "Data"] = function(Panel, Key, Setter)
			if not isstring(Key) then return end

			local Variables   = ACF[Realm .. "Data"]
			local SetFunction = ACF["Set" .. Realm .. "Data"]

			StoreData("Panels", Panel, Realm, Key, "Setter")
			StoreData(Realm, Key, "Setter", Panel)

			HijackFunctions(Panel, Setter or "SetValue")

			Panel[Realm .. "Var"] = Key

			if Variables[Key] == nil then
				SetFunction(Key, Panel:GetValue())
			end

			QueueRefresh(Realm, Key)
		end

		PanelMeta["Track" .. Realm .. "Data"] = function(Panel, Key, Setter)
			if not isstring(Key) then return end

			StoreData("Panels", Panel, Realm, Key, "Tracker")
			StoreData(Realm, Key, "Tracker", Panel)

			HijackFunctions(Panel, Setter or "SetValue")
		end

		hook.Add("ACF_On" .. Realm .. "DataUpdate", "ACF Update Panel Values", function(_, Key, Value)
			local Data = DataPanels[Realm][Key]

			if not Data then return end -- This variable is not being set or tracked by panels

			UpdatePanels(Data.Setter, Realm, Key, Value, IsTracked)
			UpdatePanels(Data.Tracker, Realm, Key, Value, IsTracked)
		end)
	end
end
