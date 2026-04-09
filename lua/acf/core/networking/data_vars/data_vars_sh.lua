local ACF = ACF

do -- Macros for defining data variables and their types
	ACF.DataVarTypesByName = ACF.DataVarTypesByName or {} -- Maps name -> type definition

	function ACF.DefineDataVarType(Name)
		local DataVarType = ACF.DataVarTypesByName[Name]
		if not DataVarType then
			DataVarType = {
				Name = Name,
				NetRead = net["Read" .. Name],
				NetWrite = net["Write" .. Name],
			}
			ACF.DataVarTypesByName[Name] = DataVarType
		end
		return DataVarType
	end

	ACF.DataVars = ACF.DataVars or {} -- Maps UUID -> variable definition
	ACF.DataVarsByScopeAndName = ACF.DataVarsByScopeAndName or {} -- Maps scope -> name -> variable definition
	ACF.DataVarScopesOrdered = ACF.DataVarScopesOrdered or {} -- Maps scope -> ordered list of variable names (for menu generation)

	--- Defines data variable on the client
	local VarCounter = 1
	function ACF.DefineDataVar(Name, Scope, Type, Default, Options)
		local DataVar = ACF.DataVarsByScopeAndName[Scope] and ACF.DataVarsByScopeAndName[Scope][Name]
		if not DataVar then
			DataVar = {
				Name = Name,
				Scope = Scope,
				UUID = VarCounter,
				Values = {},
			}

			-- Add to ordered list of scopes
			ACF.DataVarScopesOrdered[Scope] = ACF.DataVarScopesOrdered[Scope] or {}
			table.insert(ACF.DataVarScopesOrdered[Scope], Name)
			ACF.DataVars[VarCounter] = DataVar
			VarCounter = VarCounter + 1

			ACF.DataVarsByScopeAndName[Scope] = ACF.DataVarsByScopeAndName[Scope] or {}
			ACF.DataVarsByScopeAndName[Scope][Name] = DataVar
		end

		DataVar.Type = ACF.DataVarTypesByName[Type]
		DataVar.Default = Default
		DataVar.Options = Options or {}

		return DataVar
	end
end

do -- Managing data variable synchronization and networking
	local ACF_DATA_VAR_LIMIT_EXPONENT = 8 -- Maximum number of data vars allowed as an exponent of 2
	local ACF_DATA_VAR_MAX_MESSAGE_SIZE = 128 -- Maximum size of a data var message in bytes

	if SERVER then util.AddNetworkString("ACF_DV_NET") end

	-- TODO: Add queue for rate limitting per variable (and forcing option)

	local function StartWriteDataVar(DataVar, Value, SyncServer)
		net.Start("ACF_DV_NET")
		net.WriteUInt(DataVar.UUID, ACF_DATA_VAR_LIMIT_EXPONENT)
		net.WriteBool(SyncServer) -- Whether we are synchronizing server data or client data
		DataVar.Type.NetWrite(Value, DataVar)
	end

	--- Synchronizes a data variable change across the network
	--- Called from server:
	---		ACF.SetDataVar(Name, Scope, Value) -> Same as "Server" case (default)
	--- 	ACF.SetDataVar(Name, Scope, Value, "Server") -> Updates a server variable and broadcasts to all clients
	---		ACF.SetDataVar(Name, Scope, Value, Player) -> Updates a client variable for a specific player and sends to that player
	--- Called from client:
	---		ACF.SetDataVar(Name, Scope, Value) -> Same as LocalPlayer() case (default)
	--- 	ACF.SetDataVar(Name, Scope, Value, LocalPlayer()) -> Updates a client variable and sends to the server, but you must use the local player
	--- 	ACF.SetDataVar(Name, Scope, Value, "Server") -> Updates a client variable for the local player and sends to the server
	function ACF.SetDataVar(Name, Scope, Value, ToSync)
		ToSync = ToSync or (CLIENT and LocalPlayer()) or "Server" -- default values

		local SyncServer = ToSync == "Server"
		if CLIENT and SyncServer and not ACF.CanSetServerData(LocalPlayer()) then return end -- Don't allow unauthorized clients to send server data

		-- Only do stuff if something changes
		local DataVar = ACF.DataVarsByScopeAndName[Scope][Name]
		if not DataVar.Options.Hidden and DataVar.Values[ToSync] ~= Value then
			DataVar.Values[ToSync] = Value

			StartWriteDataVar(DataVar, Value, SyncServer)

			if SERVER then
				if SyncServer then net.Broadcast() -- Broadcast server change to all clients
				else net.Send(ToSync) end -- Send specific client change to that client
			else
				if SyncServer then net.SendToServer() -- Send server change to server
				else net.SendToServer() end -- Send client change to server
			end

			-- print("Sent data var", ACF.DataVarIDsToNames[DataVar.UUID], "with value", Value)
			hook.Run("ACF_OnDataVarChanged", DataVar.Name, DataVar.Scope, Value) -- Notify our realm before we send
		end
	end

	-- Handle incoming data var updates
	net.Receive("ACF_DV_NET", function(len, ply)
		if len > (ACF_DATA_VAR_MAX_MESSAGE_SIZE * 8) then return end

		local ID = net.ReadUInt(ACF_DATA_VAR_LIMIT_EXPONENT)
		local DataVar = ACF.DataVars[ID]
		if not DataVar then return end

		local SyncServerRealm = net.ReadBool()
		local Value = DataVar.Type.NetRead(DataVar)

		-- Unauthorized clients cannot set the server's view of the data
		if SERVER and SyncServerRealm and not ACF.CanSetServerData(ply) then return end

		if SERVER then
			if SyncServerRealm then
				-- Update the server's value and broadcast the change to all clients other than the proposer
				DataVar.Values.Server = Value
				StartWriteDataVar(DataVar, Value, true)
				net.SendOmit(ply)
			else DataVar.Values[ply] = Value end
		else
			if SyncServerRealm then DataVar.Values.Server = Value
			else DataVar.Values[LocalPlayer()] = Value end
		end
		hook.Run("ACF_OnDataVarChanged", DataVar.Name, DataVar.Scope, Value) -- Notify any listeners that the variable has changed
	end)

	if SERVER then
		-- Cleanup values when a player leaves to avoid stale data
		hook.Add("PlayerDisconnected", "ACF_CleanupDataVars", function(ply)
			for _, dv in ipairs(ACF.DataVars) do
				dv.Values[ply] = nil
			end
		end)

		-- When a player loads in, send them all the server data so they have the correct values
		hook.Add("ACF_OnLoadPlayer", "ACF_FullServerDataSync", function(ply)
			if not IsValid(ply) then return end

			for _, DataVar in ipairs(ACF.DataVars) do
				local value = DataVar.Values.Server
				if value ~= nil then
					StartWriteDataVar(DataVar, value, true)
					net.Send(ply)
				end
			end
		end)
	end

	--- Returns whether a client is allowed to set a server datavars
	function ACF.CanSetServerData(Player)
		if not IsValid(Player) then return true end -- No player, probably the server
		if Player:IsSuperAdmin() then return true end

		return ACF.GetDataVar("ServerDataAllowAdmin", "ServerSettings") and Player:IsAdmin()
	end

	--- Gets the value of a data variable for the given Player/"Server"
	function ACF.GetDataVar(Name, Scope, Player, IgnoreUnset)
		local DataVar = ACF.DataVarsByScopeAndName[Scope][Name]
		if not DataVar then return end
		if DataVar.Options.Hidden then return nil end

		local Value = DataVar.Values[Player or (CLIENT and LocalPlayer()) or "Server"]
		if not Value and not IgnoreUnset then return DataVar.Default end
		return Value
	end

	--- Sets all data variables at once using a nested table format: KVs[Scope][Name] = Value.
	function ACF.SetDataVars(KVs, Player)
		for scope, _ in pairs(ACF.DataVarsByScopeAndName) do
			for name, _ in pairs(ACF.DataVarsByScopeAndName[scope] or {}) do
				if KVs[scope] and KVs[scope][name] ~= nil then ACF.SetDataVar(name, scope, KVs[scope][name], Player) end
			end
		end
	end

	--- Gets all data variables at once in a nested table format: KVs[Scope][Name] = Value.
	function ACF.GetDataVars(Scope, Player, IgnoreUnset)
		local Result = {}
		for scope, _ in pairs(ACF.DataVarsByScopeAndName) do
			if Scope and scope ~= Scope then continue end
			for name, _ in pairs(ACF.DataVarsByScopeAndName[scope] or {}) do
				Result[scope] = Result[scope] or {}
				Result[scope][name] = ACF.GetDataVar(name, scope, Player, IgnoreUnset)
			end
		end
		return Result
	end
end

do -- Automatic Menu Generation
	function ACF.CreatePanelFromDataVar(Menu, DataVar, TargetRealm)
		if DataVar.Options.Hidden then return end
		if not DataVar.Type.CreatePanel then return end
		local Panel = DataVar.Type.CreatePanel(Menu, DataVar)
		if Panel.BindToDataVar then Panel:BindToDataVar(DataVar.Name, DataVar.Scope, TargetRealm) end
		if DataVar.Tooltip then Panel:SetTooltip(DataVar.Tooltip) end
		return Panel
	end

	function ACF.CreatePanelsFromDataVars(Menu, Scope, TargetRealm)
		local Panels = {}
		for _, Name in ipairs(ACF.DataVarScopesOrdered[Scope] or {}) do
			local DataVar = ACF.DataVarsByScopeAndName[Scope][Name]
			if DataVar then
				Panels[Name] = ACF.CreatePanelFromDataVar(Menu, DataVar, TargetRealm)
			end
		end
		return Panels
	end
end

do -- Defining default data variables and types
	local CreateSliderMenu = function(Menu, DataVar) return Menu:AddSlider(DataVar.Name, DataVar.Options.Min, DataVar.Options.Max, 2) end
	local CreateWangMenu = function(Menu, DataVar) return Menu:AddNumberWang(DataVar.Name, DataVar.Options.Min, DataVar.Options.Max, 2) end

	-- Basic types
	local BoolDV = ACF.DefineDataVarType("Bool")
	BoolDV.CreatePanel = function(Menu, DataVar) return Menu:AddCheckbox(DataVar.Name) end
	BoolDV.Sanitize = function(x) return isbool(x) and x end

	local StringDV = ACF.DefineDataVarType("String")
	StringDV.CreatePanel = function(Menu, DataVar) return Menu:AddTextEntry(DataVar.Name) end
	StringDV.Sanitize = function(x) return isstring(x) and x end

	local FloatDV = ACF.DefineDataVarType("Float")
	FloatDV.CreatePanel = CreateSliderMenu
	FloatDV.Sanitize = function(x) return isnumber(x) and x end

	local DoubleDV = ACF.DefineDataVarType("Double")
	DoubleDV.CreatePanel = CreateSliderMenu
	DoubleDV.Sanitize = function(x) return isnumber(x) and x end

	local ColorDV = ACF.DefineDataVarType("Color")
	ColorDV.Sanitize = function(x) return IsColor(x) and x end

	local AngleDV = ACF.DefineDataVarType("Angle")
	AngleDV.Sanitize = function(x) return isangle(x) and x end

	local VectorDV = ACF.DefineDataVarType("Vector")
	VectorDV.CreatePanel = function(Menu, DataVar) return Menu:AddVectorSlider(DataVar.Name, DataVar.Options.Min, DataVar.Options.Max, 2) end

	local NormalDV = ACF.DefineDataVarType("Normal")
	NormalDV.Sanitize = function(x) return isvector(x) and x:Length() == 1 end

	local EntityDV = ACF.DefineDataVarType("Entity")
	EntityDV.Sanitize = function(x) return IsValid(x) and x end

	local PlayerDV = ACF.DefineDataVarType("Player")
	PlayerDV.Sanitize = function(x) return IsValid(x) and x:IsPlayer() and x end

	local TableDV = ACF.DefineDataVarType("Table")
	TableDV.Sanitize = function(x) return istable(x) and x end

	local DataDV = ACF.DefineDataVarType("Data")
	DataDV.Sanitize = function(x) return isstring(x) and x end

	local BoolDV = ACF.DefineDataVarType("Bit")
	BoolDV.Sanitize = function(x) return isbool(x) and x end

	-- Signed integers (1 to 32 bits)
	local IntDV = ACF.DefineDataVarType("Int")
	IntDV.NetRead = function(DataVar) return net.ReadInt(DataVar.Options.Bits or 32) end
	IntDV.NetWrite = function(Value, DataVar) net.WriteInt(Value, DataVar.Options.Bits or 32) end
	IntDV.CreatePanel = CreateWangMenu

	-- Unsigned integers (1 to 32 bits)
	local UIntDV = ACF.DefineDataVarType("UInt")
	UIntDV.NetRead = function(DataVar) return net.ReadUInt(DataVar.Options.Bits or 32) end
	UIntDV.NetWrite = function(Value, DataVar) net.WriteUInt(Value, DataVar.Options.Bits or 32) end
	UIntDV.CreatePanel = CreateWangMenu

	----------------------------------------------------------

	-- Advanced types
	local StoredEntityDV = ACF.DefineDataVarType("StoredEntity")
	StoredEntityDV.PreCopy = function(_, _, Value) return Value:EntIndex() end
	StoredEntityDV.PostPaste = function(_, _, Value, CreatedEnts) return CreatedEnts[Value] end

	local StoredEntitiesDV = ACF.DefineDataVarType("StoredEntities")
	StoredEntitiesDV.PreCopy = function(_, _, Value)
		local Result = {}
		for Entity in pairs(Value) do Result[#Result + 1] = Entity:EntIndex() end
		return Result
	end
	StoredEntitiesDV.PostPaste = function(_, _, Value, CreatedEnts)
		local Result = {}
		for _, EntIndex in ipairs(Value) do
			local Created = CreatedEnts[EntIndex]
			if IsValid(Created) then Result[#Result + 1] = Created end
		end
		return Result
	end
	local EnumeratedStringDV = ACF.DefineDataVarType("EnumeratedString")
	EnumeratedStringDV.NetWrite = net.WriteString
	EnumeratedStringDV.NetRead = net.ReadString
	EnumeratedStringDV.CreatePanel = function(Menu, DataVar)
		local Combo = Menu:AddComboBox(DataVar.Name)
		for _, Option in ipairs(DataVar.Options.Choices) do Combo:AddChoice(Option, Option) end
		return Combo
	end

	-- TODO: Change to a class system to allow for types to inherit functionality from each other

	----------------------------------------------------------

	-- Test variable
	ACF.DefineDataVar("TestVar", "TestScope", "String", "TestValue")

	ACF.DefineDataVar("ServerDataAllowAdmin", "ServerSettings", "Bool", false)
	ACF.DefineDataVar("DisableLegalChecks", "ServerSettings", "Bool", false)
	ACF.DefineDataVar("DataVarNetQueue", "ServerSettings", "Float", 1.0, {Min = 0, Max = 1.0})

	ACF.DefineDataVar("ClientEffectMultiplier", "ClientSettings", "Float", 1.0, {Min = 0, Max = 1.0})
	ACF.DefineDataVar("ClientSoundMultiplier", "ClientSettings", "Float", 1.0, {Min = 0, Max = 1.0})

	ACF.DefineDataVar("SpawnClass", "ToolGun", "String", "ACF_testent")
end