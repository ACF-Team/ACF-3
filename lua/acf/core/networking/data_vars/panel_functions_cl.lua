local ACF       = ACF
local PanelMeta = FindMetaTable("Panel")

--- NOTE: I DON'T THINK IsTracked EVER GETS USED... PROBABLY IGNORE IT...

--[[
	EXAMPLE USAGE IF USING DATA VARS:

	local Control = GearBase:AddSlider(SliderName, MinGearRatio, MaxGearRatio, 2)
	Control:SetClientData(Variable, "OnValueChanged")
	Control:DefineSetter(function(Panel, _, _, Value)
		Value = math.Round(Value, 2)

		ValuesData[Variable] = Value

		Panel:SetValue(Value)

		return Value
	end)
]]

--- This allows you to set a custom function to handle setting the panel's value.
--- @param Function function A function that takes (Realm, Key, Value, IsTracked) and sets the value of the panel and returns that value.
function PanelMeta:DefineSetter(Function)
	if not isfunction(Function) then return end

	self.SetCustomValue = Function
end

do -- Tracker and Setter panel functions
	-- Example structure of ACF.DataPanels:
	--	["Client"]:
	-- 		["AmmoStage"]:
	--			["Setter"]:
	-- 				[Panel: [name:DNumberWang][class:TextEntry][143,0,64,24]]	=	true
	--		["Caliber"]:
	-- 			["Setter"]:
	-- 				[Panel: [name:DNumSlider][class:Panel][0,32,217,32]]	=	true
	--			["Tracker"]:
	-- 				[Panel: [name:DLabel][class:Label][0,0,207,54]]	=	true
	-- 				[Panel: [name:DLabel][class:Label][0,374,207,182]]	=	true
	--	["Server"]:
	-- 		["AllowDynamicLinking"]:
	-- 			["Setter"]:
	-- 				[Panel [NULL]]	=	true
	-- 		["CrewFallbackCoef"]:
	-- 			["Setter"]:
	-- 				[Panel [NULL]]	=	true
	--	["Panels"]:
	--		[Panel [NULL]]:
	-- 			["Server"]:
	-- 				["FuelFactor"]	=	Setter
	-- 		[Panel [NULL]]:
	-- 			["Server"]:
	-- 				["ServerDataAllowAdmin"]	=	Setter
	ACF.DataPanels = ACF.DataPanels or {
		Server = {},
		Client = {},
		Panels = {},
	}

	---------------------------------------------------------------------------

	local DataPanels = ACF.DataPanels
	local Queued     = { Client = {}, Server = {} } 	-- For each realm, a LUT mapping variables to true if they need to be processed
	local IsQueued   									-- Whether the refresh is queued

	--- Networks the current value of all queued data variables by force
	local function RefreshValues()
		for Realm, Data in pairs(Queued) do
			local SetFunction = ACF["Set" .. Realm .. "Data"]
			local Variables   = ACF[Realm .. "Data"]

			for Key in pairs(Data) do
				SetFunction(Key, Variables[Key], true)	-- Force network the current value
				Data[Key] = nil
			end
		end

		IsQueued = nil
	end

	--- Queues a refresh for a specific data variable
	--- @param Realm string The realm of the data variable (Server/Client)
	--- @param Key string The key of the data variable to refresh
	local function QueueRefresh(Realm, Key)
		local Data = Queued[Realm]

		if Data[Key] then return end

		Data[Key] = true

		-- Rate limit updates
		if not IsQueued then
			timer.Create("ACF Refresh Data Vars", 0, 1, RefreshValues)

			IsQueued = true
		end
	end

	---------------------------------------------------------------------------

	--- Returns a Table[Key], creating a blank entry if it doesn't exist.
	local function GetSubtable(Table, Key)
		local Result = Table[Key]

		if not Result then
			Result     = {}
			Table[Key] = Result
		end

		return Result
	end

	--- Stores data about what panels are tracking/setting what data variables
	--- The argument names are misleading and there's multiple ways to use this function :(
	--- For client/server:
	--- @param Destiny string The realm of the data variable (e.g. "Server"/"Client")
	--- @param Key string The key of the data variable (e.g. "CrewFallbackCoef")
	--- @param Realm string The action relevant to this data variable (e.g. "Setter"/"Tracker")
	--- @param Value any The ACF panel relevant to that action
	--- @param Store boolean Marks said panel as part of the table or not. (e.g. true or nil)
	--- For panels:
	--- @param Destiny string Always "Panel" in this case
	--- @param Key any The panel to update
	--- @param Realm string A data variable key said panel interacts with
	--- @param Value function The current setter function for said variable for said panel
	--- @param Store boolean Always nil in this case
	local function StoreData(Destiny, Key, Realm, Value, Store)
		local BaseData = GetSubtable(DataPanels[Destiny], Key) 	-- DataPanels[Destiny][Key]
		local TypeData = GetSubtable(BaseData, Realm) 			-- DataPanels[Destiny][Key][Realm]

		TypeData[Value] = Store or true							-- DataPanels[Destiny][Key][Realm][Value] = Store or true
	end

	--- Clears a panel from tracking or setting any data variables
	--- @param Data The Data Panel table
	--- @param Realm string The realm to clear from (e.g. "Server"/"Client")
	--- @param Panel any The panel to clear
	local function ClearFromType(Data, Realm, Panel)
		local Saved = Data[Realm]

		if not Saved then return end

		-- Mode goes over "Tracker" and "Setter"
		for Name, Mode in pairs(Saved) do
			DataPanels[Realm][Name][Mode][Panel] = nil -- Weed lmao
		end
	end

	--- Clears a panel's setter function
	--- @param Panel any The panel to clear
	local function ClearData(Panel)
		local Panels = DataPanels.Panels
		local Data   = Panels[Panel]	-- The data for this panel

		-- Apparently this can be called twice
		if Data then
			ClearFromType(Data, "Server", Panel)
			ClearFromType(Data, "Client", Panel)
		end

		Panels[Panel] = nil
	end

	--- @param Panel Panel The panel to set data for
	--- @param Value any The value to set
	--- @param Forced boolean Whether to force the update
	local function DefaultSetter(Panel, Value, Forced)
		-- NOTE: These come from the generated functions at the bottom of the file
		local ServerVar = Panel.ServerVar	-- The relevant server variable if it exists
		local ClientVar = Panel.ClientVar	-- The relevant client variable if it exists

		-- If there's no data variable assigned to this panel
		if not (ServerVar or ClientVar) then
			-- If we did specify a custom setter (DefineSetter), use it to determine a value
			if Panel.SetCustomValue then
				Value = Panel:SetCustomValue(nil, nil, Value) or Value
			end

			-- This actually causes the panel to update its visuals
			return Panel:OldSet(Value)
		end

		-- If a server data variable was assigned, set it.
		-- This also proposes the change to the server, which is how it turns into usable information
		if ServerVar then
			ACF.SetServerData(ServerVar, Value, Forced)
		end

		-- If a client data variable was assigned, set it.
		if ClientVar then
			ACF.SetClientData(ClientVar, Value, Forced)
		end
	end

	--- Hijacks the Think function of a panel, automaticaly enabling/disabling based on authorization.
	--- @param Panel Panel The panel to hijack
	local function HijackThink(Panel)
		local OldThink = Panel.Think
		local Player   = LocalPlayer()

		Panel.Enabled = Panel:IsEnabled()

		function Panel:Think(...)
			-- Since server data vars (e.g. Allow Arbitrary Parenting) should only be set by authorized players
			-- Disable the panel if the user is unauthorized to make it clear (of course we still verify on server)
			-- Or reenable the panel if they become authorized
			if self.ServerVar then
				local Enabled = ACF.CanSetServerData(Player)

				if self.Enabled ~= Enabled then
					self.Enabled = Enabled

					self:SetEnabled(Enabled)
				end
			end

			-- Run the old think regardless
			if OldThink then
				return OldThink(self, ...)
			end
		end
	end

	--- Hijacks the Remove function of a panel, automaticaly clearing data before removal.
	--- @param Panel Panel The panel to hijack
	local function HijackRemove(Panel)
		local OldRemove = Panel.Remove

		function Panel:Remove(...)
			ClearData(self)

			return OldRemove(self, ...)
		end
	end

	--- Detours the setters to use the custom setter and hijacks the think and remove functions
	--- @param Panel Panel The panel to hijack
	--- @param SetFunction string? When to trigger an update (e.g. OnChange, OnValueChanged)
	local function HijackFunctions(Panel, SetFunction)
		if Panel.Hijacked then return end

		local Setter = Panel[SetFunction] and SetFunction or "SetValue"

		Panel.OldSet   = Panel[Setter]	-- Stores the old setter function, e.g. SetValue
		Panel[Setter]  = DefaultSetter	-- Detours the panel's setter function to use our custom setter function
		Panel.Setter   = DefaultSetter	-- Stores the custom setter function
		Panel.Hijacked = true			-- Marks the panel as hijacked

		HijackThink(Panel)
		HijackRemove(Panel)
	end

	--- Updates the values of the panels assuming an update happened to a specific data var
	--- @param Panels table A LUT of panels to update
	--- @param Realm string The realm of the data var (e.g. "Client", "Server")
	--- @param Key string The key of the data var
	--- @param Value any The new value of the data var
	--- @param IsTracked boolean Whether the update is tracked
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

		--- Sets the data for a panel
		--- @param Panel Panel The panel to set data for
		--- @param Key string The key of the data variable
		--- @param Setter string|nil When to trigger an update (e.g. OnChange, OnValueChanged)
		PanelMeta["Set" .. Realm .. "Data"] = function(Panel, Key, Setter)
			if not isstring(Key) then return end

			local Variables   = ACF[Realm .. "Data"]
			local SetFunction = ACF["Set" .. Realm .. "Data"]

			-- This still puzzles me
			StoreData("Panels", Panel, Realm, Key, "Setter")
			StoreData(Realm, Key, "Setter", Panel)

			-- Hijack the panel to do various things including reacting to Setter
			HijackFunctions(Panel, Setter or "SetValue")

			Panel[Realm .. "Var"] = Key -- Note the data variable relevant to this panel

			-- Initialize the variable if it doesn't exist to the current value of the panel
			if Variables[Key] == nil then
				local Value = Panel:GetValue()
				SetFunction(Key, Value)
			end

			-- Refresh since that probably changed things
			QueueRefresh(Realm, Key)
		end

		--- Tracks the data for a panel
		--- @param Panel Panel The panel to track data for
		--- @param Key string The key of the data variable
		--- @param Setter string|nil When to trigger an update (e.g. OnChange, OnValueChanged)
		PanelMeta["Track" .. Realm .. "Data"] = function(Panel, Key, Setter)
			if not isstring(Key) then return end

			-- This still puzzles me
			StoreData("Panels", Panel, Realm, Key, "Tracker")
			StoreData(Realm, Key, "Tracker", Panel)

			-- Hijack the panel to do various things including reacting to Setter
			HijackFunctions(Panel, Setter or "SetValue")
		end

		--- Updates the values of the panels when a variable is updated 
		hook.Add("ACF_OnUpdate" .. Realm .. "Data", "ACF Update Panel Values", function(_, Key, Value)
			local Data = DataPanels[Realm][Key]

			if not Data then return end -- This variable is not being set or tracked by panels for this realm

			-- IsTracked is nil here, idk what's going on... TODO: Fix this?
			UpdatePanels(Data.Setter, Realm, Key, Value, IsTracked)
			UpdatePanels(Data.Tracker, Realm, Key, Value, IsTracked)
		end)
	end
end
