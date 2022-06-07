local ACF     = ACF
local Classes = ACF.Classes

Classes.Engines = Classes.Engines or {}

local Engines = Classes.Engines
local Entries = {}
local Types


local function AddPerformanceData(Engine)
	local Type = Types.Get(Engine.Type)

	if not Type then
		Type = Types.Get("GenericPetrol")

		Engine.Type = "GenericPetrol"
	end

	if not Engine.TorqueCurve then
		Engine.TorqueCurve = Type.TorqueCurve
	end

	ACF.AddEnginePerformanceData(Engine)
end

function Engines.RegisterGroup(ID, Data)
	local Group = Classes.AddClassGroup(ID, Entries, Data)

	if not Group.LimitConVar then
		Group.LimitConVar = {
			Name   = "_acf_engine",
			Amount = 16,
			Text   = "Maximum amount of ACF engines a player can create."
		}
	end

	Classes.AddSboxLimit(Group.LimitConVar)

	return Group
end

function Engines.Register(ID, ClassID, Data)
	local Class = Classes.AddGrouped(ID, ClassID, Entries, Data)

	if not Class.Sound then
		Class.Sound = "vehicles/junker/jnk_fourth_cruise_loop2.wav"
	end

	if Types then
		AddPerformanceData(Class)
	end

	return Class
end

Classes.AddGroupedFunctions(Engines, Entries)

do -- Adding engine performance data
	hook.Add("ACF_OnAddonLoaded", "ACF Engine Performance", function()
		Types = Classes.EngineTypes

		for Name in pairs(Engines.GetEntries()) do
			for _, Engine in pairs(Engines.GetItemEntries(Name)) do
				AddPerformanceData(Engine)
			end
		end

		hook.Remove("ACF_OnAddonLoaded", "ACF Engine Performance")
	end)
end

do -- Discontinued function
	function ACF_DefineEngine(ID)
		print("Attempted to register engine " .. ID .. " with a discontinued function. Use ACF.RegisterEngine instead.")
	end
end
