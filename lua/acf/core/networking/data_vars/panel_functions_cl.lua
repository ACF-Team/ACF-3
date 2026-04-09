local ACF = ACF
local PanelMeta = FindMetaTable("Panel")

ACF.DebugStorePanels = ACF.DebugStorePanels or {}

--- Attaches a panel to the debug store for easy access in the console. Usage: Panel:ACFDebug("MyPanel").
--- The panel can then be accessed via ACF.DebugStorePanels["MyPanel"]
function PanelMeta:ACFDebug(Name)
	ACF.DebugStorePanels[Name] = self
	return self
end

--- Detours a panel's method, allowing you to run code after the original method
function PanelMeta:HijackAfter(methodName, callback)
	local old = self[methodName]

	self[methodName] = function(pnl, ...)
		local ret = old(pnl, ...)
		callback(pnl, ...)
		return ret
	end

	return old
end

--- Watches a data variable and runs a callback whenever it changes.
function PanelMeta:WatchDataVar(Name, Scope, Callback)
	local HookID = "ACF_Bind_" .. tostring(self) .. "_" .. Name .. "_" .. Scope
	hook.Add("ACF_OnDataVarChanged", HookID, function(name, scope, value)
		if name ~= Name or scope ~= Scope then return end
		if not IsValid(self) then hook.Remove("ACF_OnDataVarChanged", HookID) return end

		Callback(value)
	end)
end

--- Convenience function to watch multiple data variables with the same callback
function PanelMeta:WatchDataVars(DataVars, Scope, Callback)
	for _, Name in pairs(DataVars) do
		self:WatchDataVar(Name, Scope, Callback)
	end
end

--- Binds a panel to a data variable, keeping them in sync in both directions.
--- Whenever the panel's value is changed by the user or programmatically, the data variable will be updated.
--- Whenever the data variable is updated (by the server or client), the panel's value will be updated.
--- @param DataVar string The name of the data variable to bind to
--- @param setterName string The name of the panel's setter function (e.g. SetValue, SetText, SetChecked, etc.)
--- @param getterName string The name of the panel's getter function (e.g. GetValue, GetText, GetChecked, etc.)
--- @param changeName string The name of the panel's OnVAlueChanged-like function to detour (e.g. OnValueChanged, OnTextChanged, OnCheckedChanged, etc.)
function PanelMeta:BindToDataVarAdv(Name, Scope, setterName, getterName, changeName, TargetRealm)
	local suppress = false -- Need to prevent infinite loops when both panel and DataVar update each other

	local function SetValue(value)
		suppress = true
		self[setterName](self, value)
		suppress = false
	end

	-- Panel -> DataVar (user changes)
	local function PushToDataVar(pnl)
		if suppress then return end
		local value = pnl[getterName](pnl)
		ACF.SetDataVar(Name, Scope, value, TargetRealm)
	end

	self:HijackAfter(changeName, PushToDataVar)
	self:HijackAfter(setterName, PushToDataVar)

	-- DataVar -> Panel (network updates)
	self:WatchDataVar(Name, Scope, function(value)
		SetValue(value)
	end)

	-- Initialize with current / default value (unset values remain unset)
	local initial = CLIENT and ACF.GetDataVar(Name, Scope, TargetRealm)
	if initial ~= nil then
		SetValue(initial)
	end
end